# notes on this ansible playbook

Usage example: 
    `# ansible-playbook  -i $PWD/inventory $PWD/site.yml --skip-tags k8s_images`


New install:
- stage3+portage+git-clone-firmware
- enable net.end0+sshd
- sync /lib/firmware/bmrc and /cypress and /var/db/repos/gentoo

Notes:
- trying to run on one host only using run_once/delegate_to did only work having a hostname set as fact not with a variable. It seems like vars are re-evaluated when accessed, but facts remain constant
- uninstall of kubernetes is triggered using "--tags=all,force_reinstall", otherwise force_reinstall is skipped
- calling Ansible example: eval $my_ansible site.yml --tags=deploy,build --extra-vars limit_application=deconz site.yml --tags=deploy,build --extra-vars 'limit_namespace="istio-ingress"
- ANSIBLE_HOME to use /plugin/filters for custom filters and local_only: ANSIBLE_HOME=$PWD ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory standalone/k8s-status.yaml --extra-vars local_only=/data/mine/git 
- Ansible example, deploy Gentoo with build: ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory site.yml --tags=gentoo,emerge
- remove claimRef: kubectl patch pv keycloak -p '{"spec":{"claimRef": null}}'
- create token: kubectl create token -n tools kiali-service-account
- gluster - change size: use "vol replace-brick" and replace brick by brick 
- gluster repair - split-brain: 
    brickdir=/data/gluster/bricks/home-assistant/home-assistant-config/
    backupdir=/
    for a in auth.session ; do cp $brickdir/$a $backupdir/$a; inum=$(ls -ain $brickdir/.storage/$a | awk '{print $1}'); f=$(find $brickdir/.glusterfs  -inum $inum);rm $brickdir/$a $f; cp -dp $backupdir/$a $brickdir/$a;  done


Manage Registry:
- remove from registry: # list_images.sh | grep keycloak | grep 19 | awk '{print $2" "$5}' | xargs delete_image.sh
- fix corruption/0-byte files: find /var/lib/registry/docker/registry/v2 -size 0 -path "*_manifests/revisions/sha256*" -exec rm -v {} \;
- delete physically: # podman exec -it registry bin/registry garbage-collect /etc/docker/registry/config.yml
- additionally sometimes structures have to be removed in /var/lib/registry/docker/registry/v2/repositories when no image version is shown

