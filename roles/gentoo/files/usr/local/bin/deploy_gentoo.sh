#!/bin/sh

my_name=$(basename $0)
exec 2>&1
exec 1>> /var/log/${my_name}.log

. /usr/local/bin/set_env.sh 
export ANSIBLE_DIR=/data/mine/home-cluster-deployment
[ ! -d "${ANSIBLE_DIR}" ] && mkdir -p $(dirname "${ANSIBLE_DIR}") && cd $(dirname "${ANSIBLE_DIR}") && git clone "${own_git_url}"

cd "${ANSIBLE_DIR}"
git pull

procs=$(pgrep -c -f "$0")
if [ $procs -gt 1 ]; then
  message="already $procs processes running of ${my_name} => exit"
  logger "${message}"
  echo "${message}"
  exit
fi

logger "starting $my_name"

eval $my_ansible ${ANSIBLE_DIR}/site.yml --tags=gentoo,emerge

eval $my_ansible ${ANSIBLE_DIR}/site.yml --tags=deploy --extra-vars limit_application=infopage

logger "finished $my_name"
