#!/bin/bash -e

###
# Install Consul
###

sudo apt-get install -y consul

# Validate Nomad was installed successfully
consul --version &> /dev/null
if [[ $? == 0 ]]; then
    echo "Consul was installed successfully."
else
    echo "ERROR: Consul installation failed, Error Code: $?"
	exit 1
fi

sudo tee /etc/systemd/system/consul.service <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable consul