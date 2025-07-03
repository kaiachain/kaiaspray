locals {
  ansible_inventory = templatefile(
    "${path.module}/templates/inventory.tftpl",
    {
      ansible_ssh_private_key_file = try(module.keypair.ssh_private_key_path, "<change-me>")
      cn                           = try(module.layer1.cn, [])
      pn                           = try(module.layer1.pn, [])
      en                           = try(module.layer1.en, [])
      monitor                      = try(module.layer1.monitor, {})
    }
  )
    ansible_vars = templatefile(
    "${path.module}/templates/groupvarsall.tftpl",
    {
      kaia_install_mode = var.deploy_options.kaia_install_mode
      kaia_version      = var.deploy_options.kaia_version
      kaia_build_docker_base_image = var.deploy_options.kaia_build_docker_base_image
      kaia_build_remote_git_url = var.deploy_options.kaia_build_remote_git_url
      kaia_build_remote_git_branch = var.deploy_options.kaia_build_remote_git_branch
      kaia_num_cn       = var.cn_options.count
      kaia_num_pn       = var.pn_options.count
      kaia_num_en       = var.en_options.count
      kaia_network_id   = var.deploy_options.kaia_network_id
      kaia_chain_id     = var.deploy_options.kaia_chain_id
    }
  )
}
resource "local_file" "this" {
  content  = local.ansible_inventory
  filename = format("%s/../../../inventory/%s/inventory.ini", path.module, basename(abspath(path.module)))
}
resource "local_file" "ansible_group_vars" {
  content  = local.ansible_vars
  filename = format("%s/../../../inventory/%s/group_vars/all/all.yml", path.module, basename(abspath(path.module)))
}