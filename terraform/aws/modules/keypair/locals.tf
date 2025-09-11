locals {
  default_tags = merge(
    var.tags,
    {
      Name      = var.name
      ManagedBy = "terraform"
    }
  )
  
  # Extract key name from existing private key path
  existing_key_name = var.create_aws_key_pair ? var.name : replace(basename(var.ssh_existing_private_key_path), ".pem", "")
}

