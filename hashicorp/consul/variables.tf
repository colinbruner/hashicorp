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

variable "ec2_consul_server_ami" {
  type    = string
  default = "ami-0828b8986ca434f18"

}

variable "ec2_key_name" {
  type    = string
  default = "colin.bruner"
}
