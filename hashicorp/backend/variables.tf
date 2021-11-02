###
# AWS
###

variable "aws_region" {
  default = "us-east-2"
}

###
# s3
###

variable "s3_backend_bucket" {
  type    = string
  default = "hashicorp-sandbox-backend"
}
