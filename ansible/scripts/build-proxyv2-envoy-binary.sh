#!/bin/bash

. set_env.sh

build_directory="/data/build-envoy"
original_image="istio-system/proxyv2:1.25.1"	
new_image_suffix="gentoo"

[ ! -d "${build_directory}" ] && mkdir "${build_directory}"
cd "${build_directory}"

echo "FROM docker.io/debian:bookworm

RUN apt update
RUN apt install -y git bash  clang lld gcc g++ curl  libc++-14-dev libc++abi-14-dev make
RUN curl -sL https://github.com/bazelbuild/bazel/releases/download/8.1.1/bazel-8.1.1-linux-arm64 --output /usr/local/bin/bazel
RUN chmod a+x /usr/local/bin/bazel
" > Dockerfile

podman build -f Dockerfile -t debian:bazel

rm Dockerfile

git clone https://github.com/istio/proxy.git
cd proxy
git checkout release-1.25

echo "build --define tcmalloc=gperftools # in .bazelrc" >> .bazelrc

build_cache="${build_directory}/cache"
[ ! -d "${build_cache}" ] && mkdir "${build_cache}"

podman run -it --rm -e CC=/usr/bin/clang -e CXX=/usr/bin/clang++ -v "${build_cache}":/root/.cache -v $PWD:$PWD --workdir $PWD debian:bazel bash -c "bazel build --verbose_failures --strip=always --config=sizeopt --noenable_bzlmod -- //:envoy && find bazel-out/ -type f -name envoy -exec cp -dp {} . \;"

strip ./envoy # change this in the build command to exclude during build already, check after next full rebuild

echo "FROM ${original_image}

ADD envoy /usr/local/bin/envoy
" > Dockerfile

podman build -f Dockerfile -t "${registry}/${original_image}-${new_image_suffix}"

podman push "${registry}/${original_image}-${new_image_suffix}"
