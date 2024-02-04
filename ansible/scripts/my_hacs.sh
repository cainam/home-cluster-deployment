#!/bin/bash

version=$1
path=$2

file=hacs.zip

[ ! -d "${path}/custom_components" ] && echo err1 && exit
hacs_path="${path}/custom_components/hacs"

rm -rf "${hacs_path}" && mkdir "${hacs_path}" 

curl -L "https://github.com/hacs/integration/releases/${version}/download/${file}" --output ./${file}-${version}

unzip ./${file}-${version} -d "${hacs_path}"

