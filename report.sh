#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$(journalctl -u $folder.service --no-hostname -o cat | grep "MOONVEIL L2 Muse Node" | awk '{print $6}' | tail -1 )
nft=$(journalctl -u $folder.service --no-hostname -o cat | grep "successfully delegated" | awk '{print $7}' | tail -1 | sed 's/#//')
service=$(sudo systemctl status $folder --no-pager | grep "active (running)" | wc -l)
errors=$(journalctl -u $folder.service --since "1 hour ago" --no-hostname -o cat | grep -c -E "rror|ERR")
success=$(journalctl -u $folder.service --since "1 day ago" --no-hostname -o cat | grep -c -E "successfully validated")

status="ok" && message=""
[ $errors -gt 500 ] && status="warning" && message="too many errors";
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
        "m1":"bph=$success",
        "m2":"nft=$nft"
  }
}
EOF

cat $json | jq
