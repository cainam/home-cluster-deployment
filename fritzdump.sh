#!/bin/bash

# This is the address of the router
FRITZIP=http://fritz.box
TRAFFIC_FILTER="not (src net (10.0.0.0/8 or 172.16.0.0/12 or 192.168.0.0/16) and dst net (10.0.0.0/8 or 172.16.0.0/12 or 192.168.0.0/16))"

IFACE="2-0"  # WAN
IFACE="1-lan" # LAN
#IFACE="internet"

U1=$1
P1=$2
OUT=$3
SID='0000000000000000'

valid_sid(){
  sid="$1"
  u="$2"
  p="$3"
  echo "Trying to login into $FRITZIP as user $u" >&2
  sid_status=$(curl -s "$FRITZIP/login_sid.lua?sid=${sid}" | awk -F'</?SID>' 'NF>1{print $2}')
  if [ ${sid_status} = '0000000000000000' ]; then
    CHALLENGE=$(curl -k -s $FRITZIP/login_sid.lua |  grep -o "<Challenge>[a-z0-9]\{8\}" | cut -d'>' -f 2)
    HASH=$(printf "%s-%s" "$CHALLENGE" "$p" | iconv -t UTF-16LE | md5sum | cut -d' ' -f1)
    sid=$(curl -k -s "$FRITZIP/login_sid.lua" -d "response=$CHALLENGE-$HASH" -d 'username='${u} | grep -o "<SID>[a-z0-9]\{16\}" | cut -d'>' -f 2)
    echo "${sid}" | grep ^0+$ && echo "Login failed. Did you create & use explicit Fritz!Box users?" >&2 && exit 1
  fi
  echo "${sid}"
}

echo "Capturing traffic on Fritz!Box interface $IFACE ..." 1>&2
SID=$(valid_sid ${SID} $U1 $P1)
curl -X POST "http://fritz.box/capture.lua" -d "sid=$SID" -d "capture=eth0" -d "stop=1"

while true; do
    FILE="$OUT-$(date +%s).pcap"
    echo "[+] capturing $FILE"
    SID=$(valid_sid ${SID} $U1 $P1)
    URL="$FRITZIP/cgi-bin/capture_notimeout?ifaceorminor=$IFACE&snaplen=&capture=Start&sid=$SID"
    #curl --no-buffer -s "$URL" --output $FILE # | podman run --rm -i -v /tmp:/tmp myregistry.adm13:443/local/shark:20260429 tcpdump -r - -w "$FILE" -C 10 -W 20 -G 60 -z gzip
    curl --no-buffer -s "$URL" | tcpdump -r - -w "$FILE" -C 1 "$TRAFFIC_FILTER"
done
