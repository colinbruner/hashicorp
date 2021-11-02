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
# EC2
###

variable "ec2_nomad_ami" {
  type    = string
  default = "ami-0b28a6c361c2c463e"
}

variable "ec2_key_name" {
  type    = string
  default = "colin.bruner"
}
