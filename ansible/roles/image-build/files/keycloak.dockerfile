FROM docker.io/library/debian:11.5-slim

ENV KEYCLOAK_VERSION 20.0.1
ENV LANG en_US.UTF-8

ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

USER root 
RUN apt -y update && apt -y upgrade && apt -y install  openjdk-11-jre-headless  curl
RUN groupadd keycloak && useradd --home-dir /opt --gid keycloak --no-create-home keycloak && chown -R -h keycloak:keycloak /opt
USER keycloak
RUN curl -L -o /opt/kc.tar.gz $KEYCLOAK_DIST && cd /opt/ && tar --extract --gzip --owner=keycloak --file=kc.tar.gz --owner=keycloak --group=keycloak && rm /opt/kc.tar.gz && ln -s * keycloak

USER 1000

