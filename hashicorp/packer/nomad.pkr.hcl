locals {
  # Grab the source ami from ami_map defaults
  source_ami = var.base_nomad_ami

  # Set AMI name based on timestamp and the version of NVIDIA Tesla driverA
  nomad_server = "nomad-server-${replace(timestamp(), ":", "-")}"
}

# Building a Nomad Server + Client in a single AMI for the sake of ease
source "amazon-ebs" "nomad_server" {
  ami_name      = local.nomad_server
  instance_type = var.instance_type

  # Ubuntu
  source_ami = local.source_ami

  # Network
  region    = var.aws_region
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
  # Security
  security_group_ids = var.security_group_ids

  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.nomad_server"]

  # Race Conditions :(
  provisioner "shell" {
    inline = ["sleep 10"]
  }

  # Configure Consul
  provisioner "shell" {
    script = "scripts/consul/configure_client.sh"
    environment_vars = [
      "CONSUL_DATACENTER=${var.dc_name}"
    ]
  }

  # Configure Nomad
  provisioner "shell" {
    script = "scripts/nomad/configure.sh"
  }

  ###
  # Certificate Upload
  ###
  # Upload Consul agent CA, create necessary dirs, move into place
  provisioner "file" {
    source      = "files/certs/consul-agent-ca.pem"
    destination = "/home/ubuntu/"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /home/ubuntu/",
      "sudo mkdir -p /etc/pki/tls/private",
      "sudo mv /home/ubuntu/consul-agent-ca.pem /etc/pki/tls/private/",
      "sudo chown consul:consul /etc/pki/tls/private/consul-agent-ca.pem",
      "sudo chmod 0600 /etc/pki/tls/private/consul-agent-ca.pem"
    ]
  }
}
