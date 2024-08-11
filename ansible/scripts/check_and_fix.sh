#!/bin/bash

# script addresses crashing services issues: detect them, log them, fix them
. set_env.sh
timestamp=$(date +'%Y-%m-%d %H:%M:%S')
my_name=$(basename $0)

exec 2>> /var/log/${my_name}.log
exec >> /var/log/${my_name}.log

log(){
  echo "${timestamp}: ${name}: $1"
}

### internal central services
if ( ip a 2>/dev/null | grep -q "10.10.10.10"; ); then

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

# lighttpd
name="lighttpd"
out=$(curl -sv ${helm_repo_base} 2>&1)
ret=$?
if [ ${ret} -eq 35 ]; then
  log "known error: restarting service"
  rc-service lighttpd restart; sleep 5
  out=$(curl -sv ${helm_repo_base} 2>&1)
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
out=$(curl -s -X GET https://${registry}/v2/_catalog 2>&1)
ret=$?
if [ ${ret} -eq 35 ]; then
  log "known error: restarting service"
  rc-service registry restart; sleep 60
  out=$(curl -s -X GET https://${registry}/v2/_catalog 2>&1)
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

### external services
# wlan up

### local services
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
out=$(ls -l /shared/* 2>&1)
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
