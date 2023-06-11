#!/bin/bash

input="$1"
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
      for att in image repository repo; do
        result=$(yq -r '.'"${match}"'.'"${att}"' // empty' "${input}")
	echo "match: ${match}, lookup for ${att}, result:${result}"
        if [ "${result}" != "" ]; then # something found
	  [ "${image}" != "" ] && echo "found another attribute, conflict, panic, exit!!!!" && exit -1
	  image="${result}"
	  image_attr='.'"${match}"'.'"${att}"
	fi
      done
      image_path=$(echo "${image}" | grep -q / && echo "${image%/*}")
      echo "match: ${match} section_type: ${section_type} image: ${image} image_attr: ${image_attr} image_path: ${image_path}"
      # tag: check attribute, check image => if both contain tag, error, if one contains: keep, if none contains: error
      tag_attr=$(yq -r '.'"${match}"'.tag // empty' "${input}")
      tagBy=attr
      tag_image=
      [[ ${image} == *:* ]] && tag_image=${image#*:} && tagBy=image
      [ "${tag_image}" == "" -a "${tag_attr}" == "" ] && echo "no tag provided, panic! exit!" && exit -1
      fetch_img="${image}"
      [ "${tagBy}" == "attr" ] && fetch_img="${fetch_img}:${tag}"
      real_image_only="$(echo "${fetch_img}"  | cut -d : -f 1 | xargs basename)"

      echo "match: ${match} section_type: ${section_type} image: ${image} image_attr: ${image_attr} image_path: ${image_path} tagBy:${tagBy} tag:${tag} real_image_only: ${real_image_only}"



    done


exit

    yq -r 'path(..|.image? // empty) | [.[]|tostring]|join(".")' "${input}"  | while read image_section_org;do
          echo
      image_section=$(echo "${image_section_org}" | sed -e 's/^/"/' -e 's/$/"/' -e 's/\./"\."/g')
      section_type=$(yq -r '.'"${image_section}"' | type' "${input}" )
      # namings pulling an image: <path>/<image>:<tag>
      if [ "${section_type}" == "string" ]; then # if image is only a string use the value as repository
        parent=$(yq -r 'path(.'"${image_section}"') | .[:-1] |join(".")' "${input}")
        parent_tag=$(yq -r '.'"${parent}"'.tag? // empty ' "${input}" )

        image=$(yq -r '.'"${image_section}" "${input}" )
        image_path=$(echo "${image}" | grep -q / && echo "${image%/*}")
        image_itself=${image##*/}
        ## [[ ${image_itself} == *:* && ${parent_tag} == "" ]] || image_itself="${image_itself}:${parent_tag}"

        repo=$(yq -r '.'"${parent}"'.repository? // empty ' "${input}" )
        [ -z "${repo}" ] && repo=$(yq -r '.'"${parent}"'.hub? // empty ' "${input}" ) # prefer parent.repository over parent.hub
      else
        parent_tag=$(yq -r '.'"${image_section}"'.tag? // empty' "${input}")

        image=$(yq -r '.'"${image_section}"'.repository? // empty' "${input}")
        [[ ${image} == "" ]] && image=$(yq -r '.'"${image_section}"'.repo? // empty' "${input}")
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

done
