locals {
  ansible_inventory = templatefile(
    "${path.module}/templates/inventory.tftpl",
    {
      ansible_ssh_private_key_file = try(module.keypair.ssh_private_key_path, "<change-me>")
      en                           = try(module.en, [])
      scn                          = try(module.scn, [])
    }
  )
  ansible_vars_all = templatefile(
    "${path.module}/templates/groupvarsall.tftpl",
    {
      homi_output_dir = var.deploy_options.homi_output_dir
      kaia_rewardbase = var.deploy_options.kaia_rewardbase
      kaia_install_mode = var.deploy_options.kaia_install_mode
      kaia_version = var.deploy_options.kaia_version
      kaia_build_docker_base_image = var.deploy_options.kaia_build_docker_base_image
      kaia_build_remote_git_url = var.deploy_options.kaia_build_remote_git_url
      kaia_build_remote_git_branch = var.deploy_options.kaia_build_remote_git_branch
    }
  )
  ansible_vars_en = templatefile(
    "${path.module}/templates/groupvarsen.tftpl",
    {
      kaia_node_type = "en"
      kaia_chaindata_timestamp = var.deploy_options.kaia_chaindata_timestamp
      kaia_bridge_enabled = var.deploy_options.kaia_bridge_enabled
      kaia_conf_override_en = var.deploy_options.kaia_conf_override_en
    }
  )
  ansible_vars_scn = templatefile(
    "${path.module}/templates/groupvarsscn.tftpl",
    {
      kaia_node_type = "scn"
      kaia_service_parent_chain_id = var.deploy_options.kaia_service_parent_chain_id
      kaia_service_network_id = var.deploy_options.kaia_service_network_id
      kaia_service_chain_id = var.deploy_options.kaia_service_chain_id
      kaia_conf_override_scn = merge(
        var.deploy_options.kaia_conf_override_scn,
        {
          NETWORK_ID = tostring(var.deploy_options.kaia_service_network_id)
        }
      )
    }
  )
}

resource "local_file" "this" {
  content  = local.ansible_inventory
  filename = format("%s/../../../inventory/%s/inventory.ini", path.module, basename(abspath(path.module)))
}

resource "local_file" "ansible_group_vars_all" {
  content  = local.ansible_vars_all
  filename = format("%s/../../../inventory/%s/group_vars/all/all.yml", path.module, basename(abspath(path.module)))
}

resource "local_file" "ansible_group_vars_en" {
  content  = local.ansible_vars_en
  filename = format("%s/../../../inventory/%s/group_vars/en.yml", path.module, basename(abspath(path.module)))
}

resource "local_file" "ansible_group_vars_scn" {
  content  = local.ansible_vars_scn
  filename = format("%s/../../../inventory/%s/group_vars/scn.yml", path.module, basename(abspath(path.module)))
}
