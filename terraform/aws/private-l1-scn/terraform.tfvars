aws_region     = "ap-northeast-2"
ssh_client_ips = ["0.0.0.0/0"]

deploy_options = {
  kaia_version = "v1.0.3"
  kaia_network_id = 9999
  kaia_chain_id = 9999
  kaia_service_network_id = 10000
  kaia_service_chain_id = 10000
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

scn_options = {
  count           = 1
  instance_type   = "t3.small"
  ebs_volume_size = 20
}
