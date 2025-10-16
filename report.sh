#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$(journalctl -u $folder.service --no-hostname -o cat | grep "MOONVEIL L2 Muse Node" | awk '{print $6}' | tail -1 )
[ -z $version ] || echo $version >/root/logs/$folder-version
version=$(cat /root/logs/$folder-version)
nft=$(journalctl -u $folder.service --no-hostname -o cat | grep "successfully delegated" | awk '{print $7}' | tail -1 | sed 's/#//')
[ -z $nft ] || echo $nft >/root/logs/$folder-nft
nft=$(cat /root/logs/$folder-nft)
service=$(sudo systemctl status $folder --no-pager | grep "active (running)" | wc -l)
errors=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")
bpd=$(journalctl -u $folder.service --since "1 day ago" --no-hostname -o cat | grep -c -E "successfully validated")
bph=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "successfully validated")

status="ok" && message="validated $bph blocks last hour" 
[ $bph -eq 0 ] && systemctl restart $folder.service && status="warning" && message="restarted (no blocks last hour)";
[ $errors -gt 500 ] && status="warning" && message="too many errors ($errors/h)";
[ $service -ne 1 ] && status="error" && message="service not running";

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "id":"$folder",
       "machine":"$MACHINE",
       "grp":"node",
       "owner":"$OWNER"
  },
  "fields": {
        "chain":"moonveil",
        "network":"mainnet",
        "version":"$version",
        "status":"$status",
        "message":"$message",
        "service":$service,
        "errors":$errors,
        "m1":"bpd=$bpd bph=$bph",
        "m2":"nft=$nft"
  }
}
EOF

cat $json | jq
