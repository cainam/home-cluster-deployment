FROM docker.io/library/debian:12.4-slim

ENV KEYCLOAK_VERSION 22.0.5
ENV LANG en_US.UTF-8

ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

USER root 
RUN apt -y update && apt -y upgrade && apt -y install  openjdk-17-jre-headless  curl
#RUN groupadd keycloak && useradd --home-dir /opt --gid keycloak --no-create-home keycloak && chown -R -h keycloak:keycloak /opt
RUN chown -R -h 100200:100200  /opt
USER 100200
RUN curl -L -o /opt/kc.tar.gz $KEYCLOAK_DIST && cd /opt/ && tar --extract --gzip --file=kc.tar.gz --owner=100200 --group=100200 && rm /opt/kc.tar.gz && ln -s * keycloak
