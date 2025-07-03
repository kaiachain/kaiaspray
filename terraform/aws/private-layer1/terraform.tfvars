aws_region     = "ap-northeast-2"
ssh_client_ips = ["0.0.0.0/0"]

deploy_options = {
  kaia_install_mode = "build"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  kaia_network_id = 9999
  kaia_chain_id   = 9999
  kaia_build_remote_git_url = "git@github.com:kaiachain/kaia.git"
  kaia_build_remote_git_branch = "dev"
}

cn_options = {
  count           = 1
  instance_type   = "t3.small"
  ebs_volume_size = 20
}

pn_options = {
  count           = 1
  instance_type   = "t3.small"
  ebs_volume_size = 20
}

en_options = {
  count           = 1
  instance_type   = "t3.small"
  ebs_volume_size = 20
}

monitor_options = {
  instance_type   = "t3.small"
  ebs_volume_size = 20
}
