#!/bin/bash

export category=$1

export KUBECONFIG=/etc/kubernetes/admin.conf

export images_list="/data/meinKram/conf/images.list"
export images_map="/data/meinKram/conf/images.map"

export registry="myregistry.adm13:443"

export helm_dir=/shared/helm
export helm_options="--repository-config $helm_dir/config --repository-cache $helm_dir/cache "
export xpodman_options="-t --rm --network host -v /tmp:/tmp -v /etc/kubernetes:/etc/kubernetes -v /etc/ssl/certs:/etc/ssl/certs -v $helm_dir:$helm_dir --workdir $PWD -v $PWD:$PWD -e KUBECONFIG=$KUBECONFIG"
alias helmx="podman run ${podman_options} myregistry.adm13:443/helm:v3.10.2 $helm_options"
function helm(){
  export podman_options="-t --rm --network host -v /tmp:/tmp -v /etc/kubernetes:/etc/kubernetes -v /etc/ssl/certs:/etc/ssl/certs -v $helm_dir:$helm_dir --workdir $PWD -v $PWD:$PWD -e KUBECONFIG=$KUBECONFIG"
  echo "podman_options:${podman_options}"
  [ "${category}" != "" ] && helm_options="${helm_options} -n ${category}"
  podman run ${podman_options} ${registry}/helm:3.12.2 $helm_options $*
}
export -f helm
export helm_repo=${category}
export helm_url=https://helm.adm13:9443/$helm_repo
export helm_repo_dir=$helm_dir/$helm_repo

export my_ansible="ANSIBLE_NO_TARGET_SYSLOG=True ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook --extra-vars local_only=/data/mine/git -i inventory"

export env_is_set=1
