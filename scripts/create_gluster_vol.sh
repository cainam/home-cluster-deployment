#!/bin/bash 

gluster_dir=/data/gluster
(read name sz; b=""; while read hconf; do 
echo "name: $name, size:$sz";
h=$(echo "$hconf" | cut -d = -f 1);
cnt=$(echo "$hconf" | cut -d = -f 2);
echo "host: $h number of vols: $cnt"
for i in $(seq 1 $cnt); do 
  ssh -n $h "
  brick=${gluster_dir}/brick_${name}_${i};
  disk=\"${gluster_dir}/disk_${name}_$i\";
  echo \"brick: \$brick disk:\$disk\";
  umount \"\$brick\";
  [ -f \"\$disk\" ] && echo 'datafile exists, fix manually, exit' && exit 1
  truncate -s ${sz} \"\$disk\";
  mkfs.ext4 \"\$disk\";
  [ ! -d \"\$brick\" ] && mkdir \"\$brick\";
  mount \"\$disk\" \"\$brick\"
  mkdir \"\$brick\"/data "|sed -e "s/^/$h: /g";
  b="$b $h:${gluster_dir}/brick_${name}_${i}/data";
done;done;
echo "creating bricks from $b";
gluster volume create $name replica 2 transport tcp $b force;
gluster vol set $name transport.address-family inet;
gluster volume set $name cluster.quorum-type fixed
gluster volume set $name cluster.quorum-count 2
gluster volume start $name) 

