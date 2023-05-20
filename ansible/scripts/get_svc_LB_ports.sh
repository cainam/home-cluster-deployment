#!/bin/bash

export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
export NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
export TOKEN=$(cat ${SERVICEACCOUNT}/token)
export CACERT=${SERVICEACCOUNT}/ca.crt
export APISERVER=https://kubernetes.default.svc

#curl -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/istio-ingress/services/istio-ingress 
data=$(curl -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/istio-ingress/services/gateway)

echo "$data" | jq -Mr '.spec.externalIPs[]'
echo "$data" | jq -Mr '.spec.ports[] | [.name, .port, .targetPort] | @csv' 
#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api
