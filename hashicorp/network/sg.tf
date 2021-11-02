locals {
  #trusted_cidr = ["108.18.128.147/32"]
  trusted_cidrs = ["34.198.34.166/32", "52.55.22.144/32"]

  #  HTTP, HTTPS
  consul_http_ports = ["8500", "8501"]

  consul_ports = ["8600", "8500", "8501", "8301", "8302", "8300"]
}

#NOTE: Uncomment for VPN
#SG for Client VPN Network Interfaces

resource "aws_security_group" "ssh" {
  name        = "ssh-from-trusted"
  description = "Allow SSH from trusted IP"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name" = "ssh-from-trusted"
  }
}

resource "aws_security_group_rule" "ssh_ingress" {
  security_group_id = aws_security_group.ssh.id
  type              = "ingress"

  description = "SSH from Trusted"
  cidr_blocks = local.trusted_cidrs

  from_port = 22
  to_port   = 22
  protocol  = "TCP"
}

resource "aws_security_group_rule" "ssh_egress" {
  security_group_id = aws_security_group.ssh.id
  type              = "egress"

  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 0
  protocol    = "all"
}

###
# Nomad
###

resource "aws_security_group" "nomad" {
  name        = "nomad-sg"
  description = "Allow HTTP inbound traffic for Nomad"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name" = "nomad-sg"
  }
}

# HTTP Access
resource "aws_security_group_rule" "http_nomad" {
  security_group_id = aws_security_group.nomad.id
  type              = "ingress"

  cidr_blocks = local.trusted_cidrs
  description = "HTTP from Trusted"

  from_port = 4646
  to_port   = 4646
  protocol  = "tcp"
}

# RPC Access
resource "aws_security_group_rule" "rpc_nomad" {
  security_group_id = aws_security_group.nomad.id
  type              = "ingress"

  cidr_blocks = [var.vpc_cidr]
  description = "RPC from VPC"

  from_port = 4647
  to_port   = 4647
  protocol  = "tcp"
}

# Gossip Access (LAN)
resource "aws_security_group_rule" "gossip_nomad" {
  for_each = toset(["tcp", "udp"])

  security_group_id = aws_security_group.nomad.id
  type              = "ingress"

  cidr_blocks = [var.vpc_cidr]
  description = "Gossip (Serf) to 4648 from VPC"

  from_port = 4648
  to_port   = 4648
  protocol  = each.key
}

# TCP Ports for HTTP workloads to bind to
resource "aws_security_group_rule" "workload_nomad" {
  security_group_id = aws_security_group.nomad.id
  type              = "ingress"

  cidr_blocks = concat([var.vpc_cidr], local.trusted_cidrs)
  description = "Nomad workload TCP Ports"

  from_port = 8000
  to_port   = 8100
  protocol  = "tcp"
}

# TCP Ports for HTTP additional workloads to bind to
resource "aws_security_group_rule" "workload_two_nomad" {
  security_group_id = aws_security_group.nomad.id
  type              = "ingress"

  cidr_blocks = concat([var.vpc_cidr], local.trusted_cidrs)
  description = "Nomad additional workload TCP Ports"

  from_port = 9000
  to_port   = 9100
  protocol  = "tcp"
}

###
# Consul
###
resource "aws_security_group" "consul" {
  name        = "consul-sg"
  description = "Allow required ports for Consul"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "Name" = "consul-sg"
  }
}


# HTTP Access from Trusted
resource "aws_security_group_rule" "http_consul" {
  for_each = toset(local.consul_http_ports)

  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = local.trusted_cidrs
  description = "TCP to ${each.key} from Trusted"

  from_port = each.key
  to_port   = each.key
  protocol  = "tcp"
}

# gRPC Access from Trusted & VPC
resource "aws_security_group_rule" "grpc_consul" {
  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = concat([var.vpc_cidr], local.trusted_cidrs)
  description = "gRPC from Trusted & VPC"

  from_port = 8502
  to_port   = 8502
  protocol  = "tcp"
}

# DNS Access from within VPC
resource "aws_security_group_rule" "dns_consul" {
  for_each = toset(["tcp", "udp"])

  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = concat([var.vpc_cidr], local.trusted_cidrs)
  description = "DNS to 8600 from VPC"

  from_port = 8600
  to_port   = 8600
  protocol  = each.key
}

# Gossip Access (LAN)
# NOTE: Not allowing for WAN Gossip, as this demo is only focused on 1 DC
resource "aws_security_group_rule" "gossip_consul" {
  for_each = toset(["tcp", "udp"])

  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = [var.vpc_cidr]
  description = "Gossip (Serf) to 8301 from VPC"

  from_port = 8301
  to_port   = 8301
  protocol  = each.key
}

resource "aws_security_group_rule" "rpc_consul" {
  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = [var.vpc_cidr]
  description = "Server RPC to 8300 from VPC"

  from_port = 8300
  to_port   = 8300
  protocol  = "tcp"
}


resource "aws_security_group_rule" "sidecar_consul" {
  security_group_id = aws_security_group.consul.id
  type              = "ingress"

  cidr_blocks = [var.vpc_cidr]
  description = "Consul Connect Sidecar Min - Sidecar Max Ports"

  from_port = 20000
  to_port   = 32000
  protocol  = "tcp"
}

