
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

The reason for an own script to be called as ValidatingWebhook or Mutating webhook is that Pod Security Admissison doesn't allow granular control per pod and per rule

NetworkPolicy looks interesting but requires Calicio or Cilium CNI, Falco (runtime security) looks nice

users/groups/permissions:
settings for runAsUser, runAsGroup, mode for files and directories are added to the application declarations, either defaults or randoms are set or fixed settings from local secrets file are used
This are only used if configured for the ValidatingWebhook/MutatingWebhook, if not the webhook enforces its own settings

longhorn-system and kube-system seem to be implicitly exempted from PodSecurity. As this is not visible outside the cluster, only by its effects, both are explicitly exempted in the AdmissionController
- audit log Policy: first match wins, so granular exclusions have to be early in the policy

All in all Pod Security Admission is not useful when you want to restrict individually on Pod level

## ingress logging

traefik+istio forward logs to OpenTelemetry which makes it usable in Loki
- traefik log forwarding
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: otel-log-sink
  namespace: ingress-traefik
spec:
  forwardAuth:
    address: "http://otel-collector.otel-namespace.svc.cluster.local:55681/v1/logs"
    trustForwardHeader: true
    authResponseHeaders:
      - "X-Request-Start"

- istio:
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-ingress
  namespace: istio-system
spec:
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        overlays:
        - kind: Deployment
          name: istio-ingressgateway
          patches:
          - path: spec.template.spec.containers[0].env
            value:
            - name: ISTIO_META_JSON_LOGGING
              value: |
                {
                  "accessLogService": {
                    "address": "otel-collector.otel-namespace.svc.cluster.local:4317",
                    "logName": "istio-access"
                  }
                }

- OTEL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: otel-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector-contrib:0.84.0
        command: ["/otelcontribcol"]
        args: ["--config=/conf/otel-config.yaml"]
        volumeMounts:
          - name: config
            mountPath: /conf
      volumes:
        - name: config
          configMap:
            name: otel-collector-config


- OTEL config
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: otel-namespace
data:
  otel-config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:    # Istio ALS
          http:    # Traefik ForwardAuth

    exporters:
      loki:
        endpoint: "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
        labels:
          source: otel-collector

    service:
      pipelines:
        logs:
          receivers: [otlp]
          exporters: [loki]

- Loki:
