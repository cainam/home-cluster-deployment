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

    if [ "${#fix_source[@]}" -ne 0 ];then
      echo "applying fix on source values.yaml"
      for key in "${!fix_source[@]}"; do
        set -x
        yq -yi  "${key}="'"'"${fix_source[$key]}"'"' values.yaml
	set +x
      done
    fi

    # manage images
    # first try, but to keep for later usage: img_infos=$yq -y '(.. | .image? // empty)' test | sed -e 's/: /:"/g' -e 's/$/"/g' | sed -e 's/---"$/---/g' ) #| tr '\n' ' ' | sed -e 's/\s*---\s*/\n/g')
    yq -r 'path(..|.image? // empty) | [.[]|tostring]|join(".")' values.yaml | while read image_section_org;do
      echo
      image_section=$(echo "${image_section_org}" | sed -e 's/^/"/' -e 's/$/"/' -e 's/\./"\."/g')
      section_type=$(yq -r '.'"${image_section}"' | type' values.yaml )
      # namings pulling an image: <path>/<image>:<tag>
      if [ "${section_type}" == "string" ]; then # if image is only a string use the value as repository
        parent=$(yq -r 'path(.'"${image_section}"') | .[:-1] |join(".")' values.yaml) 
	parent_tag=$(yq -r '.'"${parent}"'.tag? // empty ' values.yaml )

	image=$(yq -r '.'"${image_section}" values.yaml )
	image_path=$(echo "${image}" | grep -q / && echo "${image%/*}")
        image_itself=${image##*/}
	## [[ ${image_itself} == *:* && ${parent_tag} == "" ]] || image_itself="${image_itself}:${parent_tag}"

	repo=$(yq -r '.'"${parent}"'.repository? // empty ' values.yaml )
	[ -z "${repo}" ] && repo=$(yq -r '.'"${parent}"'.hub? // empty ' values.yaml ) # prefer parent.repository over parent.hub
      else
        parent_tag=$(yq -r '.'"${image_section}"'.tag? // empty' values.yaml)

        image=$(yq -r '.'"${image_section}"'.repository? // empty' values.yaml)
	[[ ${image} == "" ]] && image=$(yq -r '.'"${image_section}"'.repo? // empty' values.yaml)
	image_path=$(echo "${image}" | grep -q / && echo "${image%/*}")
        image_itself=${image##*/}
	## [[ ${image_itself} == *:* && ${parent_tag} == "" ]] || image_itself="${image_itself}:${parent_tag}"

	repo=
      fi
      [[ ${image_itself} == "" ]] && continue
      fetch_img="${repo}/${image_path}/${image_itself}"
      [[ ${fetch_img} != *:* && ${parent_tag} != "" ]] && fetch_img="${fetch_img}:${parent_tag}" 
      [[ ${fetch_img} == *:* ]] && tag="${fetch_img#*:}"
      fetch_img=$(echo "$fetch_img" | sed -e 's#/\+#/#' -e 's#^/\+##')
      echo "treat image repository: ${repo} image: ${image_itself} fetch_img: ${fetch_img} image_section=${image_section} section_type=${section_type} (from org:${image_section_org})"
      #if [ "${repository}" != "null" ]; then
        for rem_reg in "" docker.io/ quay.io/; do # try different registries directly as /etc/containerd/registries.conf should have deactivated them
	  image_entry=$(echo "$platform ${rem_reg}$fetch_img /$category/" | sed -e 's#/\+#/#' -e 's#^/\+##' )
          echo "image_entry: $image_entry from original chart image: ${fetch_img}"
	  echo "$image_entry" | pull-tag-push.sh
	  [ $? -ne 9 ] && break
	done
	if [ "${section_type}" == "string" ]; then # only if image is a single string
	  echo "replacing ${image_section}.image by ${category}/${image_itself}"
          yq -yi '.'"${image_section}"'="'"${category}/${image_itself}"'"' values.yaml
	else
          yq -yi '.'"${image_section}"'.repository="'"${category}/${image_itself%:*}"'"' values.yaml
          yq -yi '.'"${image_section}"'.repo="'"${category}/${image_itself%:*}"'"' values.yaml
          yq -yi '.'"${image_section}"'.tag="'"${tag}"'"' values.yaml
	  yq -yi 'del(.'"${image_section}"'.registry)' values.yaml
	fi
      #fi
    done
  
    # treat dependencies
    while read name repo version; do 
      if echo "$remove_deps" | grep -q "^$name"; then
        echo "dependency $name will be removed from Chart.yaml and skipped from processing"
	yq -yi 'del(.dependencies[]? | select (.name=="'"${name}"'"))' Chart.yaml
        continue
      fi
#      echo "resolving dependency: $name $version $repo";
#      if [ ${version::1} == "~" ]; then 
#        version=$(echo "${version:1}" | sed -e 's/[0-9]$//');
#      fi; 
#      if echo "${version}" | grep -q -e 'X' -e 'x' -e '*'; then
#        version=$(echo "${version}" | sed -e "s/[Xx*].*$//g");
#      fi
#      echo "version updated to $version, next fetching from helm repo: $repo"
#      curl -L -s $repo/index.yaml | yq -r '.entries."'$name'"[] | select(.version|startswith("'$version'" ) ) | [.version, (.urls|join(","))  ] | @tsv' | sort -n -r  | head -n 1 | while read version url; do
#        dep_dir=$(mktemp --directory) 
#        echo "entering $dep_dir and treating dependency with $url"
#        cd $dep_dir
#        curl -L -O -s $url
#        tar xfz $(echo $url | xargs basename)
#        pull_local || exit $?
#      done
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
pull_local || exit $?
