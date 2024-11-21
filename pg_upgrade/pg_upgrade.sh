#!/bin/sh

data_old="/data/pgdata_old"
data_new="/data/pgdata"

bin_new="/usr/lib/postgresql/17/bin"
bin_old="/usr/lib/postgresql/16/bin"

chown postgres:postgres /data
ls -l /data

mv "${data_new}" "${data_old}"
mkdir "${data_new}" && chown postgres:postgres "${data_new}"
su - postgres -c "${bin_new}/initdb  --pgdata=${data_new} --username=pg -A trust" 

su - postgres -c "${bin_new}/pg_upgrade -b ${bin_old} -B ${bin_new} -d ${data_old} -D ${data_new} -U pg --check --verbose" && 
su - postgres -c "${bin_new}/pg_upgrade -b ${bin_old} -B ${bin_new} -d ${data_old} -D ${data_new} -U pg --verbose"

ls -l "${data_new}"  "${data_old}"

sleep 1000
