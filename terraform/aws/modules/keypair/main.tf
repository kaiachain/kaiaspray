resource "tls_private_key" "this" {
  count = var.create_aws_key_pair == true ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "this" {
  count = var.create_aws_key_pair == true ? 1 : 0

  key_name   = var.name
  public_key = tls_private_key.this[0].public_key_openssh

  tags = local.default_tags
}

resource "local_sensitive_file" "this" {
  count = var.create_aws_key_pair == true ? 1 : 0

  content         = tls_private_key.this[0].private_key_openssh
  filename        = var.ssh_private_key_path
  file_permission = "0400"
}

locals {
  # Use the appropriate key and public key based on configuration
  private_key_path = var.create_aws_key_pair ? basename(var.ssh_private_key_path) : var.ssh_existing_private_key_path
  public_key = var.create_aws_key_pair ? tls_private_key.this[0].public_key_openssh : file(var.ssh_existing_public_key_path)
}
