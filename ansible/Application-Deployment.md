## Kubernetes
I started deploying the applications on Kubernetes using helm charts but at some point I decided to add a second method via kustomize.
This I did when even there were so many posibilities of customization in the postgresql chart, it didn't allow me to configure the volumeMounts the way I wanted. This was just the final issue I fasted, I thought about this step earlier already when I started to configure random uids for execution and had to go via postRender which in the end allows to change everything which was done in the templating before.
With kustomize he configuration for the playbooks is easier, no adaptions require to fetch and modify the helm chart, no limitations on the chart
In the end helm templating with ansible templating is one templating too much!

Notes:
- runAsUser is configured explicitely or - if missing - a random (which each new deployment action) uid is assigned to the running containers and to files deployed (if any)

