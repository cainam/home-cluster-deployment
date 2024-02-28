FROM alpine:3.19.1

EXPOSE 9050 9051 5353
RUN apk upgrade --no-cache && apk add --no-cache tor
CMD tor -f /etc/tor/torrc
