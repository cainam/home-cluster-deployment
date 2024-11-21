#!/bin/bash

pw="$1"

old_version=15.6-alpine
new_version=16.1-alpine

pg_image="myregistry.adm13:443/db/postgres"

data_org="/shared/data-postgresql-0/pgdata"
data_org="/data/gluster/bricks/postgresql/data-postgresql-0/pgdata/"

#rm -rf /tmp/pg_migrate && cp -rdp "${data_org}" /tmp/pg_migrate
mkdir /tmp/pg_new && chown postgres:1001 /tmp/pg_new

get_fs="podman image mount"
old_fs=$(eval ${get_fs} ${pg_image}:${old_version} 2> /dev/null)
new_fs=$(eval ${get_fs} ${pg_image}:${new_version} 2> /dev/null)

echo -e "layers:\nold_fs: ${old_fs}\nnew_fs: ${new_fs}"

podman run -it --user postgres --rm -v ${old_fs}:/old -v ${new_fs}:/new -v /tmp/pg_migrate:/pg_migrate --workdir /tmp -v /tmp/pg_new:/pg_new ${pg_image}:${new_version}  bash -c "
echo -n 'old:'; /old/usr/local/bin/pg_upgrade --version
echo -n 'new:'; /new/usr/local/bin/pg_upgrade --version
/new/usr/local/bin/initdb --pgdata=/pg_new --username=pg -A trust # password --pwfile=<(echo \"${pw}\")
#/new/usr/local/bin/pg_ctl -D /pg_new -l logfile start

/new/usr/local/bin/pg_upgrade -b  /old/usr/local/bin/ -B  /new/usr/local/bin/ -d /pg_migrate -D /pg_new -U pg --check --verbose && 
/new/usr/local/bin/pg_upgrade -b  /old/usr/local/bin/ -B  /new/usr/local/bin/ -d /pg_migrate -D /pg_new -U pg --verbose
" 
