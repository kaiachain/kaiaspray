resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    auto_delete = true
    initialize_params {
      image = lookup(var.boot_disk, "image_id", data.google_compute_image.this.family)
      size  = lookup(var.boot_disk, "boot_disk_size", 20)
    }
  }

  dynamic "attached_disk" {
    for_each = var.compute_disk != null ? [1] : []

    content {
      source      = google_compute_disk.this[0].self_link
      device_name = lookup(var.compute_disk, "name", "data-disk")
    }
  }

  network_interface {
    subnetwork = var.subnetwork

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
}

resource "google_compute_disk" "this" {
  count = var.compute_disk != null ? 1 : 0

  name     = lookup(var.compute_disk, "name", null)
  type     = lookup(var.compute_disk, "type", null)
  zone     = lookup(var.compute_disk, "zone", null)
  size     = lookup(var.compute_disk, "size", null)
  snapshot = lookup(var.compute_disk, "snapshot", null)
}

resource "google_compute_address" "this" {
  count = var.use_public_ip ? 1 : 0

  name         = format("%s-ip", var.name)
  region       = var.region != null ? var.region : "asia-southeast1"
  network_tier = var.network_tier
}
