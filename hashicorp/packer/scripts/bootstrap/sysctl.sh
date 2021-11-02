#/bin/bash -e

# This should be enabled by default regardless
sudo tee /etc/sysctl.d/10-bridge-network.conf << EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF