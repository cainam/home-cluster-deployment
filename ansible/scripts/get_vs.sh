#!/bin/bash

export SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
export NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
export TOKEN=$(cat ${SERVICEACCOUNT}/token)
export CACERT=${SERVICEACCOUNT}/ca.crt
export APISERVER=https://kubernetes.default.svc

data=$(curl -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/apis/networking.istio.io/v1alpha3/namespaces/istio-ingress/virtualservices/main )

echo "$data" | jq -Mr '.spec.http[] | [.name,.match[].uri.prefix] | @tsv'
#curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api
