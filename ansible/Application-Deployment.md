## Kubernetes
Applications on Kubernetes are deployed using helm charts

Flow:
- chart source taken from git repository (own or shared)
- chart is build and uploaded to local helm repository
- application is installed using helm with a post-render script to perform some normalization (e.g. set securityContext if missing)

Notes:
- runAsUser is configured explicitely or - if missing - a random (which each new deployment action) uid is assigned to the running containers and to files deployed (if any)

