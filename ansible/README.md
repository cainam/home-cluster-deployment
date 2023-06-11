# notes on this ansible playbook

Usage example: 
    `# ansible-playbook  -i $PWD/inventory $PWD/site.yml --skip-tags k8s_images`

Notes:
- trying to run on one host only using run_once/delegate_to did only work having a hostname set as fact not with a variable. It seems like vars are re-evaluated when accessed, but facts remain constant
- uninstall of kubernetes is triggered using "--tags=all,force_reinstall", otherwise force_reinstall is skipped
- calling Ansible example: ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory site.yml --tags=deploy,build --extra-vars 'limit_namespace="istio-ingress"
- Ansible example, deploy Gentoo with build: ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook -i inventory site.yml --tags=gentoo,emerge
- remove claimRef: kubectl patch pv keycloak -p '{"spec":{"claimRef": null}}'
- create token: kubectl create token -n tools kiali-service-account

Manage Registry:
- remove from registry: # list_images.sh | grep keycloak | grep 19 | awk '{print $2" "$5}' | xargs delete_image.sh
- fix corruption/0-byte files: find /var/lib/registry/docker/registry/v2 -size 0 -path "*_manifests/revisions/sha256*" -exec rm -v {} \;
- delete physically: # podman exec -it registry bin/registry garbage-collect /etc/docker/registry/config.yml
- additionally sometimes structures have to be removed in /var/lib/registry/docker/registry/v2/repositories when no image version is shown


Istio with prefix:
- loadbalancer: 443=>main gw(tls)=>VirtualService with prefixes

etcd:
# alias etcdctl="etcdctl --write-out=table --endpoints=k8s-1-int.adm13:2379,k8s-2-int.adm13:2379  --insecure-skip-tls-verify=true --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
# etcdctl endpoint status
# etcdctl endpoint health

kiali:
prometheus web.external_url got configured, kiali failed to connect to prometheus using no prefix, solved by:
  external_services:
    prometheus:
      auth:
        insecure_skip_verify: true
      url: http://prometheus-server.tools/prometheus/


home-assistant:
  - not possible to change webroot, so subdomain used instead

TODO: 
- helm\:from_git_to_local.sh: chart_version inheritance applies to dependencies too, manage with parameters to pull_local
- add simple echo server via helm: https://github.com/mendhak/docker-http-https-echo
- VPN wireguard (Fritzbox + Android)
- Kiali shows: "istio-ingressgateway not found", but 
data:
  mesh: |-
    ingressService: gateway 
  didn't work as expected but stopped istio flows completely
