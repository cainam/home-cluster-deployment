## Helm vs. Kustomize
I started deploying the applications on Kubernetes using helm charts but at some point I decided to add a second method via kustomize.

Although many helm charts can be highly configured I faced over and over issues that some configurations were not forseen, either not achievable via templating or hardcoded:
* For security reasons I started to enforce security rules and configured random uids for execution leveraging  helm's postRender option which allowes to change everything which was done in the templating before.
* There are many posibilities of customizations in the postgresql chart, but it didn't allow me to configure the volumeMounts the way I wanted.

This was just the final issue I faced, but I made a lot of customization, templating the templating and it got more tricky which each additional feature I implemented.

In the end helm templating with ansible templating is one templating too much!

With kustomize the configuration for the playbooks is easier straight forward, no adaptions require to fetch and modify the helm chart, no limitations on the chart and I also discovered that the maintenance is less complex.

