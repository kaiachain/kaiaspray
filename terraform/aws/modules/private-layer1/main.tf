module "cn" {
  count = local.cn_options.count

  source = "../kaia-node"

  name               = format("%s-cn-%d", var.name, count.index + 1)
  ami_id             = var.ami_id
  instance_type      = local.cn_options.instance_type
  key_name           = var.key_name
  security_group_id = var.security_group_id != null && var.security_group_id != "" ? var.security_group_id : aws_security_group.layer1[0].id
  subnet_id          = var.subnet_ids[count.index % length(var.subnet_ids)]

  root_block_device = {
    volume_type = "gp2"
    volume_size = local.cn_options.ebs_volume_size
  }

  tags = local.default_tags
}

module "pn" {
  count = local.pn_options.count

  source = "../kaia-node"

  name               = format("%s-pn-%d", var.name, count.index + 1)
  ami_id             = var.ami_id
  instance_type      = local.pn_options.instance_type
  key_name           = var.key_name
  security_group_id = var.security_group_id != null && var.security_group_id != "" ? var.security_group_id : aws_security_group.layer1[0].id
  subnet_id          = var.subnet_ids[count.index % length(var.subnet_ids)]

  root_block_device = {
    volume_type = "gp2"
    volume_size = local.cn_options.ebs_volume_size
  }

  tags = local.default_tags
}

module "en" {
  count = local.en_options.count

  source = "../kaia-node"

  name               = format("%s-en-%d", var.name, count.index + 1)
  ami_id             = var.ami_id
  instance_type      = local.en_options.instance_type
  key_name           = var.key_name
  security_group_id = var.security_group_id != null && var.security_group_id != "" ? var.security_group_id : aws_security_group.layer1[0].id
  subnet_id          = var.subnet_ids[count.index % length(var.subnet_ids)]

  root_block_device = {
    volume_type = "gp2"
    volume_size = local.cn_options.ebs_volume_size
  }

  tags = local.default_tags
}

module "monitor" {
  source = "../kaia-node"

  name               = format("%s-monitor", var.name)
  ami_id             = var.ami_id
  instance_type      = local.monitor_options.instance_type
  key_name           = var.key_name
  security_group_id = var.security_group_id != null && var.security_group_id != "" ? var.security_group_id : aws_security_group.layer1[0].id
  subnet_id          = var.subnet_ids[0]

  root_block_device = {
    volume_type = "gp2"
    volume_size = local.monitor_options.ebs_volume_size
  }

  tags = local.default_tags
}
