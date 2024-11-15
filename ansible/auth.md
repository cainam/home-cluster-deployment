# Solution

Authentication and Authorization of the system is based on oauth2_proxy => hydra => idp downstream configuration
1. oauth2_proxy is configured on service mesh level to centrally manage access control outside individual applications
2. hydra is the OAUTH2 and OIDC provider used by oauth2 proxy to enable support for these protocols
3. idp is a smapp application performing identity provider functionalities as login and consent management

Initially keycloak was used, but it turned out to be too resource intensive and too complex for the required solution, DEX would be an alternative too.

## hydra deployment
a dedicated hydra-config helm chart is deployed
- to provide the optional PVC if persistent database is used
- to configure client_id via post-install batch Job (not used) and
- to deploy a Kubernetes Operator which configures the client_id upon hydra pod restart

## hydra-config
internal chart to implement k8s operator to handle client_id, but can also create a pvc for hydra if needed. A helm-job to run as post-install is included, but no longer used in favor of the k8s operator

# links
all: 
- https://www.blog.jetstack.io/blog/istio-oidc/
- https://www.ventx.de/blog/post/istio_oauth2_proxy/index.html

oauth2:
- https://github.com/oauth2-proxy/manifests.git
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/ 
- https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#keycloak-auth-provider

# testing authentication
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

# oauth2 with curl
1. curl -v -L --cookie /tmp/cookie1 --cookie-jar /tmp/cookie1 https://open.my-lb.adm13/dummy 2>&1 | tail -n 1 | sed -e 's/</\n</g' | grep input

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
2. submit login form like this: curl --cookie /tmp/cookie1 --cookie-jar /tmp/cookie1  --data-urlencode -H "Content-Type: application/x-www-form-urlencoded"  -X POST -v -L https://my-lb.adm13/idp/login -d "login_challenge=9564b82da1184091a6f2d29befccb9ba&email=user2@example.com&password=password" 

# manually edited and to be moved to ansible
- 2nd AuthorizationPolicy
- pod exec parameters:         - --cookie-domain=.my-lb.adm13,my-lb.adm13 (and same for white-list-domain)
- 2nd extensionProviders: in istio cm
# test hydra: https://my-lb.adm13/hydra/.well-known/openid-configuration
- test /userinfo endpoint: curl -v http://hydra-public.auth:4444/userinfo -H "Authorization: Bearer ory_at_5CEmBYcSTKtbvUB6jCL3OpZrkOGdQ3H0yC1a6J3dees.l66_2V80ta5HRFHxHi1X6joSoTtI87pQR3isysJhjow"

# Old remarks when using keycloak:
- error "Caused by: org.h2.mvstore.MVStoreException: The write format 2 is smaller than the supported format 3 [2.2.220/5]" => fix by migrating the DB to a newer version: java -jar H2MigrationTool-1.4-all.jar -d keycloakdb.mv.db -f 2.0.202 -t 2.2.220 --user sa --password password

setup keycloak:
- create realm test
- create user test, mail test@abc.de (verified) named first last
- create group test with user test
- create client_id test with client_authentication=on and valid redirect_url http://example.com/*
test: 
curl -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "client_secret=EcANXittpGgEpAUyEc9gWFnRxU3nW9qC" -d "client_id=test" -d "username=test"  -d 'password=test' -d 'grant_type=password'  http://localhost:8080/realms/test/protocol/openid-connect/token
{"access_token":"eyJhbGci.....
also outside the cluster it works:
curl -k -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "client_secret=EcANXittpGgEpAUyEc9gWFnRxU3nW9qC" -d "client_id=test" -d "username=test"  -d 'password=test' -d 'grant_type=password'  https://my-lb.adm13:2005/realms/test/protocol/openid-connect/token
