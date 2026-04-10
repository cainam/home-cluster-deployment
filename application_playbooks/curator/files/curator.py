#!/usr/bin/env python3
import kopf
import kubernetes
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# Initialize Kubernetes API clients
kubernetes.config.load_incluster_config()
corev1 = kubernetes.client.CoreV1Api()
appsv1 = kubernetes.client.AppsV1Api()

# Global state: track modified Deployments
modified_deployments = set()

# Constants
FALLBACK_POLICY = "IfNotPresent"
DEFAULT_POLICY = "Always"
ANNOTATION_KEY = "operator.dev/pullPolicy"


# -----------------------------
# Utility functions
# -----------------------------
def get_dep_name_from_pod(pod):
    """Return Deployment name for the Pod, following ReplicaSet owner if needed"""
    owners = pod.metadata.owner_references or []
    if not owners:
        return None
    owner = owners[0]
    if owner.kind == "Deployment":
        return owner.name
    elif owner.kind == "ReplicaSet":
        rs = appsv1.read_namespaced_replica_set(owner.name, pod.metadata.namespace)
        dep_owners = rs.metadata.owner_references or []
        if dep_owners and dep_owners[0].kind == "Deployment":
            return dep_owners[0].name
    return None


def patch_deployment_policy(dep_name, namespace, policy):
    """Patch the Deployment template's imagePullPolicy"""
    dep = appsv1.read_namespaced_deployment(dep_name, namespace)
    tmpl = dep.spec.template
    if tmpl.metadata.annotations is None:
        tmpl.metadata.annotations = {}
    tmpl.metadata.annotations[ANNOTATION_KEY] = policy
    for c in tmpl.spec.containers:
        c.image_pull_policy = policy
    appsv1.patch_namespaced_deployment(
        dep_name, namespace, {"spec": {"template": tmpl}}
    )
    logging.info(f"[{namespace}/{dep_name}] Patched imagePullPolicy to {policy}")


def all_pods_healthy(namespace, dep_name):
    """Check if all pods of a Deployment are Running and containers are ready"""
    pods = corev1.list_namespaced_pod(namespace, label_selector=f'app={dep_name}').items
    if not pods:
        return False
    return all(
        p.status.phase == "Running" and
        all(c.ready for c in (p.status.container_statuses or []))
        for p in pods
    )


# -----------------------------
# Main event handler
# -----------------------------
@kopf.on.event('pods')
def on_pod_event(event, **_):
    pod = event.get('object')
    if not pod or not pod.metadata or not pod.status:
        return

    namespace = pod.metadata.namespace
    pod_name = pod.metadata.name
    dep_name = get_dep_name_from_pod(pod)
    if not dep_name:
        return
    dep_key = f"{namespace}/{dep_name}"

    # Check if pod is in pull failure
    container_statuses = pod.status.container_statuses or []
    pull_failures = any(
        (cs.state and cs.state.waiting and cs.state.waiting.reason in ("ImagePullBackOff", "ErrImagePull"))
        for cs in container_statuses
    )

    if pull_failures:
        # Patch Deployment if not already patched
        if dep_key not in modified_deployments:
            logging.info(f"[{namespace}/{pod_name}] Pull failed, patching Deployment {dep_name}")
            patch_deployment_policy(dep_name, namespace, FALLBACK_POLICY)
            modified_deployments.add(dep_key)

        # Delete the failing pod to trigger a restart
        try:
            corev1.delete_namespaced_pod(pod_name, namespace)
            logging.info(f"[{namespace}/{pod_name}] Deleted failing pod to trigger restart")
        except kubernetes.client.exceptions.ApiException as e:
            logging.warning(f"[{namespace}/{pod_name}] Failed to delete pod: {e}")

    # Check if pod is Running and Deployment was previously modified
    elif dep_key in modified_deployments and pod.status.phase == "Running":
        if all_pods_healthy(namespace, dep_name):
            logging.info(f"[{namespace}/{dep_name}] All pods healthy, reverting Deployment")
            patch_deployment_policy(dep_name, namespace, DEFAULT_POLICY)
            modified_deployments.remove(dep_key)

