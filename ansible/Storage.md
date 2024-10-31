Initially the setup was using gluster only as shared, cluster-internal storage, but this turned out to be not a good choice in terms of performance.
For this reason longhorn as K8S clustered solution was added 

Usage: 
- gluster was kept for the needs outside the k8s cluster itself like docker registry and helm repository and for storage which is maintained via ansible like configuration
- longhorn is used for internal k8s storage needs


