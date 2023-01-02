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

3. 
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
- create realm
- create user test 
- create group test with user test
- create client_id test with client_authentication=on and valid redirect_url http://example.com/*
test: 
curl -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "client_secret=EcANXittpGgEpAUyEc9gWFnRxU3nW9qC" -d "client_id=test" -d "username=test"  -d 'password=test' -d 'grant_type=password'  http://localhost:8080/realms/test/protocol/openid-connect/token
{"access_token":"eyJhbGci.....
test in browser: https://192.168.4.100:2005/realms/test/protocol/openid-connect/auth?client_id=test&response_type=code


- storage: persistentvolume => /opt/keycloak/data


istio: 
  - standard ingress gateway + gw + vs
  - AuthorizationPolicy like
    - https://napo.io/posts/istio-oidc-authn--authz-with-oauth2-proxy/
    - with ports like https://www.alibabacloud.com/help/en/alibaba-cloud-service-mesh/latest/set-the-authorization-policy-for-tcp-traffic
    - reference: https://istio.io/latest/docs/reference/config/security/authorization-policy/
