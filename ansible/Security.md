
cluster and namespace-wide: 
https://kubernetes.io/docs/concepts/security/pod-security-admission/
https://kubernetes.io/docs/concepts/security/pod-security-standards/
https://dev.to/thenjdevopsguy/implementing-kubernetes-pod-security-standards-4aco

Implementation:
1. AdmissionConfirmation with cluster-wide config is deployed


Pod and Container Security:
PodTemplateSpec v1 core
Appears In:
    DaemonSetSpec [apps/v1]
    DeploymentSpec [apps/v1]
    JobSpec [batch/v1]
    PodTemplate [core/v1]
    ReplicaSetSpec [apps/v1]
    ReplicationControllerSpec [core/v1]
    StatefulSetSpec [apps/v1]

PodSecurityContext supports:
  appArmorProfile
  fsGroup
  fsGroupChangePolicy
  runAsGroup
  runAsNonRoot
  runAsUser
  seLinuxChangePolicy
  seLinuxOptions
  seccompProfile
  supplementalGroups
  supplementalGroupsPolicy
  sysctls
  windowsOptions

SecurityContext (container) supports overrides PodSecurityContext if specified:
  allowPrivilegeEscalation
  appArmorProfile
  capabilities
  privileged
  procMount
  readOnlyRootFilesystem
  runAsGroup
  runAsNonRoot
  runAsUser
  seLinuxOptions
  seccompProfile
  windowsOptions

Enable audit log:
cat /etc/kubernetes/manifests/kube-apiserver.yaml  | yq -y '
.spec.volumes = ((.spec.volumes // []) | map(select(.name != "audit" and .name != "audit-log"))+
  [{name: "audit","hostPath": {type: "File",path: "/etc/kubernetes/audit-policy.yaml"}},{name: "audit-log","hostPath": {type: "FileOrCreate",path: "/var/log/kubernetes/audit/audit.log"}}])

| .spec.containers[] |= (
 if .name == "kube-apiserver" then
   .command = ( (.command // [])
     + (if (.command // []) | index("--audit-log-path=/var/log/kubernetes/audit/audit.log")  | not then ["--audit-log-path=/var/log/kubernetes/audit/audit.log"]  else [] end)
     + (if (.command // []) | index("--audit-policy-file=/etc/kubernetes/audit-policy.yaml") | not then ["--audit-policy-file=/etc/kubernetes/audit-policy.yaml"] else [] end)) |
   .volumeMounts = ( (.volumeMounts // [])
     + (if (.volumeMounts // []) | map(.name) | index("audit") | not then [{name: "audit",mountPath: "/etc/kubernetes/audit-policy.yaml", readOnly: true}] else [] end )
     + (if (.volumeMounts // []) | map(.name) | index("audit-log") | not then [{name: "audit-log",mountPath: "/var/log/kubernetes/audit/audit.log", readOnly: true}] else [] end ))
 else . end )' > b
