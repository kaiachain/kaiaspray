output "key_name" {
  value = var.create_aws_key_pair ? aws_key_pair.this[0].key_name : local.existing_key_name
}

output "key_pair_name" {
  value = var.name
}

output "ssh_public_key" {
  value = local.public_key
}

output "ssh_private_key_path" {
  value = var.create_aws_key_pair ? local_sensitive_file.this[0].filename : var.ssh_existing_private_key_path
}

output "ssh_key_file_created" {
  value = var.create_aws_key_pair ? local_sensitive_file.this[0].id : "existing_key"
}
