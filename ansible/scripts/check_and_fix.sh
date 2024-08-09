#!/bin/bash

# script addresses crashing services issues: detect them, log them, fix them
. set_env.sh
timestamp=$(date +'%Y-%m-%d %H:%M:%S')

### internal central services
if ( ip a 2>/dev/null | grep -q "10.10.10.10"; ); then

# haproxy
name="haproxy"
out=$(ps -ef | grep hap | grep -v root | wc -l)
ret=$?
if [ ${out} -gt 20 ]; then
  echo "${timestamp}: ${name}: known error: restarting service"
  ps -ef | grep hap | grep -v root | awk '{print $2}' | xargs kill -SIGUSR1 ; /etc/init.d/haproxy restart
  out=$(ps -ef | grep hap | grep -v root | wc -l)
  ret=$?
  if [ ${out} -gt 20 ]; then
    echo "${timestamp}: ${name}: problem NOT fixed"
  else
    echo "${timestamp}: ${name}: problem fixed"
    sleep 10
  fi
else
  echo "${timestamp}: ${name}: ok"
fi
# lighttpd
name="lighttpd"
out=$(curl -sov ${helm_repo_base} 2>&1)
ret=$?
if [ ${ret} -eq 35 ]; then
  echo "${timestamp}: ${name}: known error: restarting service"
  rc-service lighttpd restart; sleep 5
  out=$(curl -sov ${helm_repo_base} 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "${timestamp}: ${name}: problem NOT fixed"
  else
    echo "${timestamp}: ${name}: problem fixed"
  fi
elif [ ${ret} -ne 0 ]; then
  echo "${timestamp}: ${name}: NOT ok, unknown error code: ${ret}"
else
  echo "${timestamp}: ${name}: ok"
fi

# registry
name="registry"
out=$(curl -s  -X GET https://${registry}/v2/_catalog 2>&1)
ret=$?
if [ ${ret} -eq 35 ]; then
  echo "${timestamp}: ${name}: known error: restarting service"
  rc-service registry restart; sleep 60
  out=$(curl -s  -X GET https://${registry}/v2/_catalog 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "${timestamp}: ${name}: problem NOT fixed"
  else
    echo "${timestamp}: ${name}: problem fixed"
  fi
elif [ ${ret} -ne 0 ]; then
  echo "${timestamp}: ${name}: NOT ok, unknown error code: ${ret}"
else
  echo "${timestamp}: ${name}: ok"
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
    echo "${timestamp}: ${name}: known error: restarting service"
  else
    echo "${timestamp}: ${name}: unknown error: restarting service"
  fi
  rc-service glusterd restart
  out=$(gluster vol list 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "${timestamp}: ${name}: problem NOT fixed"
  else
    echo "${timestamp}: ${name}: problem fixed"
  fi
else
  echo "${timestamp}: ${name}: ok"
fi

# gluster mounts
name="/shared mounts"
out=$(ls -l /shared/* 2>&1)
ret=$?
fs=$(echo "$out" | head -n 1 | cut -d "'" -f 2)

if [ ${ret} -ne 0 ]; then
  echo "${timestamp}: ${name}: NOT ok, trying umount"
  umount /shared/*
  out=$(ls -l /shared/* 2>&1)
  ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "${timestamp}: ${name}: problem NOT fixed, trying restart autofs"
    rc-service autofs restart
    out=$(ls -l ${fs} 2>&1)
    ret=$?
    if [ ${ret} -ne 0 ]; then
      echo "${timestamp}: ${name}: problem NOT fixed, giving up"
    else
      echo "${timestamp}: ${name}: problem fixed"
    fi
    
  else
    echo "${timestamp}: ${name}: problem fixed"
  fi
else
  echo "${timestamp}: ${name}: ok"
fi
