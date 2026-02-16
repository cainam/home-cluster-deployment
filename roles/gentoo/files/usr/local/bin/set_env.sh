#!/bin/bash

. /etc/conf.d/home-cluster

export ANSIBLE_ROLES_PATH=${ANSIBLE_DIR}/roles
export my_ansible="ANSIBLE_PIPELINING=True ANSIBLE_NO_TARGET_SYSLOG=True ANSIBLE_CALLBACK_RESULT_FORMAT=yaml ansible-playbook --extra-vars local_only=${LOCAL_CONF} -i inventory"
export env_is_set=1
