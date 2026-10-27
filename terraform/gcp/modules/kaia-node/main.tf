resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    initialize_params {
      image = lookup(var.boot_disk, "image_id", data.google_compute_image.this.family)
      size  = lookup(var.boot_disk, "boot_disk_size", 20)
      type  = lookup(var.boot_disk, "type", null)
    }
  }

  dynamic "attached_disk" {
    for_each = var.compute_disk != null ? [1] : []

    content {
      source      = google_compute_disk.this[0].self_link
      device_name = lookup(var.compute_disk, "name", "data-disk")
    }

  }

  dynamic "service_account" {
    for_each = var.service_account != null ? [1] : []

    content {
      email  = lookup(var.service_account, "email", null)
      scopes = lookup(var.service_account, "scopes", ["default"])
    }
  }

  # Spot: GCP may stop the VM at any time; STOP (not DELETE) keeps its disks so it can be started again
  dynamic "scheduling" {
    for_each = var.spot ? [1] : []

    content {
      provisioning_model          = "SPOT"
      preemptible                 = true
      automatic_restart           = false
      instance_termination_action = "STOP"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    nic_type   = var.nic_type

    dynamic "access_config" {
      for_each = var.use_public_ip == true ? [1] : []

      content {
        nat_ip       = google_compute_address.this[0].address
        network_tier = var.network_tier
      }
    }
  }

  tags = var.tags
  metadata = merge(
    var.metadata,
  )

  # A node stays in its zone when the zone list changes (e.g. a zone out of a machine type is left out): only new nodes follow it
  lifecycle {
    ignore_changes = [zone]
  }
}

resource "google_compute_disk" "this" {
  count = var.compute_disk != null ? 1 : 0

  name     = lookup(var.compute_disk, "name", null)
  type     = lookup(var.compute_disk, "type", null)
  zone     = lookup(var.compute_disk, "zone", null)
  size     = lookup(var.compute_disk, "size", null)
  snapshot = lookup(var.compute_disk, "snapshot", null)

  # Hyperdisk only
  provisioned_iops       = lookup(var.compute_disk, "iops", null)
  provisioned_throughput = lookup(var.compute_disk, "throughput", null)

  lifecycle {
    ignore_changes = [zone] # stays with its node (see google_compute_instance.this)
  }
}

resource "google_compute_address" "this" {
  count = var.use_public_ip ? 1 : 0

  name         = format("%s-ip", var.name)
  region       = var.region != null ? var.region : "asia-southeast1"
  network_tier = var.network_tier
}
