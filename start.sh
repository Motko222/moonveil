#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')

systemctl restart $folder.service
sleep 2s
journalctl -n 200 -u $folder.service -f --no-hostname -o cat
