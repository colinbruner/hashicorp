locals {
  # Grab the source ami from ami_map defaults
  source_ami = var.ami_map[var.aws_region]

  # Set AMI name based on timestamp and the version of NVIDIA Tesla driverA
  consul_server = "consul-server-${replace(timestamp(), ":", "-")}"
}

source "amazon-ebs" "consul_server" {
  ami_name      = local.consul_server
  instance_type = var.instance_type

  # Ubuntu
  source_ami    = "ami-09e67e426f25ce0d7" # local.consul_server
  #source_ami = local.source_ami

  # Network
  region    = var.aws_region
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
  # Security
  security_group_ids = var.security_group_ids

  ssh_username = "ubuntu"
}

# NOTE: Lots of logic in this. Going back, I'd probably just do this with Ansible.
build {
  sources = ["source.amazon-ebs.consul_server"]

  # Race Conditions Problems :/
  provisioner "shell" {
    inline = ["sleep 10"]
  }

  # Install & Configure Consul Server & Envoy
  provisioner "shell" {
    scripts = [
      "scripts/bootstrap/hashicorp_repos.sh",
      "scripts/bootstrap/dependencies.sh",
      "scripts/consul/install.sh",
      "scripts/consul/configure_server.sh"
    ]
    environment_vars = [
      "CONSUL_DATACENTER=${var.dc_name}"
    ]
  }

  ###
  # Certificate Upload
  ###
  # Prepare necessary directories for uploads
  provisioner "shell" {
    inline = [
      "mkdir -p /home/ubuntu/certs",
      "sudo mkdir -p /etc/pki/tls/private",
      "sudo mkdir -p /etc/pki/tls/certs"
    ]
  }

  # NOTE: We're copying all Certs and mv'ing the correct ones into place using
  # a systemd service below. Please don't do something like this in production.
  provisioner "file" {
    sources = [
      "files/certs/consul-agent-ca.pem",
      "files/certs/${var.dc_name}-server-consul-0-key.pem",
      "files/certs/${var.dc_name}-server-consul-0.pem",
      "files/certs/${var.dc_name}-server-consul-1-key.pem",
      "files/certs/${var.dc_name}-server-consul-1.pem",
      "files/certs/${var.dc_name}-server-consul-2-key.pem",
      "files/certs/${var.dc_name}-server-consul-2.pem"
    ]
    destination = "/home/ubuntu/certs/"
  }

  ###
  # Startup
  ###
  provisioner "shell" {
    inline = [
      "echo CONSUL_DATACENTER=${var.dc_name} | sudo tee /etc/default/install_consul_certs",
    ]
  }

  # Install oneshot service that handles cert juggling logic.
  provisioner "file" {
    sources = [
      "scripts/systemd/install_consul_certs.py",
      "scripts/systemd/install_consul_certs.service"
    ]
    destination = "/tmp/"
  }
  # Move files to correct place & enable oneshot service for first boot.
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/install_consul_certs.py /opt/",
      "sudo mv /tmp/install_consul_certs.service /etc/systemd/system/",
      "sudo systemctl enable install_consul_certs"
    ]
  }
}
