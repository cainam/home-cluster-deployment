## node services
Most services running on the nodes outside Kubernetes are bound to the lan interface (end0), not to all interfaces. This makes them unaccessible in the WLAN.
Only ssh is available on the WLAN.

Pod Security admission enabled but not fine-grained enough 
cluster and namespace-wide: 
https://kubernetes.io/docs/concepts/security/pod-security-admission/
https://kubernetes.io/docs/concepts/security/pod-security-standards/
https://dev.to/thenjdevopsguy/implementing-kubernetes-pod-security-standards-4aco

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

The reason for an own script to be called as ValidatingWebhook or Mutating webhook is that Pod Security Admissison doesn't allow granular control per pod and per rule

NetworkPolicy looks interesting but requires Calicio or Cilium CNI, Falco (runtime security) looks nice

users/groups/permissions:
settings for runAsUser, runAsGroup, mode for files and directories are added to the application declarations, either defaults or randoms are set or fixed settings from local secrets file are used
This are only used if configured for the ValidatingWebhook/MutatingWebhook, if not the webhook enforces its own settings

longhorn-system and kube-system seem to be implicitly exempted from PodSecurity. As this is not visible outside the cluster, only by its effects, both are explicitly exempted in the AdmissionController
- audit log Policy: first match wins, so granular exclusions have to be early in the policy

All in all Pod Security Admission is not useful when you want to restrict individually on Pod level

## connection logging
While iniitially I was looking to get log monitoring on the ingress, I discovered that log capturing on the Fritz Box router is what I need to
- check who tries to connect
- check with whom my systems try to connect

## Gentoo binhost package signing
package signing on Gentoo consists out of the signing performed as root and the signature verification performed as nobody.
This means that the information for verification has to be stored at a place managed by the nobody user.

install -d -m0700 -o root -g root /etc/portage/gpg
gpg --homedir /etc/portage/gpg --batch --passphrase '' --quick-gen-key "Cainam Gentoo Binhost Signer <root@gentoo-binhost>" rsa4096 default 2y
k=$(gpg --homedir /etc/portage/gpg --with-colons --fingerprint | grep ^fpr | cut -d : -f 10)

install -d -m0700 -o nobody -g nobody   /var/lib/portage/binpkg-verify
gpg --homedir /etc/portage/gpg --export "$k" | su -s /bin/sh nobody -c 'GNUPGHOME=/var/lib/portage/binpkg-verify  gpg --import'
printf '%s:6:\n' "$k" | su -s /bin/sh nobody -c 'GNUPGHOME=/var/lib/portage/binpkg-verify gpg --import-ownertrust'
su -s /bin/sh nobody -c 'GNUPGHOME=/var/lib/portage/binpkg-verify gpg --check-trustdb'

