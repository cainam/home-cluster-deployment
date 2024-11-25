Initially the setup was using gluster only as shared, cluster-internal storage, but this turned out to be not a good choice in terms of performance.
For this reason longhorn as K8S clustered solution was added.

As not all pods are changing the data (e.g. webpage only), also local folders got added.
Remark: gluster shares are also handled as local folders by Kubernetes.

Usage: (local is default)
- storageClass local: gluster was kept for the needs outside the k8s cluster itself like docker registry and helm repository and for storage which is maintained via ansible like configuration
- storageClass local: local folders, content static and handled by ansible
- storageClass longhorn: longhorn is used for internal k8s storage needs

Storage content can only be deployed to local folders and gluster shares, not to longhorn volumes.

Other solutions: OpenEBS is not yet compatible with Raspberry, Piraeus with DRBD could be an option, too.

Database:
upgrade:
1. AUTOMATE BEFORE NEXT UPGRADE: build image from
2. run playbook standalone/pg_update.yaml
- tuning auf gluster: gluster vol set data-postgresql-0 group db-workload
- meassure pg performance with storage:
  pgbench -i -s 50 --foreign-keys -h dbperf-postgresql -U pg  postgres
  pgbench  -h dbperf-postgresql -U pg  postgres -t 10000
  gluster:
    latency average = 174.666 ms
    initial connection time = 53.350 ms
    tps = 5.725199 (without initial connection time)
  longhorn:
    latency average = 12.016 ms
    initial connection time = 42.499 ms
    tps = 83.224261 (without initial connection time)

longhorn:
- shared mounts are enabled via /etc/fstab
- check disk (shared propagation is required): findmnt -o TARGET,PROPAGATION /var/lib/longhorn/
- check and delete longhorn crds: kubectl get crd -o jsonpath={.items[*].metadata.name} | tr ' ' '\n' | grep longhorn.io | xargs kubectl delete crd
- list api-resources in namespace: kubectl api-resources --verbs=list --namespaced -o name | grep -v ^events  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n storage
- delete: 
# cat longhorn-confirm-deletion.yaml
apiVersion: longhorn.io/v1beta2
kind: Setting
metadata:
  name: deleting-confirmation-flag
# kubectl apply -f longhorn-confirm-deletion.yaml
"README.md" 196L, 13280B                                      

gluster:
- change size: use "vol replace-brick" and replace brick by brick
- repair split-brain:
    files=$(gluster vol heal home-assistant-config info | grep ^/ | sort -u | grep -v split-brain)
    brickdir=/data/gluster/bricks/home-assistant/home-assistant-config/
    backupdir=/tmp/bck
    mkdir -p ${backupdir}
    for a in $files;do rsync --mkpath -a $brickdir/$a $backupdir/$a;inum=$(ls -aind $brickdir/$a | awk '{print $1}'); f=$(find $brickdir/.glusterfs  -inum $inum);rm $brickdir/$a $f;[ "$f" != "" ] &&  rsync --mkpath -a $backupdir/$a $brickdir/$a;  done

