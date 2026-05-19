# testing

molecule is used to perform testing

1. a CronJob running a molecule image is deployed on the cluster
2. the Cron uses a podman service running on a node to execute the testing
3. results are stored as annotations of the CronJob
4. infopage application reads the annotations and shows them on a webpage

## security
- podman service runs rootless with the user podman
- the host keys are signed by an SSH CA and the podman client accepts the CA in its known_hosts file (which is deployed via k8s secret)
- the podman service user has the public user key configured in authorized_keys

