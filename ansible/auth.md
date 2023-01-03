# links

oauth2:
- https://github.com/oauth2-proxy/manifests.git
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/ 
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#keycloak-auth-provider

1.
  oauth2_proxy.cfg: |
    provider = "keycloak"
    client_id = "test"
    client_secret = "LLrwCk590XXNigXgPArtD8L48ekbBEsy"
    oidc_issuer_url = "https://my-lb.adm13:2005/realms/master"
    ssl_insecure_skip_verify = "true"
    email_domains = [ "*" ]
    upstreams = [ "file:///dev/null" ]

2.
    email_domains = [ "*" ]
    provider = "keycloak"
    client_id = "test"
    client_secret = "LLrwCk590XXNigXgPArtD8L48ekbBEsy"
    oidc_issuer_url = "https://my-lb.adm13:2005/realms/test"
    ssl_insecure_skip_verify = "true"
    silence_ping_logging = "true"
    login_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/auth"
    redeem_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token"
    profile_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/userinfo"
    validate_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/userinfo"

3. with redirect_uri error but correct provider
    email_domains = [ "*" ]
    provider = "keycloak-oidc"
    client_id = "test"
    client_secret = "LLrwCk590XXNigXgPArtD8L48ekbBEsy"
    oidc_issuer_url = "https://my-lb.adm13:2005/realms/test"
    ssl_insecure_skip_verify = "true"
    silence_ping_logging = "true"
    scope = "openid profile email groups"
    redirect_url="https://my-lb.adm13:12000/oauth2/callback"
    login_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/auth"
    redeem_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token"
    profile_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/userinfo"
    validate_url="https://my-lb.adm13:2005/realms/test/protocol/openid-connect/userinfo"
4. 
kubectl get cm -n auth oauth2-proxy -o yaml
data:
  oauth2_proxy.cfg: |
    email_domains = [ "*" ]
    provider = "keycloak-oidc"
    client_id = "test"
    client_secret = "EcANXittpGgEpAUyEc9gWFnRxU3nW9qC"
    oidc_issuer_url = "https://my-lb.adm13:2005/realms/test"
    ssl_insecure_skip_verify = "true"
    silence_ping_logging = "true"
    redirect_url="https://my-lb.adm13:12000/oauth2/callback"

keycloak:
- create realm test
- create user test, mail test@abc.de (verified) named first last
- create group test with user test
- create client_id test with client_authentication=on and valid redirect_url http://example.com/*
test: 
curl -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "client_secret=EcANXittpGgEpAUyEc9gWFnRxU3nW9qC" -d "client_id=test" -d "username=test"  -d 'password=test' -d 'grant_type=password'  http://localhost:8080/realms/test/protocol/openid-connect/token
{"access_token":"eyJhbGci.....
also outside the cluster it works:
curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "client_secret=EcANXittpGgEpAUyEc9gWFnRxU3nW9qC" -d "client_id=test" -d "username=test"  -d 'password=test' -d 'grant_type=password'  https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token

test in browser: https://192.168.4.100:2005/realms/test/protocol/openid-connect/auth?client_id=test&response_type=code
env:
    - name: KC_LOG_LEVEL
      value: info
    - name: KC_HTTP_ENABLED
      value: "true"
    - name: X_KC_HOSTNAME_PORT
      value: "2005"
    - name: KC_HOSTNAME_URL
      value: https://my-lb.adm13:2005/
    - name: KC_HOSTNAME_ADMIN_URL
      value: https://192.168.4.100:2005/
    - name: KC_HOSTNAME_STRICT
      value: "false"
    - name: KC_HOSTNAME_STRICT_HTTPS
      value: "false"
    - name: KEYCLOAK_ADMIN
      value: adminx
    - name: KEYCLOAK_ADMIN_PASSWORD
      value: adminx
    - name: KC_PROXY
      value: edge


- storage: persistentvolume => /opt/keycloak/data


istio: 
  - standard ingress gateway + gw + vs
  - AuthorizationPolicy like
    - https://napo.io/posts/istio-oidc-authn--authz-with-oauth2-proxy/
    - with ports like https://www.alibabacloud.com/help/en/alibaba-cloud-service-mesh/latest/set-the-authorization-policy-for-tcp-traffic
    - reference: https://istio.io/latest/docs/reference/config/security/authorization-policy/
  # kubectl get AuthorizationPolicy -n istio-system ext-authz -o yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istio-system
spec:
  action: CUSTOM
  provider:
    name: oauth2-proxy
  rules:
  - to:
    - operation:
        ports:
        - "1111"
        - "22000"
  selector:
    matchLabels:
      istio: gateway


  istio configmap: 
    extensionProviders:
    - name: "oauth2-proxy"
      envoyExtAuthzHttp:
        service: "oauth2-proxy.auth.svc.cluster.local"
        port: "80" # The default port used by oauth2-proxy.
      headersToUpstreamOnAllow:
      - path
      - x-auth-request-email
      - x-auth-request-preferred-username
      headersToDownstreamOnDeny:
      - content-type
      - set-cookie
      includeRequestHeadersInCheck:
      - authorization
      - cookie
      - x-auth-request-groups
      includeAdditionalHeadersInCheck: # Optional for oauth2-proxy to enforce https
        X-Auth-Request-Redirect: 'https://%REQ(:authority)%%REQ(:path)%'


