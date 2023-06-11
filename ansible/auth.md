# links


error:
[2023/02/09 19:24:55] [oauthproxy.go:823] Error redeeming code during OAuth2 callback: could not verify id_token: audience claims [] do not exist in claims: map[acr:0 at_hash:lwpWV3nKMvtRyhcSZdFppQ aud:test auth_time:1.675970421e+09 azp:test email:test@abc.de email_verified:true exp:1.675970994e+09 family_name:last given_name:first iat:1.675970694e+09 iss:https://my-lb.adm13:2005/realms/test jti:a077fae1-b000-4e14-bef9-c7f5894cc403 name:first last nonce:oqVtYnjYky9ym_u1KwZXn3uPlt4N3km6rAlNSwhW_F4 preferred_username:test session_state:9ce3f240-8131-4410-930c-4bbd65f7aaec sid:9ce3f240-8131-4410-930c-4bbd65f7aaec sub:a52872d5-b846-42a9-ab29-15426e17870f typ:ID]


all: 
- https://www.blog.jetstack.io/blog/istio-oidc/
- https://www.ventx.de/blog/post/istio_oauth2_proxy/index.html

oauth2:
- https://github.com/oauth2-proxy/manifests.git
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/ 
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#keycloak-auth-provider

kubectl get cm -n auth oauth2-proxy -o yaml
data:
  oauth2_proxy.cfg: |-
    email_domains = [ "*" ]
    upstreams = [ "file:///dev/null" ]
    provider = "keycloak-oidc"
    client_id = "test"
    client_secret = "oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0"
    cookie_secret = "lki74598sjfojifggjnsodnf"
    oidc_issuer_url = "https://my-lb.adm13:2005/realms/test"
    ssl_insecure_skip_verify = "true"
    silence_ping_logging = "true"
    redirect_url="https://my-lb.adm13:12000/oauth2/callback"

data:
  oauth2_proxy.cfg: "email_domains = [ \"*\" ]\nupstreams = [ \"file:///dev/null\"
    ]\nprovider = \"keycloak-oidc\"\nclient_id = \"test\"\nclient_secret = \"oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0\"\ncookie_secret
    = \"lki74598sjfojifggjnsodnf\"\noidc_issuer_url = \"https://my-lb.adm13:2005/realms/test\"\nssl_insecure_skip_verify
    = \"true\"\nsilence_ping_logging = \"true\"\nset_authorization_header=true\nskip_provider_button=true\nwhitelist_domains
    = [ \"my-lb.adm13:*\",\"*.my-lb.adm13:*\" ]\ncookie_samesite=\"lax\"\ncookie_csrf_per_request=true\ncookie_csrf_expire=\"5m\"\nset_xauthrequest=true\npass_user_headers
    = true\npass_authorization_header = true\npass_access_token = true\ncookie_secure
    = false\nreverse_proxy=true "


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

#### full test with token
tk=$(curl -s -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=test" -d "username=test" -d "password=test" -d "grant_type=password" -d "scope=openid" -d "client_secret=oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0" -X POST https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token | jq -r .id_token); echo "token: $tk"
curl -L -i -X GET -H "Authorization: Bearer $tk" https://my-lb.adm13/infopage # success
curl -L -i -X GET -H "Authorization: Bearer xxx" https://my-lb.adm13/infopage # fail
curl -L -i -X GET -H "Authorization: Bearer xxx" https://ha.my-lb.adm13 # success, oauth2 is bypassed


#### full test as browser client
 curl -s -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=test" -d "username=test" -d "password=test" -d "grant_type=password" -d "scope=openid" -d "client_secret=oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0" -X POST https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token | jq


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
helm upgrade --install -n istio-system istiod istio-system/istiod --set global.proxy.privileged=true --set pilot.image=istio/pilot:1.16.2 --set global.proxy.image=istio/proxyv2:1.16.2 --set global.proxy_init.image=istio/proxyv2:1.16.2 --set global.tracer.zipkin.address=jaeger-collector.tools:9411 --set pilot.resources.requests.memory=128Mi -f values-istiod.yaml 


  - standard ingress gateway + gw + vs
  - AuthorizationPolicy like
    - https://napo.io/posts/istio-oidc-authn--authz-with-oauth2-proxy/
    - with ports like https://www.alibabacloud.com/help/en/alibaba-cloud-service-mesh/latest/set-the-authorization-policy-for-tcp-traffic
    - reference: https://istio.io/latest/docs/reference/config/security/authorization-policy/
    - best!!! https://developer.okta.com/blog/2022/07/14/add-auth-to-any-app-with-oauth2-proxy
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


# subdomains: cookie_domain? whilelist-domain?
