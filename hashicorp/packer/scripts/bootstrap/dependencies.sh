#!/bin/bash -e

###
# Installs base dependencies bootstrap
###

sudo apt-get install -y python3-pip jq
sudo pip3 install boto3 awscli