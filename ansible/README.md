# what is included
- custom ansible filter plugin
- k8s operator written in python
- simple status page using FastAPI which async calls to fetch information from the systems
- EnvoyFilter with Lua script to modify authentication responses - really cool!

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
- calling Ansible example: eval $my_ansible site.yml --tags=deploy,build --extra-vars limit_application=deconz or eval $my_ansible site.yml --tags=deps,deploy --extra-vars \''{"limit_application":["zigbee2mqtt"]}'\'
- ANSIBLE_HOME to use /plugin/filters for custom filters and local_only: ANSIBLE_HOME=$PWD ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory standalone/k8s-status.yaml --extra-vars local_only=/data/mine/git 
- Ansible example, deploy Gentoo with build: ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory site.yml --tags=gentoo,emerge
- remove claimRef to free PV: kubectl patch pv keycloak -p '{"spec":{"claimRef": null}}'
- some variables are not part of the git repo, secrets which one has to define additionally like wifi WEP

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

kiali:
prometheus web.external_url got configured, kiali failed to connect to prometheus using no prefix, solved by:
  external_services:
    prometheus:
      auth:
        insecure_skip_verify: true
      url: http://prometheus-server.tools/prometheus/

test websocket: 
 curl -i -N      -H "Connection: Upgrade"     -H "Upgrade: websocket"     -H "Host: echo.websocket.org"     -H "Origin:http://www.websocket.org" http://klskld.org

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
    - enabled via FusionSolar webpage (device: SDongleA-05) - just configure device with port (502), slave id=1
    - Modbus could be also taken via efin converter on Smart Meter or on RS485 ports on Inverter, but SDongleA-05 required no additional hardware and is wireless
    - Home-Assistant: https://github.com/wlcrs/huawei_solar to custom_components/
  - Settings -> Energy Dashboard
  - update config in git: (cd /shared/home-assistant-config; find . ! -path "./custo*" ! -path "./deps*" ! -type d ! -name "*.log*" ! -size 0 ! -name ".HA_VERSION" | while read f; do if [ -f /data/mine/git/ansible/roles/deploy/*/home-assistant-config/$f ]; then diff -q  $f /data/mine/git/ansible/roles/deploy/*/home-assistant-config/$f;ret=$?;[ $ret -eq 1 ] && cat $f > /data/mine/git/ansible/roles/deploy/*/home-assistant-config/$f ; fi; done)

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

Kubernetes Dashboard:
- with update, skip-login was no longer possible, seems Authorization Header is required (https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md ), set-authorization-header can nolonger be used (https://oauth2-proxy.github.io/oauth2-proxy/configuration/alpha-config/)  => somehow set bearer token in oauth2-proxy or istio, see: https://elastisys.com/istio-and-oauth2-proxy-in-kubernetes-for-microservice-authentication/
- follow https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
- issue with publishing via HTTP => ISTIO (TLS), see https://github.com/kubernetes/dashboard/issues/9066 https://stackoverflow.com/questions/60281374/accessing-kubernetes-dashboard
=> reject with version > 7.5.0 or alternatives

Networking:
- Load-balancer <=> Gateway: one to one relationship
- Gateway <=> VirtualService: one to one relationship
- VirtualService <=> Application: one to many relationship
- inject istio sidecare, mutatingwebhookconfigraion update to inject sidecar based on label "app"

TODO: 
- helm\:from_git_to_local.sh: chart_version inheritance applies to dependencies too, manage with parameters to pull_local
- home-assistant: log file location should not be in /config, but seems not possible with configuration.yaml only using --log_file command line option but command line is hard-coded in docker image (/etc/services.d/home-assistant/run)
- k8s join - replace kubectl token create by managing boostrap tokens (secrete in kube-system namespace) directly, get valid if not expired, else create new
- dependencies: generalize waitdb initcontainer 
- consider helm_options for build (to have tags considered or: make new section in yaml to consider both)
- build all images from gentoo
- configure tempo in kiali
- install grafana
- import script: update Chart.yaml to contain the version of the software
- migrate prometheus-server volume to longhorn
- postgresql major version update: include docker build in playbook, parameterize versions and other vars set

- start keepalived after glusterd is up
- haproxy: why doesn't it start at boot? shouldn't it be started via keepalived?
- infopage: click on href to delete image results in new-tab, but no tab should be opened
