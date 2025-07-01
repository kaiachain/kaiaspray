locals {
  # Default values
  defaults = {
    machine_type = "n2-standard-2"
    boot_disk_size = 100
    compute_disk_size = null
    snapshot_id = null
  }

  monitor_options = {
    machine_type   = lookup(var.monitor_options, "machine_type", local.defaults.machine_type)
    boot_disk_size = lookup(var.monitor_options, "boot_disk_size", local.defaults.boot_disk_size)
    compute_disk_size = lookup(var.monitor_options, "compute_disk_size", local.defaults.compute_disk_size)
    snapshot_id = lookup(var.monitor_options, "snapshot_id", local.defaults.snapshot_id)
  }

  # Generate node options lists - can be used like get_cn_node_options[0]
  get_cn_node_options = [
    for i in range(lookup(var.cn_options, "count", 0)) : {
      machine_type = try(lookup(var.cn_options, "options", {})[tostring(i)].machine_type, lookup(var.cn_options, "machine_type", local.defaults.machine_type))
      boot_disk_size = try(lookup(var.cn_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.cn_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size = try(lookup(var.cn_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.cn_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id = try(lookup(var.cn_options, "options", {})[tostring(i)].snapshot_id, lookup(var.cn_options, "snapshot_id", local.defaults.snapshot_id))
    }
  ]

  get_pn_node_options = [
    for i in range(lookup(var.pn_options, "count", 0)) : {
      machine_type = try(lookup(var.pn_options, "options", {})[tostring(i)].machine_type, lookup(var.pn_options, "machine_type", local.defaults.machine_type))
      boot_disk_size = try(lookup(var.pn_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.pn_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size = try(lookup(var.pn_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.pn_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id = try(lookup(var.pn_options, "options", {})[tostring(i)].snapshot_id, lookup(var.pn_options, "snapshot_id", local.defaults.snapshot_id))
    }
  ]

  get_en_node_options = [
    for i in range(lookup(var.en_options, "count", 0)) : {
      machine_type = try(lookup(var.en_options, "options", {})[tostring(i)].machine_type, lookup(var.en_options, "machine_type", local.defaults.machine_type))
      boot_disk_size = try(lookup(var.en_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.en_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size = try(lookup(var.en_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.en_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id = try(lookup(var.en_options, "options", {})[tostring(i)].snapshot_id, lookup(var.en_options, "snapshot_id", local.defaults.snapshot_id))
    }
  ]
}
