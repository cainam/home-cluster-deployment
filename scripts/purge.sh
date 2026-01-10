#!/bin/bash

my_name=$(basename $0)
exec 2>&1
exec 1>> /var/log/${my_name}.log

. /usr/local/bin/set_env.sh

# cleanup build directories
if [ ! -z "${build_dir}" -a "${build_dir}" != "/" ]; then
  find "${build_dir}"/ -type f -mtime +${age_before_purge} -print # -delete if ok
  find "${build_dir}"/ -type d -empty -print # -delete if ok
fi

# gentoo files for image building
for file_type in packages distfiles; do
  podman run -it --rm --volume "${foundation_dir}"/portage-${portage_release}:/var/db/repos/gentoo  --volume "${foundation_dir}"/packages:/packages --volume "${foundation_dir}"/distfiles/:/distfiles $(podman image ls | grep my_builder | head -n 1 | awk '{print $3}') eclean ${file_type}
done

# defrag k8s etcd
etcdctl defrag

# purge unused container images
configured_images=$(kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image} {.items[*].spec.initContainers[*].image}' | tr -s '[[:space:]]' '\n' | sort -u)
protected_images="registry:|pause|my_builder|stage3-|go:|base:|nodejs:|python3:"
podman image ls --format '{{.Repository}}:{{.Tag}} {{.ID}}' | sed -e "s#^${registry}/##g" | while read image id; do
  #image=$(echo "${image_with_id}" | cut -d : -f 1,2)
  #id=$(echo "${image_with_id}" | cut -d : -f 3)
  echo "${image}" | grep -Eq "${protected_images}" && continue
  echo "${image}" | grep -Eq "<none>:<none>$" && (echo "delete $image"; podman image rm -f "${id}") && continue
  echo "${configured_images}" | grep -Eq "^${image}$|^${registry}/${image}$" || (echo "delete $image"; podman image rm -f "$image")
done

# registry garbage collect
rc-service registry status && podman exec -it registry bin/registry garbage-collect --delete-untagged /var/lib/registry/config.yml
