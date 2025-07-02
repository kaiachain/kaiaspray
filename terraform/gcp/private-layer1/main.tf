module "layer1" {
  source = "../modules/private-layer1"

  name       = local.name
  zone_list  = data.google_compute_zones.this.names
  network    = local.network_self_link
  subnetwork = local.subnetwork_self_link
  project_id = var.project_id
  network_tags = var.network_tags
  gcp_region = var.gcp_region
  network_tier = "STANDARD"  # Use STANDARD tier instead of PREMIUM
  create_gcp_firewall_rules = var.create_gcp_firewall_rules

  boot_image_id  = data.google_compute_image.this.self_link
  ssh_client_ips = var.ssh_client_ips
  user_name      = var.user_name
  ssh_private_key_path = module.keypair.ssh_private_key_path

  cn_options      = var.cn_options
  pn_options      = var.pn_options
  en_options      = var.en_options
  monitor_options = var.monitor_options

  metadata = merge(
    var.metadata,
    {
      Name      = local.name
      ManagedBy = "terraform"
      ssh-keys  = format("%s:%s %s", var.user_name, trimspace(module.keypair.ssh_public_key), var.user_name)
    }
  )
}
