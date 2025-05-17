#!/bin/sh


work_dir=$(mktemp -d /tmp/post-renderer-XXXXXX)

set -x
cd "${work_dir}"

exec 2> ./error.log
cat - > helm-generated-output.yaml

# install kubectl: sc=$(kubectl get deploy -n tools infopage -o yaml | yq .spec.template.spec.containers[].securityContext)

SC='echo "{securityContext: {runAsUser: $(($RANDOM+99999))}}"'

SC_entries=$(cat helm-generated-output.yaml | yq -y '(.spec.template.spec.containers[]?.securityContext | length )' | grep -v "^\.\.\.$")

#phase 1: only handle completely empty securityContexts
#phase 2: TODO: handle item by item when securityContext is not empty

if [ ${SC_entries} -eq 0 ]; then
  cat helm-generated-output.yaml  | yq -y '(.spec.template.spec.containers[]? | select(.name)) |= (.  + '"$(eval $SC)"')' > rendered.yaml
else
  cat helm-generated-output.yaml > rendered.yaml
fi

cat rendered.yaml
