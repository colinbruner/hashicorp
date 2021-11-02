#!/bin/bash -e

###
# Configures Nomad as a server'
###

NOMAD_CONFIG_DIR="/etc/nomad.d"

# NOTE: Hardcoded number of servers to expect "5"
sudo tee $NOMAD_CONFIG_DIR/nomad.hcl << EOF
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 5
}

plugin "raw_exec" {
  config {
    enabled = true
    no_cgroups = true
  }
}

client {
  enabled = true

  # Add /var/www to isolated exec chroot env
  chroot_env {
    "/bin"            = "/bin"
    "/etc"            = "/etc"
    "/lib"            = "/lib"
    "/lib32"          = "/lib32"
    "/lib64"          = "/lib64"
    "/run/resolvconf" = "/run/resolvconf"
    "/usr"            = "/usr"
    "/var/www"        = "/var/www"
  }
}
EOF