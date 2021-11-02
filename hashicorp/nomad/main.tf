###
# AWS
###
provider "aws" {
  region = var.aws_region
}

locals {

  # Network
  public_subnets    = data.terraform_remote_state.network.outputs.public_subnets
  route53_zone_id   = data.terraform_remote_state.network.outputs.route53_zone_id
  route53_subdomain = data.terraform_remote_state.network.outputs.route53_subdomain

  # SGs
  ssh_sg    = data.terraform_remote_state.network.outputs.ssh_sg
  nomad_sg  = data.terraform_remote_state.network.outputs.nomad_sg
  consul_sg = data.terraform_remote_state.network.outputs.consul_sg

  # IAM
  iam_instance_profile = data.terraform_remote_state.iam.outputs.describe_instance_profile_id
}

###
# Main
###
# Create 5 Servers

resource "aws_instance" "server" {
  count = 5

  #ami           = var.ec2_nomad_server_ami
  ami           = var.ec2_nomad_ami
  instance_type = "t3.large"

  # Spread them out in 3 az's
  subnet_id                   = local.public_subnets[count.index % 3]
  vpc_security_group_ids      = [local.ssh_sg, local.nomad_sg, local.consul_sg]
  associate_public_ip_address = true

  root_block_device {
    encrypted   = true
    volume_size = 100
    volume_type = "gp2"
  }

  iam_instance_profile = local.iam_instance_profile

  key_name = var.ec2_key_name

  tags = {
    "Name" = "nomad-server-${count.index}"
  }
}

resource "aws_route53_record" "server" {
  count = 5

  zone_id = local.route53_zone_id
  name    = "${aws_instance.server[count.index].tags.Name}.${local.route53_subdomain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.server[count.index].public_ip]
}
