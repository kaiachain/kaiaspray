resource "aws_security_group" "layer1" {
  count = var.security_group_id == null ? 1 : 0
  
  name = format("%s-private-layer1-sg", var.name)

  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = [
      { protocol = "tcp", from_port = 22, to_port = 22, cidr_blocks = var.ssh_client_ips },
      { protocol = "tcp", from_port = 8551, to_port = 8551, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 32323, to_port = 32324, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "udp", from_port = 32323, to_port = 32323, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 50505, to_port = 50505, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 61001, to_port = 61001, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 9090, to_port = 9090, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 3000, to_port = 3000, cidr_blocks = ["0.0.0.0/0"] },
    ]

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
      self            = try(ingress.value.self, null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

