project    = "kaiaspray"
project_id = "kaiaspray-123456"
gcp_region = "asia-northeast3"

name           = "kaiaspray"
user_name       = "kaia"
ssh_client_ips = ["0.0.0.0/0"]

#network    = ""
#subnetwork = ""
#network_tags = ["ssh"]

# create_gcp_key_pair = false
# ssh_existing_private_key_path = ""
# ssh_existing_public_key_path  = ""

deploy_options = {
  kaia_install_mode = "package"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  #kaia_build_remote_git_url = "git@github.com:kaiachain/kaia.git"
  #kaia_build_remote_git_branch = "dev"
  #kaia_network = "kairos"
  kaia_network_id = 9999
  kaia_chain_id   = 9999
  # homi_extra_options = ""
}

cn_options = {
  count          = 1
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100 # if you set compute_disk_size, it will be protected if you delete MANUALLY. So, be aware of this, and please run "destroy" command when you want to delete the node.
}

pn_options = {
  count          = 1
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}

en_options = {
  count = 2
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
  # options = {
  #   0: {
  #     NETWORK = "kairos"
  #     NO_DISCOVER = 0
  #     RPC_ENABLE = 1
  #     RPC_API = "kaia,admin,personal,eth,web3,net,governance,istanbul"
  #     compute_disk_size = 1000
  #     snapshot_id = "chaindata-full-kairos-20241231"
  #   }
  #   1: {
  #     NETWORK = "mainnet"
  #     NO_DISCOVER = 0
  #     RPC_ENABLE = 1
  #     RPC_API = "kaia,admin,personal,eth,web3,net,governance,istanbul"
  #     compute_disk_size = 1000
  #     snapshot_id = "chaindata-full-mainnet-20241231"
  #   }
  # }
}

monitor_options = {
  machine_type   = "n2-standard-2"
  boot_disk_size = 30
  # compute_disk_size = 100
}
