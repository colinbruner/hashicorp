#!/bin/bash -e

###
# Configure Consul Client
###

sudo tee /etc/consul.d/consul.hcl <<EOF
datacenter = "${CONSUL_DATACENTER}"
data_dir = "/opt/consul"

# https://www.consul.io/docs/agent/options#bind_addr
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"172.26.0.0/22\" | attr \"address\" }}"

# https://www.nomadproject.io/docs/integrations/consul-connect#consul
ports = {
  grpc = 8502
}

connect = {
  enabled = true
}

# https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure#configure-the-clients
verify_incoming = false
verify_outgoing = true
verify_server_hostname = true
ca_file = "/etc/pki/tls/private/consul-agent-ca.pem"
auto_encrypt = {
  tls = true
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

sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl
