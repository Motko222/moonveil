path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source $path/env

read -p "Sure? " c
case $c in y|Y) ;; *) exit ;; esac

#create env
cd $path
[ -f env ] || cp env.sample env
nano env

#install binary
[ -d /root/moonveil ] && mkdir /root/moonveil  
cd /root/moonveil
wget $URL node-software
chmod +x node-software

#create service
printf "[Unit]
Description=$folder node
After=network.target
Wants=network-online.target

[Service]
EnvironmentFile=/root/scripts/$folder/env
User=root
Group=root
ExecStart=/root/moonveil/node-software -confirm-agreement --private-key $PK
Restart=always
RestartSec=30
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$folder
WorkingDirectory=/root/moonveil

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$folder.service

sudo systemctl daemon-reload
sudo systemctl enable $folder
