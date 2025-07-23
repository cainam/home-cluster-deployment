#!/bin/sh

# random delay
#sleep $(($RANDOM/100))

my_name=$(basename $0)
run_file="/var/run/${my_name}"

exec 2>&1
exec 1>> /var/log/${my_name}.log


. /usr/local/bin/set_env.sh 
export ANSIBLE_DIR=/data/mine/git/ansible
cd ${ANSIBLE_DIR}

procs=$(pgrep -c -f "$0")
if [ $procs -gt 1 ]; then
  message="already $procs processes running of ${my_name} => exit"
  logger "${message}"
  echo "${message}"
  exit
fi

logger "starting $my_name"

ansible-galaxy role  install -r requirements.yaml --roles-path "${ANSIBLE_DIR}"

eval $my_ansible ${ANSIBLE_DIR}/site.yml --tags=gentoo,emerge

eval $my_ansible ${ANSIBLE_DIR}/site.yml --tags=deploy --extra-vars limit_application=infopage

logger "finished $my_name"
