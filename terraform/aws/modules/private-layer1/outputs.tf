output "cn" {
  value = module.cn
}

output "pn" {
  value = module.pn
}

output "en" {
  value = module.en
}

output "monitor" {
  value = module.monitor
}

output "layer1_sg_id" {
  value = var.security_group_id != null ? var.security_group_id : aws_security_group.layer1[0].id
}
