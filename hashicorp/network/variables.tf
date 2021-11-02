###
# AWS
###
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

###
# Environment
###
variable "environment" {
  type    = string
  default = "sandbox"
}

###
# Network
###
variable "vpc_name" {
  type    = string
  default = "hashicorp"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/22"
}

###
# Route53
###
variable "route53_base_domain" {
  type = string
}
