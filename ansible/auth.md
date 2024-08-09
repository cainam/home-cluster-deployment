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

istio: 
helm upgrade --install -n istio-system istiod istio-system/istiod --set global.proxy.privileged=true --set pilot.image=istio/pilot:1.16.2 --set global.proxy.image=istio/proxyv2:1.16.2 --set global.proxy_init.image=istio/proxyv2:1.16.2 --set global.tracer.zipkin.address=jaeger-collector.tools:9411 --set pilot.resources.requests.memory=128Mi -f values-istiod.yaml 
  - standard ingress gateway + gw + vs
  - AuthorizationPolicy like
    - https://napo.io/posts/istio-oidc-authn--authz-with-oauth2-proxy/
    - with ports like https://www.alibabacloud.com/help/en/alibaba-cloud-service-mesh/latest/set-the-authorization-policy-for-tcp-traffic
    - reference: https://istio.io/latest/docs/reference/config/security/authorization-policy/
    - best!!! https://developer.okta.com/blog/2022/07/14/add-auth-to-any-app-with-oauth2-proxy

# subdomains: cookie_domain? whilelist-domain?

# oauth2 with curl
1. curl -v -L --cookie-jar /tmp/cookie1 https://open.my-lb.adm13/dummy, notes:
- last redirect: > GET /authentication/login?login_challenge=cc2ef20d32164703aa2a4c5dfb87fbbd HTTP/2
<form class="form-signin" method="post" action="/authentication/login">
    <h1 class="h3 mb-3 font-weight-normal">Please sign in</h1>
    <input type="hidden" name="login_challenge" value="cc2ef20d32164703aa2a4c5dfb87fbbd">
    <label for="inputEmail" class="sr-only">Email address</label>
    <input type="email" id="inputEmail" class="form-control" name="email" placeholder="Email address" required autofocus>
    <label for="inputPassword" class="sr-only">Password</label>
    <input type="password" id="inputPassword" class="form-control" name="password" placeholder="Password" required>
    <div class="checkbox mb-3">
        <label>
            <input type="checkbox" name="remember_me" value="true"> Remember me
        </label>
    </div>
    <button class="btn btn-lg btn-primary btn-block" type="submit">Sign in</button>
2. submit login form like this: curl  --data-urlencode -H "Content-Type: application/x-www-form-urlencoded"  -X POST -v -L https://open.my-lb.adm13/authentication/login -d "login_challenge=9564b82da1184091a6f2d29befccb9ba&email=user2@example.com&password=password" 


auth update:
- initially keycloak but: no full featured idp required, huge resource consumption, corrupted DB, time to change: options seen: DEX and hydra, hydra selected because simple and separation with idp
- Authorization policy per gateway
- oauth2-proxy per ID provider, names to match in Authorization and extensionProviders: in isiod config
- hydra debug: add log.level: debug to hydra cm
# manually edited and to be moved to ansible
- 2nd AuthorizationPolicy
- pod exec parameters:         - --cookie-domain=.my-lb.adm13,my-lb.adm13 (and same for white-list-domain)
- 2nd extensionProviders: in istio cm
# test hydra: https://my-lb.adm13/hydra/.well-known/openid-configuration
# create client: ~ $ hydra create oauth2-client -e http://localhost:4445 --name test --scope openid --secret oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0
# or:  curl -v -L -X POST 'http://hydra-admin.auth:4445/clients' -H 'Content-Type: application/json'  --data-raw "$(cat /app/hydra-client.json)" with file content:
{
    "client_name": "test",
    "client_secret": "oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0",
    "grant_types": ["authorization_code", "refresh_token"],
    "redirect_uris": ["https://my-lb.adm13/oauth2-hydra/callback"],
    "response_types": ["code", "id_token"],
    "scope": "offline openid users.write users.read users.edit users.delete",
    "token_endpoint_auth_method": "client_secret_post"
}
- test /userinfo endpoint: curl -v http://hydra-public.auth:4444/userinfo -H "Authorization: Bearer ory_at_5CEmBYcSTKtbvUB6jCL3OpZrkOGdQ3H0yC1a6J3dees.l66_2V80ta5HRFHxHi1X6joSoTtI87pQR3isysJhjow"
- hydra: sql lite: ~ $ hydra migrate sql -e -c /etc/config/hydra.yaml^C
~ $ export DSN=sqlite:///dev/shm/some-db.sqlite?_fk=true^C
 curl -v -L -X POST 'http://hydra-admin.auth:4445/clients' -H 'Content-Type: application/json'  --data-raw "$(cat /app/hydra-client.json)" with file content:
{
    "client_name": "test",
    "client_secret": "oyoEa5qajmOqBFtJHWEg2iZhGli5nQu0", 
    "grant_types": ["authorization_code", "refresh_token"],
    "redirect_uris": ["https://my-lb.adm13/oauth2-hydra/callback"],
    "response_types": ["code", "id_token"],
    "scope": "offline openid users.write users.read users.edit users.delete",
    "token_endpoint_auth_method": "client_secret_post"
}   
