# Deploy Private Layer1 Network on AWS

### 1. Deploy AWS resources
> :warning: Before running the following commands, please get AWS credentials.

Execute command below to deploy resources via Terraform.
```bash
$ git clone https://github.com/kaiachain/kaiaspray.git
$ cd kaiaspray
$ export TF_OPTIONS="-chdir=terraform/aws/private-layer1"
$ terraform $TF_OPTIONS init
$ terraform $TF_OPTIONS plan
$ terraform $TF_OPTIONS apply -auto-approve
```

terraform output will be shown like the below.
```hcl
layer1 = {
  cn = [
    {
      "instance_id" = "<instance-id>"
      "private_ip" = "<private-ip>"
      "public_ip" = "<public-ip>"
    },
    ...
  ]
  en = [
    {
      "instance_id" = "<instance-id>"
      "private_ip" = "<private-ip>"
      "public_ip" = "<public-ip>"
    },
  ]
  pn = [
    {
      "instance_id" = "<instance-id>"
      "private_ip" = "<private-ip>"
      "public_ip" = "<public-ip>"
    },
    ...
  ]
  monitor = {
    "instance_id" = "<instance-id>"
    "private_ip" = "<private-ip>"
    "public_ip" = "<public-ip>"
  }
  layer1_sg_id = "<security-group-id>"
}
```

### 2. Check the generated files
You can check two files in the root path of kaiaspray.
1. private-ssh-key.pem: a file to use via SSH
2. inventory/private-layer1/inventory.ini: a file storing Kaia node connection information
3. inventory/private-layer1/group_vars/all.yml: a file storing deploy options information

### 3. Execute Ansible playbook
```bash
$ ansible-playbook -i inventory/private-layer1/inventory.ini private-layer1.yaml
```

### 4. Check working using Grafana
Open http://<monitor-public-ip>:3000 in the webbrowser. The default credential is admin:admin.

![Image](docs/img/grafana.png?raw=true)

### 5. Destroy the deployed instances
```bash
$ terraform $TF_OPTIONS destroy -auto-approve
```

### Additional Configuration Options

You can modify various configuration options in the terraform.tfvars file. See the example below for available settings:

#### Option1. deploy_options

The `deploy_options` block configures deployment settings for your Kaia nodes:

1. **Installation Mode**:
   - Set `kaia_install_mode` to specify how nodes are installed
   - Available options are "package" or "build"

2. **Version Control**:
   - Set `kaia_version` to specify which version to deploy
   - Example: "v1.0.3"

3. **Docker Build Settings**:
   - Use `kaia_build_docker_base_image` to set the base image for builds
   - Only needed when installation mode is "build"

4. **Network Configuration**:
   - `kaia_network_id`: Unique identifier for your network
   - `kaia_chain_id`: Chain identifier for your network

### Example terraform.tfvars
```
deploy_options = {
  kaia_install_mode = "package"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  kaia_network_id = 9999
  kaia_chain_id   = 9999
}
```
