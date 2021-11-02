#!/bin/bash -e

###
# Configure Consul Client running on Server?
###

sudo tee /etc/consul.d/consul.hcl <<EOF
# Required
datacenter = "${CONSUL_DATACENTER}"
data_dir = "/opt/consul"

# https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure#configure-the-clients
verify_incoming = false
verify_outgoing = true
verify_server_hostname = true
ca_file = "/etc/pki/tls/private/consul-agent-ca.pem"
auto_encrypt = {
  allow_tls = true
}

# https://learn.hashicorp.com/tutorials/consul/deployment-guide#enable-consul-acls
acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}

# https://learn.hashicorp.com/tutorials/consul/deployment-guide#performance-stanza
performance {
  raft_multiplier = 1
}

retry_join = ["provider=aws tag_key=consul-server tag_value=true"]
EOF

###
# Configure Consul Server
###

sudo tee /etc/consul.d/server.hcl <<EOF
server = true
bootstrap_expect = 3
client_addr = "0.0.0.0"
ui_config {
  enabled = true
}

# TLS https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure#configure-the-servers
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
ca_file = "/etc/pki/tls/private/consul-agent-ca.pem"
cert_file = "/etc/pki/tls/certs/PLACEHOLDER.pem"
key_file = "/etc/pki/tls/certs/PLACEHOLDER-key.pem"
auto_encrypt {
  allow_tls = true
}
EOF

sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/{server,consul}.hcl
