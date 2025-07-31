#!/bin/bash

. set_env.sh

curl -s  -X GET https://${registry}/v2/_catalog | jq -r '.repositories[]' | while read img; do 
  tags=$(curl -s -X GET https://${registry}/v2/$img/tags/list  | jq -r '.tags[]' 2>/dev/null); 
  for t in $tags; do 
    echo -n "img: $img tag: $t";
    digest=$(curl -v -H  "Accept: application/vnd.docker.distribution.manifest.v2+json" -H "Accept: application/vnd.oci.image.manifest.v1+json" -X HEAD  https://${registry}/v2/$img/manifests/$t 2>&1 | grep docker-content-digest: | awk '{print $3}' | tr -d "\r");
    echo -n " $digest" ;
    size=$(curl -s -H  "Accept: application/vnd.docker.distribution.manifest.v2+json" -H "Accept: application/vnd.oci.image.manifest.v1+json" -X GET https://${registry}/v2/$img/manifests/$digest| jq "([.layers[].size/(1024*1024)] | add) | round")
    echo " size: $size MB"
  done;
done
