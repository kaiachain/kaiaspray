module "vpc" {
  count = var.network == "" ? 1 : 0 # create vpc only if network is not provided

  source  = "terraform-google-modules/network/google"
  version = "~> 11.1" # 18.x rejects this configuration

  project_id   = var.project_id
  network_name = local.name

  subnets = [
    {
      subnet_name   = format("%s-public-subnet", local.name)
      subnet_ip     = "10.1.101.0/24"
      subnet_region = var.gcp_region
    },
    {
      subnet_name           = format("%s-private-subnet", local.name)
      subnet_ip             = "10.1.1.0/24"
      subnet_region         = var.gcp_region
      subnet_private_access = "true"
    },
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
  ]
}

# reference the VPC and Subnet
locals {
  network_self_link    = var.network != "" ? var.network : length(module.vpc) > 0 ? module.vpc[0].network_self_link : ""
  subnetwork_self_link = var.subnetwork != "" ? var.subnetwork : length(module.vpc) > 0 ? [for item in module.vpc[0].subnets_self_links : item if can(regex("public", item))][0] : ""
}