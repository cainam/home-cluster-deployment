#!/bin/bash

while 
read space pv_name gluster_vol_name; do
[ "$space" == "" ] && echo "pipe per line: space pv_name gluster_vol_name" && exit 0

echo "processing input: space=${space} pv_name=${pv_name} gluster_vol_name=${gluster_vol_name}"

#kubectl delete service -n ${space} glusterfs
#kubectl delete ep -n ${space} glusterfs
#kubectl delete pv ${pv_name}

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
 name: glusterfs
 namespace: ${space}
spec:
 ports:
 - port: 49152
EOF
 
kubectl apply -f - <<EOF
apiVersion: v1
kind: Endpoints
metadata:              
 name: glusterfs         
 namespace: ${space}
subsets:                     
 - addresses:                   
    - ip: 192.168.3.133   
   ports:
     - port: 49152
 - addresses:
    - ip: 192.168.4.101   
   ports:
     - port: 49152
EOF

kubectl apply -f - <<EOF                     
apiVersion: v1
kind: PersistentVolume
metadata:              
 namespace: ${space}
 name: ${pv_name}
 labels:                     
   storage.k8s.io/name: glusterfs
spec:                              
 accessModes:                     
   - ReadWriteOnce                
   - ReadOnlyMany                 
   - ReadWriteMany                
 capacity:                        
   storage: 10Gi   
 storageClassName: ""
 persistentVolumeReclaimPolicy: Retain
 volumeMode: Filesystem                 
 glusterfs:                             
   endpoints: glusterfs                 
   path: ${gluster_vol_name}
   readOnly: no                         
EOF

done
