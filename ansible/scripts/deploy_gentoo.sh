#!/bin/sh

# random delay
sleep $(($RANDOM/100))

my_name=$(basename $0)
run_file="/var/run/${my_name}"

. /usr/local/bin/set_env.sh 
cd /data/mine/git/ansible/

[ -f "${run_file}" ] && exit 0
touch "${run_file}"

logger "starting $my_name"

eval $my_ansible /data/mine/git/ansible/site.yml --tags=gentoo,emerge

rm "${run_file}"
logger "finished $my_name"
