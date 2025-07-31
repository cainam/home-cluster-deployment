#!/bin/bash

while 
read space name prefix gw_port pod_port; do
[ "$space" == "" ] && echo "pipe per line: space name prefix gw_port pod_port" && exit 0

echo "processing input: space=${space} name=${name}"

cat <<EOF
space=${space} name=${name}
EOF

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
  name: ${name}
  namespace: ${space}         
spec:
  selector:
    istio: ingress
  servers:
  - hosts:
    - '*'
    port:
      name: https
      number: ${gw_port}
      protocol: HTTPS
    tls:
      credentialName: istio-ingress
      mode: SIMPLE

EOF
kubectl apply -f - <<EOF                     
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ${name}
  namespace: ${space}
spec:
  gateways:
  - ${name}
  hosts:
  - '*'
  http:
  - match:
    - uri:
        prefix: ${prefix}
    route:
    - destination:
        host: ${name}
        port:
          number: ${pod_port}
EOF

done
