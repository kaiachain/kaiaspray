project    = "kaiaspray"
project_id = "kaiaspray-123456"
gcp_region = "asia-northeast3"

name           = "kaiaspray"
user_name       = "kaia"
ssh_client_ips = ["0.0.0.0/0"]


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
  count          = 1
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}

pn_options = {
  count          = 1
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}

en_options = {
  count          = 1
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}

monitor_options = {
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}
