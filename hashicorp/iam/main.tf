###
# AWS
###

provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "describe_instance" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "describe_instance" {
  name = "ec2_describe_instances"

  inline_policy {
    name   = "ec2_describe_instances"
    policy = data.aws_iam_policy_document.describe_instance.json
  }
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_instance_profile" "describe_instance" {
  name = "ec2_describe_instances"
  role = aws_iam_role.describe_instance.name
}
