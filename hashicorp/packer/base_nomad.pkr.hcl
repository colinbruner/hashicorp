###
# Base AMI: This is contains base Software packages required by Nomad
###

locals {
  # Grab the source ami from ami_map defaults
  source_ami = var.ami_map[var.aws_region]

  # Set AMI name based on timestamp and the version of NVIDIA Tesla driverA
  base_nomad_server = "base-nomad-server-${replace(timestamp(), ":", "-")}"
}

# Build Base Nomad Server + Client in a single AMI for the sake of ease
source "amazon-ebs" "base_nomad_server" {
  ami_name      = local.base_nomad_server
  instance_type = var.instance_type

  # Ubuntu
  #source_ami = local.source_ami
  source_ami = "ami-09e67e426f25ce0d7"

  # Network
  region    = var.aws_region
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
  # Security
  security_group_ids = var.security_group_ids

  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.base_nomad_server"]

  # Race Conditions :(
  provisioner "shell" {
    inline = ["sleep 10"]
  }

  # Install HashiCorp Repos, Ruby, and other base dependencies
  provisioner "shell" {
    scripts = [
      "scripts/bootstrap/hashicorp_repos.sh",
      "scripts/bootstrap/dependencies.sh",
      "scripts/bootstrap/sysctl.sh",
      "scripts/bootstrap/ruby.sh",
    ]
  }

  # Install Nomad & Base Drivers
  provisioner "shell" {
    scripts = [
      "scripts/nomad/install.sh",
      "scripts/nomad/drivers/docker.sh",
      "scripts/nomad/drivers/cni_bridge.sh"
    ]
  }

  # Install Consul as a local agent Client
  provisioner "shell" {
    scripts = [
      "scripts/consul/install.sh",
    ]
    environment_vars = [
      "CONSUL_DATACENTER=${var.dc_name}"
    ]
  }

  post-processor "manifest" {
    output     = "manifests/base_nomad.json"
    strip_path = true
  }
}
