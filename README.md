# what is included
- custom ansible filter plugin
- k8s operator written in python
- simple status page using FastAPI which async calls to fetch information from the systems
- EnvoyFilter with Lua script to modify authentication responses - really cool!

# usage
some additional files are required for handling sensitive information (like passwords), these are to be stored at $local_conf (files: secret)

Challenges:
### recursion with playbooks
challenge: images are build using playbooks, but they have downstream dependencies and within the build another build has to be triggered first, but there is no task level scope of variables in Ansible
solution: a combination of dynamic variables and a stack of them ensures that a build within a build can be performed 

### new node
- populate /boot partition with copy and root from stage3-arm64-openrc
- /boot/cmdline.txt => update root=PARTUUID from  lsblk -o NAME,UUID,PARTUUID /dev/sdf, set /etc/conf.d/hostname to FQDN and define FQDN in /etc/hosts
- configure end0 in /etc/conf.d/net, authorized_keys, create net.end0 link net.lo, admin + host keypair from secrets(key with go-r mod)  and enable sshd and net.end0 in /etc/runlevel/default => boot!
- update UUID and PARTUUID in inventory file and if host to be installed is gentoo-build, remove this from the inventory
- run deploy gentoo ( to test: run without emerge option, then emerge --keep-going --verbose --update --deep --newuse --usepkg --ask --with-bdeps=y @world), reboot to fix missing module issue for iwd - or fix the issue, check if interface is there,  modprobe brcmfmac got added to script
- gluster: remove former bricks if any:  (for v in $(gluster vol list); do gluster vol heal $v info | grep k8s-3 | sed -e "s/^Brick/$v/g"; done) | while read v b;do (echo "y" | gluster vol remove-brick $v replica 2 $b force); done
- gluster: gluster peer detach k8s-3-int.adm13 and gluster peer probe k8s-3-int.adm13
- Emerge: missing binary packages can be created using e.g. quickpkg --include-config y lua
- remove node from k8s and from etcd
- deploy k8s

# notes on this ansible playbook
Usage example: 
- `# ansible-playbook  -i $PWD/inventory $PWD/site.yml --skip-tags k8s_images`
- build a dedicated image: eval $my_ansible site.yml --tags=images-only --extra-vars \''{"limit_images":["fastapi"]}'\'

Notes:
- trying to run on one host only using run_once/delegate_to did only work having a hostname set as fact not with a variable. It seems like vars are re-evaluated when accessed, but facts remain constant
- uninstall of kubernetes is triggered using "--tags=all,force_reinstall", otherwise force_reinstall is skipped
- calling Ansible example: eval $my_ansible site.yml --tags=deploy,build --extra-vars limit_application=deconz or eval $my_ansible site.yml --tags=deps,deploy --extra-vars \''{"limit_application":["zigbee2mqtt"]}'\'
- ANSIBLE_HOME to use /plugin/filters for custom filters and local_only: ANSIBLE_HOME=$PWD ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory standalone/k8s-status.yaml --extra-vars local_only=/data/mine/git 
- Ansible example, deploy Gentoo with build: ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory site.yml --tags=gentoo,emerge
- remove claimRef to free PV: kubectl patch pv keycloak -p '{"spec":{"claimRef": null}}'
- some variables are not part of the git repo, secrets which one has to define additionally like wifi WEP
- gentoo_build and gentoo_binhost are usually assigned to the same host, but in case of recovery having two variables allows to disable build while configuring another available host as binhost

Manage Registry:
- remove from registry: # list_images.sh | grep keycloak | grep 19 | awk '{print $2" "$5}' | xargs delete_image.sh
- fix corruption/0-byte files: find /var/lib/registry/docker/registry/v2 -size 0 -path "*_manifests/revisions/sha256*" -exec rm -v {} \;
- delete physically: # podman exec -it registry bin/registry garbage-collect --delete-untagged /var/lib/registry/config.yml
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

replace token in all my git repos:
 find /data/mine/ -type d -name .git | while read d; do sed -i -e 's/Andi:.*@/Andi:token@/g' $d/config  | grep url; done


Deconz:
flash:
# # git clone https://github.com/dresden-elektronik/gcfflasher.git
# git checkout v4.5.2
# ./build_cmake.sh
# kubectl scale --replicas=0 -n home deploy deconz
# build/GCFFlasher -d /dev/ttyAMA0 -f /root/deCONZ_RaspBeeII_0x26780700.bin.GCF
- conbee III: stty -F /dev/ttyUSB0 115200 is crucial; startup debugging: DEBUG=zigbee-herdsman*
- Woolley BSD29/BSD59: issues: offline suddenly and autonomous power-off after few secs, got it working with config adapter_delay=350 plus "Min rep change" to 29 and then to 0 (yes, strange!)
- Zigbee is sensible: stay away from USB devices (use cable) and use a Zigbee channel far away from 2.4GHz WLAN channel you use

