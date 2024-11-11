#!/bin/sh

# random delay
#sleep $(($RANDOM/100))

my_name=$(basename $0)
run_file="/var/run/${my_name}"

exec 2>&1
exec 1>> /var/log/${my_name}.log


. /usr/local/bin/set_env.sh 
cd /data/mine/git/ansible/

#[ -f "${run_file}" ] && exit 0
#touch "${run_file}"
#procs=$(pgrep -c -f "${my_name}")
procs=$(pgrep -c -f "$0")
if [ $procs -gt 1 ]; then
  message="already $procs processes running of ${my_name} => exit"
  logger "${message}"
  echo "${message}"
  exit
fi

logger "starting $my_name"

eval $my_ansible /data/mine/git/ansible/site.yml --tags=gentoo,emerge

#rm "${run_file}"
logger "finished $my_name"
