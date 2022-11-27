#!/bin/bash

reg=myregistry.adm13:443

while read arch img section comments; do
  bname=$(basename ${img%%:*});
  version=${img#*:};
  mine=$reg$section$bname:$version; 
  echo "pulling $arch $img $section basename:$bname version:$version upload to section:$section/$bname:$version #$comments pushing as $mine";
  podman pull --arch=$arch $img;
  podman tag $img $mine; 
  podman push $mine;
done
