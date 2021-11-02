###
# AWS
###

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

# Ubuntu 20.04 LTS (base img)
variable "ami_map" {
  type = map(string)
  default = {
    "us-east-1" = "ami-09e67e426f25ce0d7"
    "us-east-2" = "ami-00399ec92321828f5"
  }
  description = "Map to a region specific AMI"
}

###
# Consul
###

variable "dc_name" {
  type        = string
  default     = "dc1"
  description = "The datacenter for Consul / Nomad."
}

###
# Nomad
###

variable "base_nomad_ami" {
  type    = string
  default = ""
}

###
# Network
###

variable "vpc_id" {
  type = string
}
variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type        = set(string)
  description = "Security groups required for SSH provisioning and external network access."
}

###
# EC2
###

# Build instance type
variable "instance_type" {
  type    = string
  default = "t3.small"
}
