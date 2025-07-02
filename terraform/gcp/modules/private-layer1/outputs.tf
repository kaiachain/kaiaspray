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

# Outputs for testing locals
output "defaults" {
  value = local.defaults
}

output "get_cn_node_options" {
  value = local.get_cn_node_options
}

output "get_pn_node_options" {
  value = local.get_pn_node_options
}

output "get_en_node_options" {
  value = local.get_en_node_options
}

output "monitor_options" {
  value = local.monitor_options
}