Mosquitto:
- remove messages flagged for retain: # mosquitto_sub -h localhost -u x -P x -v --retained-only --remove-retained -t 'zigbee2mqtt/Zimmertr/availability' -E

applicationSecurity: allows to configure locally security settings per application which are not pushed to github, e.g. runUser which is then not only used for the concerning securityContext entry of a pod, but also for the storage deployed for it

Kubernetes Dashboard:
- with update, skip-login was no longer possible, seems Authorization Header is required (https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md ), set-authorization-header can nolonger be used (https://oauth2-proxy.github.io/oauth2-proxy/configuration/alpha-config/)  => somehow set bearer token in oauth2-proxy or istio, see: https://elastisys.com/istio-and-oauth2-proxy-in-kubernetes-for-microservice-authentication/
- follow https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
- issue with publishing via HTTP => ISTIO (TLS), see https://github.com/kubernetes/dashboard/issues/9066 https://stackoverflow.com/questions/60281374/accessing-kubernetes-dashboard
=> reject with version > 7.5.0 or alternatives

Networking Istio:
- Load-balancer <=> Gateway: one to one relationship
- Gateway <=> VirtualService: one to one relationship
- VirtualService <=> Application: one to many relationship
- inject istio sidecare, mutatingwebhookconfigraion update to inject sidecar based on label "app"

TODO: 
- k8s join - replace kubectl token create by managing boostrap tokens (secrete in kube-system namespace) directly, get valid if not expired, else create new
- dependencies: generalize waitdb initcontainer 
- Longhorn I/O error: high CPU? working again after: kubectl get pod -o wide -n longhorn-system | grep k8s-3 | grep -v longhorn- | awk '{print $1}' | xargs kubectl delete pod -n longhorn-system => restart instance-manager + pgsql
- turn script into real Ansible tasks: - name: install git directly if /var/db/repos/gentoo/.git is empty to allow emerge-sync (needed for initial installation)
- mutate: kube-flannel + replace helm by kustomize
- security: log all incoming connections on gateway (traefik+istio log access to file => OpenTelemetry collector => Loki ) => see Security.md
- generate playbook doc with tags described
- image-builder: find solution to build envoy (JDK and bazel binary mandate JDK, how does alpine solve it?) 
- certificates: requests.yaml => replace reg_cert and reg_key by dynamic variables provided as input similar as build dir for templates
- longhorn: see to run less privileged, e.g. replace hostpath by something elese e.g. for the socke in /var/lib/kubelet/plugins/driver.longhorn.io/
- lifeness and readiness probes: generate from application config
- kubelet/config.yaml: is created twice, first from template, 2nd from configmap - change it!
- with podman 5.8: change k8s-1-int from boltDB to sqlite: podman system migrate --database-backend sqlite
- try to create modules for Ansible: kustom, gateway, dependencies, upgrades (e.g. postgresql), code (infopage/auth-operator)
- if can be executed only on control host: replace getting vars from shell output via register, use     task_timestamp: "{{ lookup('pipe', 'date +%Y%m%d%H%M%S') }}" instead, if it is reading files, use slurp
- var/images: split build script snippets so multiple required images can be used (e.g. traefik has go and nodejs, so run a part on go builder, another on nodejs builder)
- standard: PullPolicy Always, but this would block pod creation if registry is unavailable. Solution: set Always as standard, but run an operator to check for failures and correct the deployment, first code at roles/deploy/files/curator/curator.py
- traefik dashboard not accessible, webui is not compiled, yarn build:prod is missing in build, issue with command yarn build:prod, yarn install needs to run (maybe as very first?" to pull rollup musl
- kubelet config cleanup, file or configmap leading

- postgresql major version update: include docker build in playbook, parameterize versions and other vars set, triggered for major version upgrade
=> how to detect a major upgrade? dynamically load role from outside main ansible playbook, then perform update, then continue as usual
=> home-assistant has hardcoded version for opensp compilation issue, see var/images
=> opensp: patch https://bugs.gentoo.org/947175:
#  else
char *getcwd ();
#  endif
and surround it by: # if !defined HAVE_GETCWD


-  eclean -p --deep --time-limit 90d packages to get /var/cache/binpkg clean, but see also to clean /data/build/data/packages
- istio vs wrongly created for home-assistant (e.g. destination, prefix)
