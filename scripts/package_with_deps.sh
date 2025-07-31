#!/bin/bash

[ -z ${env_is_set+x} ] && echo "env is not set ..." && exit -1


helm dependency list $PWD | grep -v -e "^\s*$" -e ^NAME | while read name version url rest; do echo "name: $name url: $url"; helm repo add $name $url; done # online repo hinzufügen
helm dependency build $PWD # Abhängigkeiten herunterladen
helm dependency list $PWD | grep -v -e "^\s*$" -e ^NAME | while read name version url rest; do echo "name: $name url: $url"; helm repo remove $name; done # repo wieder entfernen
helm package -d $helm_repo_dir/ $PWD
helm repo index "${helm_repo_dir}" --url $helm_url

