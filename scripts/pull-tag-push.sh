#!/bin/bash

force=0

for i in "$@"; do
  case $i in
    -f|--force)
      force=1
      shift
      ;;
    *)
      ;;
  esac
done

while read arch img section comments; do
  image_only=$(basename ${img})
  bname=${image_only%%:*}
  version=${image_only#*:}
  section=${section#/*}
  section=${section%/*}
  mine=$(echo "$registry/$section/$bname:$version" | sed -e 's#/\+#/#g')
  manifest=$(echo "https://${registry}/v2/$section/$bname/manifests/$version" | sed -e 's#/\+#/#g')

  if [ ${force} -eq 1 ]; then
    echo "enforcing new image"
  else
    curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -H "Accept: application/vnd.oci.image.manifest.v1+json"  "${manifest}" --fail-with-body > /dev/null && continue
  fi

  echo "pulling $arch $img $section basename:$bname version:$version upload to section:$section/$bname:$version #$comments pushing as $mine";
  podman pull --quiet --arch=$arch $img;
  podman tag $img $mine; 
  podman push $mine; 
  podman image rm $img #)|| true
done
