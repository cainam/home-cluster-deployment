#!/bin/bash

git_source=$1 # https://github.com/oauth2-proxy/manifests.git
git_subdir=$2
git_branch=$3

if [ "${git_branch}" != "" ]; then
  git_branch="--branch ${git_branch}"
fi

#dir=$(mktemp --directory)
#cd $dir
echo "$0: directory: $PWD"
#git clone   --depth 1    --filter=blob:none    --no-checkout  "${git_source}"
#git clone --depth 1 --filter=blob:none --no-checkout "${git_source}"

#git clone --depth 1 --single-branch -b v3.4.5 https://github.com/traefik/traefik.git


if [ "${git_subdir}" = "" ]; then
  git clone "${git_source}"
else
  git clone ${git_branch} --depth 1 --filter=blob:none --sparse "${git_source}"
fi
cd *
# git checkout --quiet $(git branch --show-current) --  "${git_subdir}" &> /dev/null
if [ "${git_subdir}" != "" ]; then
  git sparse-checkout set "${git_subdir}"
fi
echo "subdir checkout done"
