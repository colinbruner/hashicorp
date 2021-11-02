#!/bin/bash -e

###
# Install CNI Bridge Plugin binaries
# https://discuss.hashicorp.com/t/failed-to-find-plugin-bridge-in-path/3095
###

VERSION="1.0.1"

curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v${VERSION}/cni-plugins-linux-amd64-v${VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz