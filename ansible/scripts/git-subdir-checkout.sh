#!/bin/bash

git_source=$1 # https://github.com/oauth2-proxy/manifests.git
git_subdir=$2

#dir=$(mktemp --directory)
#cd $dir
echo "$0: directory: $PWD"
#git clone   --depth 1    --filter=blob:none    --no-checkout  "${git_source}"
#git clone --depth 1 --filter=blob:none --no-checkout "${git_source}"
git clone --depth 1 --filter=blob:none --sparse "${git_source}"
cd *
# git checkout --quiet $(git branch --show-current) --  "${git_subdir}" &> /dev/null
git sparse-checkout set "${git_subdir}"
echo "subdir checkout done"
