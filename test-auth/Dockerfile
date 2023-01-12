FROM k8s.gcr.io/e2e-test-images/echoserver:2.5
RUN sed -i '/\[::\]/d' /etc/nginx/nginx.conf
RUN cat /etc/nginx/nginx.conf

