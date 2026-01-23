#!/bin/bash

name="$1"
cd /data/mine/certs/

externalDNSname=xyz # e.g. router dynamic DNS name

openssl genrsa -out ${name}.key 2048

openssl req -new -sha256 -key ${name}.key -subj "/C=XX/ST=Some-State/O=Some-State/CN=${name}" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:${name},DNS:${externalDNSname}")) -out ${name}.csr

openssl x509 -req -in ${name}.csr -CA myCA.pem -CAkey myCA.key -CAcreateserial -out ${name}.crt -days 5000 -sha256  -extfile <(printf "subjectAltName=DNS:${name},DNS:${externalDNSname}")

openssl x509 -in ${name}.crt -text
