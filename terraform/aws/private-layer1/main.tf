module "layer1" {
  source = "../modules/private-layer1"

  name = local.name

  aws_region = var.aws_region
  vpc_id     = var.vpc_id != null ? var.vpc_id : module.vpc[0].vpc_id
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : module.vpc[0].public_subnets
  security_group_id = var.security_group_id

  ami_id         = data.aws_ami.this.id
  key_name       = local.key_name
  ssh_client_ips = var.ssh_client_ips

  cn_options      = var.cn_options
  pn_options      = var.pn_options
  en_options      = var.en_options
  monitor_options = var.monitor_options

  tags = var.tags
}
