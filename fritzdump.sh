#!/bin/bash

# This is the address of the router
FRITZIP=http://fritz.box

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
  sid_status=$(wget -qO- "http://fritz.box/login_sid.lua?sid=${sid}" | grep -oP '(?<=<SID>).*?(?=</SID>)')
  if [ ${sid_status} = '0000000000000000' ]; then
    # Request challenge token from Fritz!Box
    CHALLENGE=$(curl -k -s $FRITZIP/login_sid.lua |  grep -o "<Challenge>[a-z0-9]\{8\}" | cut -d'>' -f 2)

    # Very proprieatry way of AVM: Create a authentication token by hashing challenge token with password
    HASH=$(perl -MPOSIX -e '
        use Digest::MD5 "md5_hex";
        my $ch_Pw = "$ARGV[0]-$ARGV[1]";
        $ch_Pw =~ s/(.)/$1 . chr(0)/eg;
        my $md5 = lc(md5_hex($ch_Pw));
        print $md5;
      ' -- "$CHALLENGE" "$p")
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
    curl --no-buffer -s "$URL" | podman run --rm -i -v /tmp:/tmp myregistry.adm13:443/local/shark:20260429 tcpdump -r - -w "$FILE" -C 1 # -W 20 -G 60 # -z gzip #--output $FILE
done
