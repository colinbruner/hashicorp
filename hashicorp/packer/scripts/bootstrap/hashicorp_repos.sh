#!/bin/bash -e

###
# Sets up the Hashicorp release repo
###

# Throwing stdout of 'apt-key add' to /dev/null prevents scary red in Packer output.
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - &>/dev/null
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update -y