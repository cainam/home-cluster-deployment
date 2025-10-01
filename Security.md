
cluster and namespace-wide: 
https://kubernetes.io/docs/concepts/security/pod-security-admission/
https://kubernetes.io/docs/concepts/security/pod-security-standards/
https://dev.to/thenjdevopsguy/implementing-kubernetes-pod-security-standards-4aco

Kyvero: hm, nice, but too heavy, better to code directly for the need

query audit violations of PSA from audit.log: cat /var/log/kubernetes/audit.log | jq 'select(.annotations."pod-security.kubernetes.io/audit-violations" != null)'

ports:
- random ports for the service are used if not defined and deployments use random ports, too. This ensures new ports with each deployment 


Order of admission validation and webhooks:
1. mutate webhook
2. PSA
3. validation webhook

Implementation:
1. AdmissionConfirmation with cluster-wide config is deployed
2. own ValidationWebhook is configured to handle exemptions from Pod Security Admission reimplementing the rules

NetworkPolicy looks interesting but requires Calicio or Cilium CNI, Falco (runtime security) looks nice

users/groups/permissions:
settings for runAsUser, runAsGroup, mode for files and directories are added to the application declarations, either defaults or randoms are set or fixed settings from local secrets file are used
This are only used if configured for the ValidatingWebhook/MutatingWebhook, if not the webhook enforces its own settings

longhorn-system and kube-system seem to be implicitly exempted from PodSecurity. As this is not visible outside the cluster, only by its effects, both are explicitly exempted in the AdmissionController
- audit log Policy: first match wins, so granular exclusions have to be early in the policy

All in all Pod Security Admission is not useful when you want to restrict individually on Pod level

