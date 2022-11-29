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

    # manage images
    # first try, but to keep for later usage: img_infos=$yq -y '(.. | .image? // empty)' test | sed -e 's/: /:"/g' -e 's/$/"/g' | sed -e 's/---"$/---/g' ) #| tr '\n' ' ' | sed -e 's/\s*---\s*/\n/g')
    yq -r 'path(..|.image? // empty) | [.[]|tostring]|join(".")' values.yaml | while read image_section;do
      repository=$(yq -r '.'"${image_section}"'.repository? // empty' values.yaml)
      tag=$(yq -r '.'"${image_section}"'.tag? // empty' values.yaml)
      if [ "${tag}" == "" ]; then
        echo "tag is empty (${tag}, trying appVersion"
        tag=$(yq -r '.appVersion' Chart.yaml)
      fi
      echo "treat image repository: ${repository} tag: ${tag}"
      if [ "${repository}" == "" ] || [ "${tag}" == "" ]; then
        echo "repository and tag are not allowed to be empty"
        exit -1
      fi
      if [ "${repository}" != "null" ]; then
        img_name=$(echo "${repository}" | grep -o '[^/]*$' )
        read dummy mapping < <( grep "^${img_name}\s\+" ${images_map})
        [ "${mapping}" = "" ] && mapping="cat"
        fetch_img=$(echo "${repository}:${tag}" | eval $mapping)
    
        for rem_reg in "" docker.io/; do 
	  image_entry="$platform ${rem_reg}$fetch_img /$category/"
          echo "image_entry: $image_entry from original chart image: ${repository}:${tag} - via mapping: $mapping"
          # grep -F -x -q "$image_entry" $images_list || echo "$image_entry" >> $images_list # add entry if it is missing
	  echo "$image_entry" | pull-tag-push.sh
	  [ $? -ne 9 ] && break
	done
        yq -yi '.'"${image_section}"'.repository="'"${category}/${img_name}"'"' values.yaml
        yq -yi '.'"${image_section}"'.tag="'"$(echo "${fetch_img}"|cut -d : -f 2)"'"' values.yaml
        
        #yq -yi '.image.repository |= "'${category}/${img_name}'"' values.yaml
        ## the new replace command is                                                        yq -yi '(.. | .repository? // empty) |= "lkj"' values.yaml
        #yq -yi '.image.tag |= "'$(echo "${fetch_img}"|cut -d : -f 2)'"' values.yaml
      fi
    done
    # yq -yi '.image.registry |= "'${registry}'"' values.yaml
  
    # treat dependencies
    while read name repo version; do 
      echo "resolving dependency: $name $version $repo";
      if [ ${version::1} == "~" ]; then 
        version=$(echo "${version:1}" | sed -e 's/[0-9]$//');
      fi; 
      if echo "${version}" | grep -q -e 'X' -e 'x' -e '*'; then
        version=$(echo "${version}" | sed -e "s/[Xx*].*$//g");
      fi
      echo "version updated to $version, next fetching from helm repo: $repo"
      curl -L -s $repo/index.yaml | yq -r '.entries."'$name'"[] | select(.version|startswith("'$version'" ) ) | [.version, (.urls|join(","))  ] | @tsv' | sort -n -r  | head -n 1 | while read version url; do
        dep_dir=$(mktemp --directory) 
        echo "entering $dep_dir and treating dependency with $url"
        cd $dep_dir
        curl -L -O -s $url
        tar xfz $(echo $url | xargs basename)
        pull_local || exit $?
      done
    done < <(cat Chart.yaml | yq -r -c '(.dependencies[]? | [.name, .repository, .version] |@tsv)')
  
    yq -yi '.dependencies[]?.repository |= "'$helm_url'"' Chart.yaml
    helm dependency build $PWD

    helm package -d $helm_repo_dir/ $PWD
    helm repo index "${helm_repo_dir}" --url $helm_url
    helm repo update
    cd -
    echo "done for $pack_dir"
  done

}

platform=$1 # arm64
git_source=$2 # https://github.com/oauth2-proxy/manifests.git
git_subdir=$3

dir=$(mktemp --directory)
cd $dir
echo "directory: $PWD"

git-subdir-checkout.sh "${git_source}" "${git_subdir}" 2>&1 | sed -e 's/^/git-subdir-checkout.sh: /g'
cd */$git_subdir
pull_local || exit $?
