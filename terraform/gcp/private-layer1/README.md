# Deploy Private Layer1 Network on GCP

### 0. Prepare GCP Credentials
> :warning: Before running the following commands, please get GCP credentials using command below.

Option1.
```bash
gcloud auth application-default login
```
Option2.
```bash
export GOOGLE_APPLICATION_CREDENTIALS="<path-to-credential-json>"
```

### 1. Deploy GCP resources
Execute command belows to deploy resources via Terraform.
```bash
$ git clone https://github.com/kaiachain/kaiaspray.git
$ cd kaiaspray
$ export TF_OPTIONS="-chdir=terraform/gcp/private-layer1"
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
  layer1_sg_id  = "<security-group-id>"
  monitor_sg_id = "<security-group-id>"
}
```

### 2. Check the generated files
You can check two files in the root path of kaiaspray.
1. gcp-private-ssh-key.pem: a file to use via SSH (if you )
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

#### Option1. SSH Key Management

1. **Generate a new SSH key pair**:
   - Set `create_gcp_key_pair = true` in your terraform.tfvars file
   - The private key will be automatically generated and saved to the path specified in the module
   - The public key will be automatically extracted and added to instance metadata

2. **Use an existing SSH key pair**:
   - Set `create_gcp_key_pair = false` in your terraform.tfvars file
   - Provide the path to your existing private key in `ssh_existing_private_key_path`
   - Provide the path to your existing public key in `ssh_existing_public_key_path`

> How to Extract Public Key from Private Key?
> 
> If you have an existing private key and need to extract the public key, you can use the following command:

```bash
# For OpenSSH format private keys
ssh-keygen -y -f /path/to/private_key > /path/to/public_key.pub

# For PEM format private keys
ssh-keygen -y -f /path/to/private-key.pem > /path/to/public-key.pem
```

### Example terraform.tfvars

```hcl
# Option 1: Generate a new key pair
create_gcp_key_pair = true

# Option 2: Use existing key pair
create_gcp_key_pair = false
ssh_existing_private_key_path = "/path/to/private-key.pem"
ssh_existing_public_key_path = "/path/to/public-key.pub"
```

#### Option2. deploy_options

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

5. **Git URL and branch**:
   - `kaia_build_remote_git_url`: Git URLs to clone and build kaia (could be string or array of strings)
   - `kaia_build_remote_git_branch`: Git branch to clone and build kaia (could be string or array of strings)
   - Note that only different versions of Kaia **node** binaries would be used (i.e., only one version of homi will be used regardless of the number of git URL and branch)
   - Multi-git builds are supported for the `build` install mode

6. **Build** (`kaia_install_mode = "build"`): kaia is built with docker (statically linked) on the machine that runs ansible, and copied to the nodes
   - `kaia_build_cache`: a `gs://` folder (optional). A kaia commit found there (`<folder>/<commit>/`, with its `COMPLETE` file) is downloaded instead of built

### Example terraform.tfvars
```
deploy_options = {
  kaia_install_mode = "package"
  kaia_version = "v1.0.3"
  kaia_build_docker_base_image = "kaiachain/build_base:latest"
  kaia_network_id = 9999
  kaia_chain_id   = 9999
  kaia_build_remote_git_url = ["https://github.com/kaiachain/kaia.git", "https://github.com/yourname/kaia.git"]
  kaia_build_remote_git_branch = ["dev", "my-feature-branch"]
}
```
