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
  consul_sg = data.terraform_remote_state.network.outputs.consul_sg

  # IAM
  iam_instance_profile = data.terraform_remote_state.iam.outputs.describe_instance_profile_id
}

###
# Main
###
# Create 3 Servers

resource "aws_instance" "server" {
  count = 3

  ami           = var.ec2_consul_server_ami
  instance_type = "t3.small"

  subnet_id                   = local.public_subnets[count.index]
  vpc_security_group_ids      = [local.ssh_sg, local.consul_sg]
  associate_public_ip_address = true

  iam_instance_profile = local.iam_instance_profile

  key_name = var.ec2_key_name

  tags = {
    "Name"          = "consul-server-${count.index}"
    "consul-server" = "true"
  }
}

resource "aws_route53_record" "server" {
  count = 3

  zone_id = local.route53_zone_id
  name    = "${aws_instance.server[count.index].tags.Name}.${local.route53_subdomain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.server[count.index].public_ip]
}
