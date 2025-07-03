name                = "Kaiaspray"
resource_group_name = "Kaiaspray"
ssh_client_ips      = ["0.0.0.0/0"]

deploy_options = {
  kaia_install_mode = "package"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  kaia_network_id = 9999
  kaia_chain_id   = 9999
  kaia_build_remote_git_url = "git@github.com:kaiachain/kaia.git"
  kaia_build_remote_git_branch = "dev"
}

cn_options = {
  count         = 1
  instance_size = "Standard_D2_v5"
  os_disk_size  = 30
}

pn_options = {
  count         = 1
  instance_size = "Standard_D2_v5"
  os_disk_size  = 30
}

en_options = {
  count         = 1
  instance_size = "Standard_D2_v5"
  os_disk_size  = 30
}

monitor_options = {
  count         = 1
  instance_size = "Standard_B2s"
  os_disk_size  = 30
}
