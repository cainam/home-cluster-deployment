## TODO:
check to apply the etcd tuning options:
          snapshot-count: 5000
          heartbeat-interval: 400
          election-timeout: 3000
          experimental-warning-apply-duration: 300ms

# kubelet
kubelet configuration is deployed as a file and the kubelet configmap is refreshed from this file

## networking information
```
# kubectl describe cm kubeadm-config -n kube-system |grep Subnet
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12

# kubectl describe nodes | grep -e ^Name: -e InternalIP: -e PodCIDR:
Name:               k8s-1-int
  InternalIP:  10.10.10.21
PodCIDR:                      10.244.0.0/24
Name:               k8s-2-int
  InternalIP:  10.10.10.22
PodCIDR:                      10.244.1.0/24

# kubectl get cm -n kube-flannel kube-flannel-cfg -o yaml | grep -m 1 Network
      "Network": "10.244.0.0/16",

k8s-1-int ~ # ip addr show dev flannel.1 | grep inet
    inet 10.244.0.0/32 scope global flannel.1

k8s-2-int ~ # ip addr show dev flannel.1 | grep inet
    inet 10.244.1.0/32 scope global flannel.1

k8s-1-int ~ # ip addr show dev cni0 | grep inet
    inet 10.244.0.1/24 brd 10.244.0.255 scope global cni0

k8s-2-int ~ # ip addr show dev cni0 | grep inet
    inet 10.244.1.1/24 brd 10.244.1.255 scope global cni0
```

## example for patching
    # kubectl -n kube-system patch ds kube-flannel-ds -p '{"spec": {"template": {"spec": {"containers": [{"name": "kube-flannel","args": ["--ip-masq","--kube-subnet-mgr","--flannel-backend=host-gw"]}]}}}}'

