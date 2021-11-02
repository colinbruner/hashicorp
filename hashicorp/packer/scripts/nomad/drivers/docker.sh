#!/bin/bash -e

###
# Installs / Configures Docker as a container driver
###

# Just install the package which will enable / start the systemd daemon
sudo apt-get install docker.io -y
