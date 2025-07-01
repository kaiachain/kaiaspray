module "cn" {
  count = length(local.get_cn_node_options)

  source = "../kaia-node"

  name         = format("%s-cn-%d", var.name, count.index + 1)
  
  # Get node settings with index-based overrides
  machine_type = local.get_cn_node_options[count.index].machine_type

  subnetwork    = var.subnetwork
  zone          = var.zone_list[count.index % length(var.zone_list)]
  use_public_ip = true
  region        = var.gcp_region
  network_tier  = var.network_tier

  boot_disk = {
    image_id       = var.boot_image_id
    boot_disk_size = local.get_cn_node_options[count.index].boot_disk_size
  }

  compute_disk = local.get_cn_node_options[count.index].compute_disk_size != null ? {
    name        = format("%s-cn-%d-disk", var.name, count.index + 1)
    type        = "pd-ssd"
    zone        = var.zone_list[count.index % length(var.zone_list)]
    size        = local.get_cn_node_options[count.index].compute_disk_size
    snapshot    = local.get_cn_node_options[count.index].snapshot_id
  } : null

  tags = length(var.network_tags) > 0 ? concat(var.network_tags) : ["kaiaspray", "cn"]

  metadata = merge(var.metadata, {
    Name = format("%s-cn-%d", var.name, count.index + 1)
  })
}

module "pn" {
  count = length(local.get_pn_node_options)

  source = "../kaia-node"

  name         = format("%s-pn-%d", var.name, count.index + 1)
  
  # Get node settings with index-based overrides
  machine_type = local.get_pn_node_options[count.index].machine_type

  subnetwork    = var.subnetwork
  zone          = var.zone_list[count.index % length(var.zone_list)]
  use_public_ip = true
  region        = var.gcp_region
  network_tier  = var.network_tier

  boot_disk = {
    image_id       = var.boot_image_id
    boot_disk_size = local.get_pn_node_options[count.index].boot_disk_size
  }

  compute_disk = local.get_pn_node_options[count.index].compute_disk_size != null ? {
    name = format("%s-pn-%d-disk", var.name, count.index + 1)
    type = "pd-ssd"
    zone = var.zone_list[count.index % length(var.zone_list)]
    size = local.get_pn_node_options[count.index].compute_disk_size
    snapshot = local.get_pn_node_options[count.index].snapshot_id
  } : null

  tags = length(var.network_tags) > 0 ? concat(var.network_tags) : ["kaiaspray", "pn"]

  metadata = merge(var.metadata, {
    Name = format("%s-pn-%d", var.name, count.index + 1)
  })
}

module "en" {
  count = length(local.get_en_node_options)

  source = "../kaia-node"

  name         = format("%s-en-%d", var.name, count.index + 1)
  
  # Get node settings with index-based overrides
  machine_type = local.get_en_node_options[count.index].machine_type

  subnetwork    = var.subnetwork
  zone          = var.zone_list[count.index % length(var.zone_list)]
  use_public_ip = true
  region        = var.gcp_region
  network_tier  = var.network_tier

  boot_disk = {
    image_id       = var.boot_image_id
    boot_disk_size = local.get_en_node_options[count.index].boot_disk_size
  }

  compute_disk = local.get_en_node_options[count.index].compute_disk_size != null ? {
    name = format("%s-en-%d-disk", var.name, count.index + 1)
    type = "pd-ssd"
    zone = var.zone_list[count.index % length(var.zone_list)]
    size = local.get_en_node_options[count.index].compute_disk_size
    snapshot = local.get_en_node_options[count.index].snapshot_id
  } : null

  tags = length(var.network_tags) > 0 ? concat(var.network_tags) : ["kaiaspray", "en"]

  metadata = merge(var.metadata, {
    Name = format("%s-en-%d", var.name, count.index + 1)
  })
}

module "monitor" {
  source = "../kaia-node"

  name         = format("%s-monitor", var.name)
  machine_type = local.monitor_options.machine_type

  subnetwork    = var.subnetwork
  zone          = var.zone_list[0]
  use_public_ip = true
  region        = var.gcp_region
  network_tier  = var.network_tier

  boot_disk = {
    image_id       = var.boot_image_id
    boot_disk_size = local.monitor_options.boot_disk_size
  }

  compute_disk = try(local.monitor_options.compute_disk_size, null) != null ? {
    name = format("%s-monitor-disk", var.name)
    type = "pd-ssd"
    zone = var.zone_list[0]
    size = local.monitor_options.compute_disk_size
    snapshot = try(local.monitor_options.snapshot_id, null)
  } : null

  tags = length(var.network_tags) > 0 ? var.network_tags : ["kaiaspray", "monitor"]

  metadata = merge(var.metadata, {
    Name = format("%s-monitor", var.name)
  })
}

# Provisioner for CN nodes with compute disk
resource "null_resource" "cn_disk_mount" {
  for_each = {
    for idx, options in local.get_cn_node_options : idx => options
    if options.compute_disk_size != null
  }

  triggers = {
    instance_id = module.cn[each.key].instance_link
  }

  provisioner "file" {
    source   = "${path.module}/mount_disk.sh"
    destination = "/tmp/mount_disk.sh"

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.cn[each.key].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mount_disk.sh",
      "sudo /tmp/mount_disk.sh ${format("%s-cn-%d-disk", var.name, each.key + 1)} kcnd"
    ]

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.cn[each.key].public_ip
    }
  }
}

# Provisioner for PN nodes with compute disk
resource "null_resource" "pn_disk_mount" {
  for_each = {
    for idx, options in local.get_pn_node_options : idx => options
    if options.compute_disk_size != null
  }

  triggers = {
    instance_id = module.pn[each.key].instance_link
  }

  provisioner "file" {
    source   = "${path.module}/mount_disk.sh"
    destination = "/tmp/mount_disk.sh"

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.pn[each.key].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mount_disk.sh",
      "sudo /tmp/mount_disk.sh ${format("%s-pn-%d-disk", var.name, each.key + 1)} kpnd"
    ]

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.pn[each.key].public_ip
    }
  }
}

# Provisioner for EN nodes with compute disk
resource "null_resource" "en_disk_mount" {
  for_each = {
    for idx, options in local.get_en_node_options : idx => options
    if options.compute_disk_size != null
  }

  triggers = {
    instance_id = module.en[each.key].instance_link
  }

  provisioner "file" {
    source   = "${path.module}/mount_disk.sh"
    destination = "/tmp/mount_disk.sh"

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.en[each.key].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mount_disk.sh",
      "sudo /tmp/mount_disk.sh ${format("%s-en-%d-disk", var.name, each.key + 1)} kend"
    ]

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.en[each.key].public_ip
    }
  }
}

# Provisioner for Monitor node with compute disk
resource "null_resource" "monitor_disk_mount" {
  count = try(local.monitor_options.compute_disk_size, null) != null ? 1 : 0

  triggers = {
    instance_id = module.monitor.instance_link
  }

  provisioner "file" {
    source   = "${path.module}/mount_disk.sh"
    destination = "/tmp/mount_disk.sh"

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.monitor.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mount_disk.sh",
      "sudo /tmp/mount_disk.sh ${format("%s-monitor-disk", var.name)} monitor"
    ]

    connection {
      type        = "ssh"
      user        = var.user_name
      private_key = file(var.ssh_private_key_path)
      host        = module.monitor.public_ip
    }
  }
}
