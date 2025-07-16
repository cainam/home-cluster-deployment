#!/bin/bash
my_name=$(basename $0)
exec 2>&1
exec 1>> /var/log/${my_name}.log
#exec 2>> /var/log/${my_name}.log

export PATH=/usr/local/bin/:$PATH

# script addresses crashing services issues: detect them, log them, fix them

. set_env.sh
timestamp=$(date +'%Y-%m-%d %H:%M:%S')

log(){
  echo "${timestamp}: ${name}: $1"
}

### external services
# wlan up
name="wlan"
if [ "$(cat /sys/class/net/wlan0/operstate)" == "down" ]; then
  log "wlan is down"
  if [ "$(rc-service iwd status --nocolor 2>&1 | grep status | cut -d ":" -f 2 | cut -c 2-)" != "started" ]; then
    log "iwd is not started: restarting service"
    rc-service iwd restart
  fi
  if [ "$(cat /sys/class/net/wlan0/operstate)" == "down" ]; then
    log "wlan is still down"
  fi
else
  log "ok"
fi

# ### local services
# DNS 
name="dns"
out=$(> /dev/tcp/$(grep ^nameserver /etc/resolv.conf | awk '{print $2}')/53)
ret=$?
if [ ${ret} -ne 0 ]; then
  log "cannot reach nameserver, restarting iwd"
  rc-service iwd restart
  out=$(> /dev/tcp/$(grep ^nameserver /etc/resolv.conf | awk '{print $2}')/53)
    ret=$?
  if [ ${ret} -ne 0 ]; then
    log "problem NOT fixed"
  else
    log "problem fixed"
  fi
else
  log "ok"
fi

# kubelet
name="kubelet"
if [ "$(rc-service kubelet status --nocolor 2>&1 | grep status | cut -d ":" -f 2 | cut -c 2-)" != "started" ]; then
  log "kubelet is not started: restarting service"
  rc-service kubelet restart
else
  log "ok"


# gluster vol list
name="gluster vol list"
out=$(gluster vol list 2>&1)
ret=$?
if [ ${ret} -ne 0 ]; then
  if ( echo "${out}" | grep "Connection failed. Please check if gluster daemon is operational." ); then
    log "known error: restarting service"
  else
    log "unknown error: restarting service"
  fi
  rc-service glusterd restart
  out=$(gluster vol list 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    log "problem NOT fixed"
  else
    log "problem fixed"
  fi
else
  log "ok"
fi

# gluster mounts
name="/shared mounts"
out=$(ls -l /shared/ 2>&1)
ret=$?
fs=$(echo "$out" | head -n 1 | cut -d "'" -f 2)

if [ ${ret} -ne 0 ]; then
  log "NOT ok, trying umount"
  out=$(for a in /shared/*; do umount "${a}"; done 2>&1 )
  out=$(ls -l /shared/ 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    log "problem NOT fixed, trying restart autofs"
    rc-service autofs restart
    out=$(ls -l ${fs} 2>&1)
    ret=$?
    if [ ${ret} -ne 0 ]; then
      log "problem NOT fixed, giving up"
    else
      log "problem fixed"
    fi
    
  else
    log "problem fixed"
  fi
else
  log "ok"
fi

# haproxy
name="haproxy"
out=$(ps -ef | grep hap | grep -v root | wc -l)
ret=$?
if [ ${out} -gt 20 ]; then
  log "known error: restarting service"
  ps -ef | grep hap | grep -v root | awk '{print $2}' | xargs kill -SIGUSR1 ; /etc/init.d/haproxy restart
  out=$(ps -ef | grep hap | grep -v root | wc -l)
  ret=$?
  if [ ${out} -gt 20 ]; then
    log "problem NOT fixed"
  else
    log "problem fixed"
    sleep 10
  fi
else
  log "ok"
fi

### internal central services
if ( ip a 2>/dev/null | grep -q "10.10.10.10"; ); then

# lighttpd
name="lighttpd"
out=$(curl -sv ${helm_url} 2>&1)
#log "helm url: ${helm_url}"
ret=$?
if [ ${ret} -eq 35 ]; then
  log "known error: restarting service"
  rc-service lighttpd restart; sleep 5
  out=$(curl -sv ${helm_url} 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    log "problem NOT fixed"
  else
    log "problem fixed"
  fi
elif [ ${ret} -ne 0 ]; then
  log "NOT ok, unknown error code: ${ret}: ${out}"
else
  log "ok"
fi

# registry
name="registry"
out=$(curl -sv -X GET https://${registry}/v2/_catalog 2>&1)
ret=$?
if [ ${ret} -eq 35 ]; then
  log "known error: restarting service"
  rc-service registry restart; sleep 60
  out=$(curl -sv -X GET https://${registry}/v2/_catalog 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    log "problem NOT fixed"
  else
    log "problem fixed"
  fi
elif [ ${ret} -ne 0 ]; then
  log "NOT ok, unknown error code: ${ret}: ${out}"
else
  log "ok"
fi

fi
