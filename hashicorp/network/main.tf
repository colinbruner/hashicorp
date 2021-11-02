###
# AWS
###
provider "aws" {
  region = var.aws_region
}

###
# Main
###

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}-${var.environment}"
  cidr = var.vpc_cidr

  # Expects '10.0.0.0/22' for CIDR.
  azs            = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
}
