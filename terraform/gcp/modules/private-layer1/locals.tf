locals {
  # Default values
  defaults = {
    machine_type      = "n2-standard-2"
    boot_disk_size    = 100
    compute_disk_size = null
    snapshot_id       = null
  }

  # Machine series that only support Hyperdisk (and gVNIC), e.g. c4-highmem-4, n4-standard-2
  hyperdisk_only = "^(c4|n4)"

  # Node options that apply to every node type:
  #   spot                     true: a Spot VM that stops (keeping its disks) when it is preempted
  #   boot_disk_type           default: hyperdisk-balanced on Hyperdisk-only machines, otherwise the GCP default
  #   compute_disk_type        default: hyperdisk-balanced on Hyperdisk-only machines, otherwise pd-ssd
  #   compute_disk_iops        Hyperdisk only; default: GCP's for the disk size
  #   compute_disk_throughput  Hyperdisk only (MiB/s); default: GCP's for the disk size
  monitor_options_raw = {
    machine_type            = lookup(var.monitor_options, "machine_type", local.defaults.machine_type)
    boot_disk_size          = lookup(var.monitor_options, "boot_disk_size", local.defaults.boot_disk_size)
    compute_disk_size       = lookup(var.monitor_options, "compute_disk_size", local.defaults.compute_disk_size)
    snapshot_id             = lookup(var.monitor_options, "snapshot_id", local.defaults.snapshot_id)
    spot                    = lookup(var.monitor_options, "spot", false)
    boot_disk_type          = lookup(var.monitor_options, "boot_disk_type", null)
    compute_disk_type       = lookup(var.monitor_options, "compute_disk_type", null)
    compute_disk_iops       = lookup(var.monitor_options, "compute_disk_iops", null)
    compute_disk_throughput = lookup(var.monitor_options, "compute_disk_throughput", null)
  }

  # Generate node options lists - can be used like get_cn_node_options[0]
  cn_node_options_raw = [
    for i in range(lookup(var.cn_options, "count", 0)) : {
      machine_type            = try(lookup(var.cn_options, "options", {})[tostring(i)].machine_type, lookup(var.cn_options, "machine_type", local.defaults.machine_type))
      boot_disk_size          = try(lookup(var.cn_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.cn_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size       = try(lookup(var.cn_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.cn_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id             = try(lookup(var.cn_options, "options", {})[tostring(i)].snapshot_id, lookup(var.cn_options, "snapshot_id", local.defaults.snapshot_id))
      service_account         = try(lookup(var.cn_options, "options", {})[tostring(i)].service_account, lookup(var.cn_options, "service_account", null))
      spot                    = try(lookup(var.cn_options, "options", {})[tostring(i)].spot, lookup(var.cn_options, "spot", false))
      boot_disk_type          = try(lookup(var.cn_options, "options", {})[tostring(i)].boot_disk_type, lookup(var.cn_options, "boot_disk_type", null))
      compute_disk_type       = try(lookup(var.cn_options, "options", {})[tostring(i)].compute_disk_type, lookup(var.cn_options, "compute_disk_type", null))
      compute_disk_iops       = try(lookup(var.cn_options, "options", {})[tostring(i)].compute_disk_iops, lookup(var.cn_options, "compute_disk_iops", null))
      compute_disk_throughput = try(lookup(var.cn_options, "options", {})[tostring(i)].compute_disk_throughput, lookup(var.cn_options, "compute_disk_throughput", null))
    }
  ]

  pn_node_options_raw = [
    for i in range(lookup(var.pn_options, "count", 0)) : {
      machine_type            = try(lookup(var.pn_options, "options", {})[tostring(i)].machine_type, lookup(var.pn_options, "machine_type", local.defaults.machine_type))
      boot_disk_size          = try(lookup(var.pn_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.pn_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size       = try(lookup(var.pn_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.pn_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id             = try(lookup(var.pn_options, "options", {})[tostring(i)].snapshot_id, lookup(var.pn_options, "snapshot_id", local.defaults.snapshot_id))
      service_account         = try(lookup(var.pn_options, "options", {})[tostring(i)].service_account, lookup(var.pn_options, "service_account", null))
      spot                    = try(lookup(var.pn_options, "options", {})[tostring(i)].spot, lookup(var.pn_options, "spot", false))
      boot_disk_type          = try(lookup(var.pn_options, "options", {})[tostring(i)].boot_disk_type, lookup(var.pn_options, "boot_disk_type", null))
      compute_disk_type       = try(lookup(var.pn_options, "options", {})[tostring(i)].compute_disk_type, lookup(var.pn_options, "compute_disk_type", null))
      compute_disk_iops       = try(lookup(var.pn_options, "options", {})[tostring(i)].compute_disk_iops, lookup(var.pn_options, "compute_disk_iops", null))
      compute_disk_throughput = try(lookup(var.pn_options, "options", {})[tostring(i)].compute_disk_throughput, lookup(var.pn_options, "compute_disk_throughput", null))
    }
  ]

  en_node_options_raw = [
    for i in range(lookup(var.en_options, "count", 0)) : {
      machine_type            = try(lookup(var.en_options, "options", {})[tostring(i)].machine_type, lookup(var.en_options, "machine_type", local.defaults.machine_type))
      boot_disk_size          = try(lookup(var.en_options, "options", {})[tostring(i)].boot_disk_size, lookup(var.en_options, "boot_disk_size", local.defaults.boot_disk_size))
      compute_disk_size       = try(lookup(var.en_options, "options", {})[tostring(i)].compute_disk_size, lookup(var.en_options, "compute_disk_size", local.defaults.compute_disk_size))
      snapshot_id             = try(lookup(var.en_options, "options", {})[tostring(i)].snapshot_id, lookup(var.en_options, "snapshot_id", local.defaults.snapshot_id))
      service_account         = try(lookup(var.en_options, "options", {})[tostring(i)].service_account, lookup(var.en_options, "service_account", null))
      spot                    = try(lookup(var.en_options, "options", {})[tostring(i)].spot, lookup(var.en_options, "spot", false))
      boot_disk_type          = try(lookup(var.en_options, "options", {})[tostring(i)].boot_disk_type, lookup(var.en_options, "boot_disk_type", null))
      compute_disk_type       = try(lookup(var.en_options, "options", {})[tostring(i)].compute_disk_type, lookup(var.en_options, "compute_disk_type", null))
      compute_disk_iops       = try(lookup(var.en_options, "options", {})[tostring(i)].compute_disk_iops, lookup(var.en_options, "compute_disk_iops", null))
      compute_disk_throughput = try(lookup(var.en_options, "options", {})[tostring(i)].compute_disk_throughput, lookup(var.en_options, "compute_disk_throughput", null))
    }
  ]

  # Disk types and NIC by machine series, unless set explicitly
  monitor_options = merge(local.monitor_options_raw, {
    boot_disk_type    = local.monitor_options_raw.boot_disk_type != null ? local.monitor_options_raw.boot_disk_type : (can(regex(local.hyperdisk_only, local.monitor_options_raw.machine_type)) ? "hyperdisk-balanced" : null)
    compute_disk_type = local.monitor_options_raw.compute_disk_type != null ? local.monitor_options_raw.compute_disk_type : (can(regex(local.hyperdisk_only, local.monitor_options_raw.machine_type)) ? "hyperdisk-balanced" : "pd-ssd")
    nic_type          = can(regex(local.hyperdisk_only, local.monitor_options_raw.machine_type)) ? "GVNIC" : null
  })

  get_cn_node_options = [
    for o in local.cn_node_options_raw : merge(o, {
      boot_disk_type    = o.boot_disk_type != null ? o.boot_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : null)
      compute_disk_type = o.compute_disk_type != null ? o.compute_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : "pd-ssd")
      nic_type          = can(regex(local.hyperdisk_only, o.machine_type)) ? "GVNIC" : null
    })
  ]

  get_pn_node_options = [
    for o in local.pn_node_options_raw : merge(o, {
      boot_disk_type    = o.boot_disk_type != null ? o.boot_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : null)
      compute_disk_type = o.compute_disk_type != null ? o.compute_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : "pd-ssd")
      nic_type          = can(regex(local.hyperdisk_only, o.machine_type)) ? "GVNIC" : null
    })
  ]

  get_en_node_options = [
    for o in local.en_node_options_raw : merge(o, {
      boot_disk_type    = o.boot_disk_type != null ? o.boot_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : null)
      compute_disk_type = o.compute_disk_type != null ? o.compute_disk_type : (can(regex(local.hyperdisk_only, o.machine_type)) ? "hyperdisk-balanced" : "pd-ssd")
      nic_type          = can(regex(local.hyperdisk_only, o.machine_type)) ? "GVNIC" : null
    })
  ]
}