etcd:
# alias etcdctl="etcdctl --write-out=table --endpoints=k8s-1-int.adm13:2379,k8s-2-int.adm13:2379,k8s-3-int.adm13:2379  --insecure-skip-tls-verify=true --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
# etcdctl endpoint status
# etcdctl endpoint health
# etcdctl defrag
if failure - restore or clean nodes manually and restart one with existing db using --force-new-cluster into manifest (see https://itnext.io/breaking-down-and-fixing-etcd-cluster-d81e35b9260d) 
failure: "snap: snapshot file doesn't exist", "failed to recover v3 backend from snapshot", "failed to find database snapshot file (snap: snapshot file doesn't exist)": fixed on faulty node by:
1. stop kubelet
2. backup
3. delete member/snap/*snap and member/*/*wal
4. start kubelet

keycloak:
- error "Caused by: org.h2.mvstore.MVStoreException: The write format 2 is smaller than the supported format 3 [2.2.220/5]" => fix by migrating the DB to a newer version: java -jar H2MigrationTool-1.4-all.jar -d keycloakdb.mv.db -f 2.0.202 -t 2.2.220 --user sa --password password

kiali:
prometheus web.external_url got configured, kiali failed to connect to prometheus using no prefix, solved by:
  external_services:
    prometheus:
      auth:
        insecure_skip_verify: true
      url: http://prometheus-server.tools/prometheus/

tor:
  - test socks5 cluster internally: curl -L  socks5://tor.anon:9050 http://tagesschau.de
  - disable istio sidecar by:         sidecar.istio.io/inject: "false" 


home-assistant:
  - DB, postgreSQL to start with, but for future use DBs guide: https://smarthomescene.com/guides/optimize-your-home-assistant-database/
  - not possible to change webroot, so subdomain used instead
  - only managed to get it manually from a running instance
    # llt="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI3NDNlOWEzNDQ4ZjQ0ODEzYjQ5ZmQ3N2M3ZTFmODQ3YiIsImlhdCI6MTY4ODI4MjA2NiwiZXhwIjoyMDAzNjQyMDY2fQ.vdlnHJWNoIaXaxbf3UF1sIxgEi1rOMbAdAh2kctiQt0"
    # curl -s -X GET  -H "Authorization: Bearer $llt" https://ha.my-lb.adm13/api/services | jq .[].domain -r
  - usage: 
  - "long_lived_access_token":
    1. remove from config, restart, add again, it works again ... seems like it can be automated
    2. add token manually again
    3. if ok, add automatically
    4. use it! => yeah, works, but no straight forward automation, at least using copy of manual config can be reused for full automation
  - MQTT integration: manually added
  - install fusion solar => 
    - no need to add HACS (scripts/get_hacs.sh): in HACS
    - git clone https://github.com/tijsverkoyen/HomeAssistant-FusionSolar.git, move custom_component to HA and add integration 
    - configure with Kiosk URL from Huawei
  - data is outdated (max 30min late) so connection via Modbus
    - enabled via FusionSolar webpage (device: SDongleA-05) - just configure device with port (502)
    - Modbus could be also taken via efin converter on Smart Meter or on RS485 ports on Inverter, but SDongleA-05 required no additional hardware and is wireless
    - Home-Assistant: https://github.com/wlcrs/huawei_solar to custom_components/
  - Settings -> Energy Dashboard

VPN wireguard (Fritzbox + Android):
  - tunnel created
  - external coredns service interface used as DNS in wireguard

Fritz.Box: 
  - configure floating IP: stop floating IP in network, flush cache by changing the DHCP range, add portfreigabe an start floating IP again
  - DYNDNS: dyndns domain added to certificates as alt-names


Deconz:
flash:
# # git clone https://github.com/dresden-elektronik/gcfflasher.git
# git checkout v4.3.0-beta
# ./build_cmake.sh
# kubectl scale --replicas=0 -n home deploy deconz
# build/GCFFlasher -d /dev/ttyAMA0 -f /root/deCONZ_RaspBeeII_0x26780700.bin.GCF
- conbee III: stty -F /dev/ttyUSB0 115200 is crucial; startup debugging: DEBUG=zigbee-herdsman*
- Woolley BSD29/BSD59: issues: offline suddenly and autonomous power-off after few secs, got it working with config adapter_delay=350 plus "Min rep change" to 29 and then to 0 (yes, strange!)
- Zigbee is sensible: stay away from USB devices (use cable) and use a Zigbee channel far away from 2.4GHz WLAN channel you use

Mosquitto:
- remove messages flagged for retain: # mosquitto_sub -h localhost -u x -P x -v --retained-only --remove-retained -t 'zigbee2mqtt/Zimmertr/availability' -E

Networking:
- Load-balancer <=> Gateway: one to one relationship
- Gateway <=> VirtualService: one to one relationship
- VirtualService <=> Application: one to many relationship

Database:
- PostgreSQL update:
  1. scale down: kubectl scale --replicas=0 -n db statefulset postgresql
  2. run ./scripts/migrate_postgresql.sh
  3. move old data (e.g. mv /shared/data-postgresql-0/pgdata/ /shared/data-postgresql-0/pgdata.15.6)
  4. copy new data in place (e.g. cp -rdp /tmp/pg_new/ /shared/data-postgresql-0/pgdata/)
  5. deploy update postgreSQL
- tuning auf gluster: gluster vol set data-postgresql-0 group db-workload

TODO: 
- helm\:from_git_to_local.sh: chart_version inheritance applies to dependencies too, manage with parameters to pull_local
- add simple echo server via helm: https://github.com/mendhak/docker-http-https-echo
- error route_not_found in istiod access log (404) using a subdomain (root cause not found, switching to dedicated IP for subdomain for dyndns usage too). Same happened with multiple gateways, there solved by using individual certificates per domain
- /etc/localtime + /etc/timezone
- gentoo_build in inventory and gentoo-binhost in hosts - replace by configuration in global vars and create hosts from template
- /var/db/repos - local on build, gluster vol for others
- gluster peering - playbook runs no random node, but has to run only on a node part of the existing gluster
- k8s join - replace kubectl token create by managing boostrap tokens (secrete in kube-system namespace) directly, get valid if not expired, else create new
- custom filter: depenencies (db + gateway)
- dependencies: limit_XXXX => build array and check if item is in array
- dependencies: generalize waitdb initcontainer 
- create keycloak config via script, e.g. https://suedbroecker.net/2020/08/04/how-to-create-a-new-realm-with-the-keycloak-rest-api/ 
- replace hard-coded by application vars: roles/deploy/templates/home-assistant-config/configuration.yaml
- consider helm_options for build (to have tags considered or: make new section in yaml to consider both)
- gatways have to be kicked by e.g. kubectl delete pod -n istio-ingress gateway-xxx-yyy to use the new image injected via webhook => include this in the playbook
- build all images from gentoo
- remove registry from runlevel: only controlle by keepalived
- configure tempo in kiali
- install grafana
- ensure that kubelet and crio are always running
- replace gluster by ??? openebs is not yet compatible with Raspberry
