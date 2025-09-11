module "keypair" {
  source = "../modules/keypair"

  name                 = var.key_name == null ? local.name : var.key_name
  create_aws_key_pair  = var.create_aws_key_pair
  ssh_private_key_path = format("%s/../../../private-ssh-key.pem", path.module)

  tags = var.tags
}

resource "aws_security_group" "layer2" {
  name = format("%s-layer2-sg", local.name)

  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [
      { protocol = "tcp", from_port = 22, to_port = 22, cidr_blocks = var.ssh_client_ips },
      { protocol = "tcp", from_port = 32323, to_port = 32324, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "udp", from_port = 32323, to_port = 32323, cidr_blocks = ["0.0.0.0/0"] },
      { protocol = "tcp", from_port = 32323, to_port = 32324, self = true },
      { protocol = "udp", from_port = 32323, to_port = 32323, self = true },
      { protocol = "tcp", from_port = 61001, to_port = 61001, security_groups = [module.layer1.layer1_sg_id] },
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
