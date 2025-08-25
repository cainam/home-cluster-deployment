Features:
- endpoint LoadBalancer
- domain with several subdomains
- oauth2-proxy authentication
- rewrite to support different domain names and to map external dynamic DNS domain to internal domain

Both, Istio and Traefik support these features



How to ...
- istio virtualservice rewrite using regex:
  - match:
    - uri:
        prefix: /z2m/
    name: zigbee2mqtt
    rewrite:
      uriRegexRewrite:
        match: /z2m(/|$)(.*)
        rewrite: /\2

- for debugging a simple http response can be added like:
      http:
      - name: dummy
        directResponse:
          status: 598
        match:
        - uri:
            prefix: /dummy



- AuthenticationPolicy:
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istio-system
spec:
#  selector:
#    matchLabels:
#      istio: gateway
  action: CUSTOM
  provider:
    name: oauth2-proxy
  rules:
  - to:
    - operation:
        hosts:
          - "*.{{ base_domain }}"
          - "{{ base_domain }}"
          - "{{ base_domain_ext }}"
        notPaths: ["/oauth2*","/hydra/*","/idp/*"]

