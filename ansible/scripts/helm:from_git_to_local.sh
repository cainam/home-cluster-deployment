#!/bin/bash

function pull_local(){
  echo; echo "pull_local in $PWD"
  find . -name Chart.yaml | xargs dirname | while read pack_dir; do
    cd $pack_dir
    echo "directory: $PWD category: $category"
    # re-set env with current dir
    . set_env.sh $category

    ls -l Chart.yaml values.yaml
    [ -f Chart.lock ] && rm Chart.lock

#        set -x
    if [ "${#fix_source[@]}" -ne 0 ];then
      echo "applying fix on source values.yaml"
      for key in "${!fix_source[@]}"; do
        yq -yi  "${key}="'"'"${fix_source[$key]}"'"' values.yaml
      done
    fi

    input=values.yaml
    # manage images
    yq -r 'path(..|(.repository,.image)? // empty) | [.[]|tostring]|join(".")' "${input}"  | while read match; do
      echo
      section_type=$(yq -r '.'"${match}"' | type' "${input}" )
      echo "match: ${match} section_type: ${section_type}"
      if [ "${section_type}" == "string" ]; then #use parent
        match=$(yq -r 'path(.'"${match}"') | .[:-1] |join(".")' "${input}")
        section_type=$(yq -r '.'"${match}"' | type' "${input}" )
      fi
      echo "match: ${match} section_type: ${section_type}"
      # mandatory: unique image
      image=
      image_attr=
      unset image_registry # used as criteria to set image_registry
      for att in image repository repo registry; do
        result=$(yq -r '.'"${match}"'.'"${att}"' // empty' "${input}")
        echo "match: ${match}, lookup for ${att}, result:${result}"
        if [ "${result}" != "" ]; then # something found
          if [ "${att}" = "registry" ]; then 
	    image_registry="${result}"
	    continue
	  fi
          [ "${image}" != "" ] && echo "found another attribute, conflict, panic, exit!!!!" && exit -1
          image="${result}"
          image_attr='.'"${match}"'.'"${att}"
        fi
      done
      [ "${image}" = "" ] && echo "no image, nothing to do" && continue
      #image_path=$(echo "${image}" | grep -q / && echo "${image%/*}")
      image_path= && [[ ${image} == */* ]] && image_path="${image%/*}"
      echo "match: ${match} section_type: ${section_type} image: ${image} image_attr: ${image_attr} image_path: ${image_path}"
      # tag: check attribute, check image => if both contain tag, error, if one contains: keep, if none contains: error
      tag_attr=$(yq -r '.'"${match}"'.tag // empty' "${input}")
      tagBy=attr
      tag_image=
      [[ ${image} == *:* ]] && tag_image=${image#*:} && tagBy=image
      [ "${tag_image}" == "" -a "${tag_attr}" == "" ] && echo "no tag provided, so ${match} will be ignored" && continue
      [ "${tag_image}" != "" -a "${tag_attr}" != "" ] && echo "image includes tag and additional tag attribute given, panic, exit!!!" && exit -1
      tag="${tag_attr%%@*}${tag_image%%@*}"
      fetch_img="${image}"
      [ "${tagBy}" == "attr" ] && fetch_img="${fetch_img}:${tag}"
      #real_image_only="$(echo "${image}" | xargs basename)"
      real_image_only="${image}" && [[ ${image} == */* ]] && real_image_only="${image##*/}" # real_image_only, without path

      echo "match: ${match} section_type: ${section_type} image: ${image} image_attr: ${image_attr} image_path: ${image_path} tagBy:${tagBy} tag:${tag} real_image_only: ${real_image_only}"
      for rem_reg in "" docker.io/ quay.io/ registry.k8s.io/; do # try different registries directly as /etc/containerd/registries.conf should have deactivated them
        image_entry=$(echo "$platform ${rem_reg}$fetch_img /$category/" | sed -e 's#/\+#/#' -e 's#^/\+##' )
        (echo "$image_entry" | pull-tag-push.sh ) || true
      done
      echo "update image informations in chart"
      yq -yi "${image_attr}=\"${category}/${real_image_only}\"" "${input}"
      [ "${tagBy}" == "attr" ] && yq -yi '.'"${match}"'.tag="'"${tag}"'"' "${input}"
      [[ ! -v ${image_registry} ]] && echo "replacing by default at ${match}.registry=${registry}" && yq -yi '.'"${match}"'.registry="'${registry}'"' "${input}" # replaces the following to ensure the value is empty instead of deleted: yq -yi 'del(.'"${match}"'.registry)' values.yaml
      echo "next image, please!"
    done 
   # done <<< $(yq -r 'path(..|(.repository,.tag,.image)? // empty) | [.[]|tostring]|join(".")' values.yaml)
#    set +x
  
    # treat dependencies
    while read name repo version; do 
      if echo "$remove_deps" | grep -q "^$name"; then
        echo "dependency $name will be removed from Chart.yaml and skipped from processing"
	yq -yi 'del(.dependencies[]? | select (.name=="'"${name}"'"))' Chart.yaml
        continue
      fi
    done < <(cat Chart.yaml | yq -r -c '(.dependencies[]? | [.name, .repository, .version] |@tsv)')
  
    yq -yi '.dependencies[]?.repository |= "'$helm_url'"' Chart.yaml
    #[ "${appVersion}" != "" ] && echo "updating appVersion" && yq -yi  '.appVersion="'"${appVersion}"'"' Chart.yaml
    #[ "${chart_version}" != "" ] && echo "updating chart_version" && yq -yi  '.version="'"${chart_version}"'"' Chart.yaml
    set -x
    helm dependency build $PWD

    helm package -d $helm_repo_dir/ $PWD
    helm repo index "${helm_repo_dir}" --url $helm_url
    helm repo update
    set +x
    cd -
    echo "done for $pack_dir"
  done

}

set -e

platform=""
git_source=""
git_subdir=""
appVersion=""
chart_version=""
declare -A fix_source

for i in "$@"; do
  case $i in
    -p=*|--platform=*)
      platform="${i#*=}"
      shift
      ;;
    -g=*|--git_source=*)
      git_source="${i#*=}"
      shift
      ;;
    -s=*|--git_subdir=*)
      git_subdir="${i#*=}"
      shift
      ;;
    --git_branch=*)
      git_branch="${i#*=}"
      shift
      ;;
    --remove_dependencies=*)
      remove_deps="${i#*=}"
      shift
      ;;
    --appVersion=*)
      appVersion="${i#*=}"
      shift
      ;;
    --fix_source=*)
      item="${i#*=}"
      key="${item%=*}"
      val="${item#*=}"
      echo "adding fix_source, key:${key} val:${val}"
      fix_source[$key]="${val}"
      shift
      ;;
    --chart_version=*)
      chart_version="${i#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

#platform=$1 # arm64
#git_source=$2 # https://github.com/oauth2-proxy/manifests.git
#git_subdir=$3

echo "platform: $platform"
echo "git_source: $git_source git_subdir: $git_subdir git_branch: $git_branch"
echo "remove_deps: $remove_deps"
echo "appVersion: $appVersion"
echo "chart_version: $chart_version"

dir=$(mktemp --directory)
cd $dir
echo "directory: $PWD"

remove_deps=$(echo "$remove_deps" | sed -e 's/,/\n/g')

git-subdir-checkout.sh "${git_source}" "${git_subdir}" "${git_branch}" 2>&1 | sed -e 's/^/git-subdir-checkout.sh: /g'
cd */$git_subdir
pull_local #|| exit $?
x=$?
echo "code:$x"
exit $x
