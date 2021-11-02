
###
# Packer
###
# terraform output packer_vars > $var_file
output "packer_vars" {
  value = {
    vpc_id             = module.vpc.vpc_id,
    subnet_id          = module.vpc.public_subnets[0]
    security_group_ids = [aws_security_group.ssh.id]
  }

}

###
# Network
###

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
###
# Route53
###

output "route53_zone_id" {
  value = aws_route53_zone.sandbox.zone_id
}

output "route53_subdomain" {
  value = "sandbox.${var.route53_base_domain}"
}

###
# Security Groups
###

output "ssh_sg" {
  value = aws_security_group.ssh.id
}

output "nomad_sg" {
  value = aws_security_group.nomad.id
}

output "consul_sg" {
  value = aws_security_group.consul.id
}
