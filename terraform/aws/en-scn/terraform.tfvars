aws_region     = "ap-northeast-2"
ssh_client_ips = ["0.0.0.0/0"]

deploy_options = {
  homi_output_dir = "/opt/homi"
  kaia_rewardbase = "0x46879cdc21832d6bd6b49081513fa3d965443075"
  kaia_install_mode = "build"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  kaia_build_remote_git_url = "git@github.com:kaiachain/kaia.git"
  kaia_build_remote_git_branch = "dev"
  
  # EN options
  kaia_chaindata_timestamp = "latest"
  kaia_bridge_enabled = 1
  kaia_conf_override_en = {
    NETWORK = "kairos"
    RPC_ENABLE = 1
    RPC_API = "kaia,admin,personal,eth,web3,net"
  }
  
  # SCN options
  kaia_service_parent_chain_id = 1001
  kaia_service_network_id = 10000
  kaia_service_chain_id = 10000
  kaia_conf_override_scn = {
    PORT = 22323
  }
}

en_options = {
  count           = 1
  instance_type   = "m6i.large"
  ebs_volume_size = 1000
}

scn_options = {
  count           = 2
  instance_type   = "t3.small"
  ebs_volume_size = 20
}
