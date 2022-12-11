#!/bin/bash

myregistry=10.10.10.10

curl -k -I https://${myregistry}:443/v2/_catalog 

for image in $(curl -k -s https://${myregistry}:443/v2/_catalog | jq -r '.repositories[]' ); do curl -k -s https://${myregistry}:443/v2/$image/tags/list | jq -r '. | .tags[]' | sed -e "s#^#$image #g"; done

alias etcdctl="etcdctl --write-out=table --endpoints=k8s-1-int.adm13:2379,k8s-2-int.adm13:2379  --insecure-skip-tls-verify=true --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"

