#!/bin/bash

. /etc/conf.d/helm

export category=$1
export KUBE_EDITOR=vi
export KUBECONFIG=/etc/kubernetes/admin.conf

export helm_dir=/shared/helm
export helm_options="--repository-config $helm_dir/config --repository-cache $helm_dir/cache "
function helm(){
  export podman_options="-t --rm --network host -v /tmp:/tmp -v /etc/kubernetes:/etc/kubernetes -v /etc/ssl/certs:/etc/ssl/certs -v $helm_dir:$helm_dir --workdir $PWD -v $PWD:$PWD -e KUBECONFIG=$KUBECONFIG"
  echo "podman_options:${podman_options}"
  [ "${category}" != "" ] && helm_options="${helm_options} -n ${category}"
  podman run ${podman_options} ${helm_image} $helm_options "$@"
}
export -f helm
export helm_repo=${category}
export helm_url="${helm_repo_base}/$helm_repo"
export helm_repo_dir=$helm_dir/$helm_repo

export my_ansible="ANSIBLE_PIPELINING=True ANSIBLE_NO_TARGET_SYSLOG=True ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook --extra-vars local_only=/data/mine/git -i inventory"

export env_is_set=1
