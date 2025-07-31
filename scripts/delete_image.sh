#!/bin/bash

image="$1"
manifest="$2"

. set_env.sh

echo "deleting manifest, image: ${image}, manifest: ${manifest}"
curl -v -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X DELETE "https://${registry}/v2/$image/manifests/${manifest}"

