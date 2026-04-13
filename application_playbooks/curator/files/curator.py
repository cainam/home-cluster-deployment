import kopf
import kubernetes
import logging


# Force the root logger to use a single format and single handler
logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s:%(name)s:%(message)s', # Simple format like your first example
    stream=sys.stdout,
    force=True
)

# Optional: If you still see doubles from specific libraries,
# disable propagation on the kopf logger specifically
logging.getLogger("kopf").propagate = False

MAX_RETRIES = 3

@kopf.on.startup()
def configure(settings: kopf.OperatorSettings, **_):
    # Disable cluster-wide namespace scanning
    settings.scanning.disabled = True

@kopf.on.field('v1', 'pods', field='status.containerStatuses')
def handle_pull_failures(logger, old, new, name, namespace, spec, **kwargs):
    if not new:
        return

    for status in new:
        state = status.get('state', {})
        waiting = state.get('waiting', {})
        logger.info(f"Pod {name} - state: {state}.")

        # Check if the pod is stuck due to image pull issues
        if waiting.get('reason') in ['ImagePullBackOff', 'ErrImagePull']:
            retries = status.get('restartCount', 0)
            if retries >= MAX_RETRIES:
                logger.info(f"Pod {name} failed {retries} times. Switching to IfNotPresent.")
                patch_pod_policy(name, namespace)

def patch_pod_policy(name, namespace):
    api = kubernetes.client.CoreV1Api()
    # Note: Many Pod fields are immutable. To change imagePullPolicy,
    # you often have to delete and recreate the pod, or ensure the
    # controller manages a Deployment/StatefulSet instead.
    body = {
        "spec": {
            "containers": [{"name": "example", "imagePullPolicy": "IfNotPresent"}]
        }
    }
    api.patch_namespaced_pod(name, namespace, body)
