
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

longhorn-system and kube-system seem to be implicitly exempted from PodSecurity. As this is not visible outside the cluster, only by its effects, both are explicitly exempted in the AdmissionController
- audit log Policy: first match wins, so granular exclusions have to be early in the policy
