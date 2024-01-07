#!/bin/bash

date >> /tmp/ll
echo "$0 $1 $2 $3" >> /tmp/ll

#if [ "$3" = "MASTER" ]; then
#  /etc/init.d/run-registry restart
#  /etc/init.d/lighttpd restart 
#fi
