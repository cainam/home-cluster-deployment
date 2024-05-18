#!/bin/bash

d=$(date +"%Y.%m.%d %H:%M")
logf="/var/log/keepalive_notify.log"

(echo; echo "$d - starting script with: $0 $1 $2 $3 $4") >> "${logf}"
echo "$d - $1 $2 has transitioned to the $3 state with a priority of $4" >> "${logf}"
exec >> $logf
if [ "$2" = "k8s" ]; then
  if [ "$3" = "MASTER" ]; then
    for service in registry lighttpd; do
      #restart_out=$(/etc/init.d/${service} restart 2>&1)
      #restart_out=$(rc-service {service} restart 2>&1)
      echo "$d - restart output: $(rc-service ${service} restart 2>&1)" >> "${logf}"
      echo "$d - service status: ${service}: $( rc-service ${service} status | cat )" >> "${logf}"
    done
  else
    for service in registry lighttpd; do
      echo "$d - stop output: $(rc-service ${service} stop 2>&1)" >> "${logf}"
      echo "$d - service status: ${service}: $( rc-service ${service} status | cat )" >> "${logf}"
    done
  fi
fi
#if [ "$3" = "MASTER" ]; then
#  /etc/init.d/run-registry restart
#  /etc/init.d/lighttpd restart 
#fi
