#!/bin/bash

input="$1"

    yq -r 'path(..|.image? // empty) | [.[]|tostring]|join(".")' "${input}"  | while read image_section_org;do
      echo
      image_section=$(echo "${image_section_org}" | sed -e 's/^/"/' -e 's/$/"/' -e 's/\./"\."/g')
      section_type=$(yq -r '.'"${image_section}"' | type' "${input}"  )
      set -x
      # namings pulling an image: <path>/<image>:<tag>
      if [ "${section_type}" == "string" ]; then # if image is only a string use the value as repository
        parent=$(yq -r 'path(.'"${image_section}"') | .[:-1] |join(".")' "${input}" )
        parent_tag=$(yq -r '.'"${parent}"'.tag? // empty ' "${input}"  )

        image=$(yq -r '.'"${image_section}" "${input}"  )
        image_path=$(echo "${image}" | grep -q : && echo "${image%/*}")
        image_itself=${image##*/}
        [[ ${image_itself} == *:* && ${parent_tag} == "" ]] || image_itself="${image_itself}:${parent_tag}"

        repo=$(yq -r '.'"${parent}"'.repository? // empty ' "${input}"  )
        [ -z "${repo}" ] && repo=$(yq -r '.'"${parent}"'.hub? // empty ' "${input}"  ) # prefer parent.repository over parent.hub
      else
        parent_tag=$(yq -r '.'"${image_section}"'.tag? // empty' "${input}" )

        image=$(yq -r '.'"${image_section}"'.repository? // empty' "${input}" )
        image_path=$(echo "${image}" | grep -q : && echo "${image%/*}")
        image_itself=${image##*/}
        [[ ${image_itself} == *:* && ${parent_tag} == "" ]] || image_itself="${image_itself}:${parent_tag}"

        repo=
      fi
      if [[ ${image_itself} != *:* ]]; then
        # echo "tag is empty (${tag}), trying appVersion"
        # tag=$(yq -r '.appVersion' Chart.yaml)
        echo "tag is empty, trying latest"
        #tag="latest" #$(yq -r '.appVersion' Chart.yaml)
        image_itself="${image_itself}:latest"
      fi
      fetch_img="${repo}/${image_path}/${image_itself}"
      tag="${image_itself#*:}"
      echo "treat image repository: ${repo} image: ${image_itself} fetch_img=${fetch_img} image_section=${image_section} section_type=${section_type} (from org:${image_section_org})"
    done
