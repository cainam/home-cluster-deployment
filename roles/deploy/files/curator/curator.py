import kopf
import kubernetes.client as k8s

# --- Configuration ---
PULL_FAILURE_THRESHOLD = 3
TARGET_NAMESPACE = 'default' # Adjust to your target namespace
FALLBACK_POLICY = 'IfNotPresent'
TARGET_POLICY = 'Always'

# Global counter to track ongoing backoff situations (optional, for cleanup)
ON_BACKOFF_PODS = set()

# Initialize the Kubernetes API clients
apps_v1 = k8s.AppsV1Api()
core_v1 = k8s.CoreV1Api()

@kopf.on.event('', 'pods')
def handle_pod_events(type, body, logger, **kwargs):
    """
    Handler to process Pod events, primarily for tracking pull failures.
    We use the event handler to clean up our internal tracking set.
    """
    name = body.get('metadata', {}).get('name')
    namespace = body.get('metadata', {}).get('namespace')

    # When the pod is deleted or succeeds, remove it from our tracking set
    if type in ('DELETED', 'MODIFIED'):
        status = body.get('status', {}).get('phase')
        if status in ('Succeeded', 'Failed'):
             if name in ON_BACKOFF_PODS:
                 logger.info(f"Pod {name} completed/failed, removing from tracking.")
                 ON_BACKOFF_PODS.discard(name)


@kopf.timer('', 'pods', interval=60, field='status.phase', value='Pending')
def check_image_pull_backoff(body, logger, **kwargs):
    """
    A timer-based handler that runs every 60 seconds for Pods in the 'Pending' phase.
    This is where we check the actual retry count.
    """
    pod_name = body.get('metadata', {}).get('name')
    namespace = body.get('metadata', {}).get('namespace')
    owner = None
    
    # 1. Check for ImagePullBackOff reason
    for container_status in body.get('status', {}).get('containerStatuses', []):
        if container_status.get('state', {}).get('waiting', {}).get('reason') == 'ImagePullBackOff':
            
            # Find the Pod's owner (Deployment/DaemonSet)
            for owner_ref in body.get('metadata', {}).get('ownerReferences', []):
                if owner_ref['kind'] in ('Deployment', 'ReplicaSet', 'DaemonSet'):
                    owner = owner_ref
                    break
            
            if owner is None:
                logger.debug(f"Pod {pod_name} is in backoff but has no relevant owner.")
                return # Skip if no owner is found
            
            # 2. Count the 'Failed to pull image' events
            events = core_v1.list_namespaced_event(namespace, field_selector=f'involvedObject.name={pod_name}').items
            pull_failure_count = sum(1 for e in events if 'Failed to pull image' in e.message)
            
            logger.info(f"Pod {pod_name}: ImagePullBackOff detected. Failed pull attempts: {pull_failure_count}")

            # 3. Apply the fallback policy if threshold is met
            if pull_failure_count >= PULL_FAILURE_THRESHOLD:
                
                # Check if the policy has already been patched
                current_policy = _get_current_pull_policy(owner, namespace, pod_name)
                if current_policy == FALLBACK_POLICY:
                    logger.info(f"Owner {owner['name']} is already patched to {FALLBACK_POLICY}.")
                    ON_BACKOFF_PODS.discard(pod_name)
                    return # Already fixed, stop here
                
                logger.warning(f"THRESHOLD REACHED ({pull_failure_count} >= {PULL_FAILURE_THRESHOLD}). Patching owner {owner['kind']}/{owner['name']} to use {FALLBACK_POLICY}.")
                
                _patch_owner_policy(owner, namespace, FALLBACK_POLICY, logger)
                
                # Optionally delete the current failing pod to force an immediate restart with the new policy
                # core_v1.delete_namespaced_pod(pod_name, namespace)
                
                ON_BACKOFF_PODS.add(pod_name)
                
            return # Processed the first container in backoff and finished

    # If the pod is no longer in backoff, remove it from the tracking set
    if pod_name in ON_BACKOFF_PODS:
        logger.info(f"Pod {pod_name} recovered from backoff, removing from tracking.")
        ON_BACKOFF_PODS.discard(pod_name)


def _get_current_pull_policy(owner, namespace, pod_name):
    """Helper to check the current pull policy of the owner's template."""
    if owner['kind'] == 'Deployment':
        deploy = apps_v1.read_namespaced_deployment(owner['name'], namespace)
        return deploy.spec.template.spec.containers[0].image_pull_policy
    # Add logic for DaemonSet, ReplicaSet, etc. here
    return TARGET_POLICY # Assume initial target if owner not found/supported


def _patch_owner_policy(owner, namespace, new_policy, logger):
    """Helper to patch the owner's Pod template."""
    patch_body = {
        'spec': {
            'template': {
                'spec': {
                    'containers': [
                        {'name': c.name, 'imagePullPolicy': new_policy}
                        for c in apps_v1.read_namespaced_deployment(owner['name'], namespace).spec.template.spec.containers
                    ]
                }
            }
        }
    }
    
    try:
        if owner['kind'] == 'Deployment':
            apps_v1.patch_namespaced_deployment(owner['name'], namespace, patch_body)
            logger.info(f"Patched Deployment {owner['name']} with pullPolicy: {new_policy}")
        # Add logic for DaemonSet, etc. here
    except k8s.ApiException as e:
        logger.error(f"Failed to patch owner {owner['name']}: {e}")
