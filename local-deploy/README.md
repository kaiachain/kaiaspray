# Local Deployment Guide

This guide explains how to deploy a local Kaia network.

## Prerequisites

- Docker and Docker Compose installed
- Git installed

## Get Started

1. Download the kaia repository at the designated paths:
   ```bash
   # Create a directory for kaia
   mkdir -p ~/workdir
   cd ~/workdir
   
   # Clone the kaia repository
   git clone https://github.com/kaiachain/kaia.git
   cd kaia

   # Build the binaries
   make
   ```

2. Navigate to the local-deploy directory:
   ```bash
   cd local-deploy
   ```

3. Configure properties.sh

   Copy the properties.sh file from copy_properties.sh
   ```bash
   cp sample_properties.sh properties.sh
   ```
   Setup Directories In Properties.sh - It's mandatory field to set.
   ```
   KAIACODE=$HOME/workdir/kaia
   HOMEDIR=$HOME/workdir/kaiaspray/local-deploy
   ```
   Setup Network_Id, Number of Nodes, and Number of TestAccounts
   ```
   NETWORK_ID=949494 # put random NETWORK_ID
   NUMOFCN=1
   NUMOFPN=1
   NUMOFEN=1
   NUMOFTESTACCSPERNODE=1
   ```
   Remix option - Default value is true.
   ```
   REMIX=true # if this is true, set the cors field of the EN to use remix. If EN not available, CN will be used for remix.
   ```

   Homi options
   ```
   # nodekey directory options - Default value is false. 
   # - It means the homi will generate new keys. 
   # - If you're already using existing nodekeys, 
   #   locate the nodekeys under nodekey
   HOMI_CNKEYS=false
   HOMI_PNKEYS=false
   HOMI_ENKEYS=false
   ```

4. Setup and Interact with Kaia nodes
   
   Next scripts are used to setup and interact with kaia nodes
   - `0_kaia_setup.sh`: Generate homi-output and setup kaia node directories
   - `1_copy_binary.sh`: Copy the built binaries from Kaia source code
   - `2_initialize_nodes.sh`: Delete and initialize the kaia nodes
   - `3_ccstart.sh`: Start the kaia nodes
   - `4_ccstop.sh`: Stop the kaia nodes
   - `5_attach.sh`: Attach the kaia node
   - `6_logs.sh`: Tail the log file of the kaia node

   Run next scripts
   ```bash
   ./0_kaia_setup.sh
   ./1_copy_binary.sh
   ./2_initialize_nodes.sh
   ./3_ccstart.sh
   ```

   Try attach the en node
   ```bash
   ./5_attach.sh en 1
   ```

   Try tail the log of the cn node
   ```bash
   ./6_logs.sh cn 1
   ```

5. Interact with Monitoring tools

   The deployment includes monitoring tools:
   - Prometheus: Available at http://localhost:9090
   - Grafana: Available at http://localhost:3000 (default credentials: admin/admin)

   To start the monitoring tool, run the next script.
   ```shell
   ./7_monitoring.sh start
   ```

   To stop the monitoring tool, run the next script.
   ```shell
   ./7_monitoring.sh stop
   ```

## Usages
```bash
./0_kaia_setup.sh
./1_copy_binary.sh # copy the binaries to all nodes
./1_copy_binary.sh cn 1 # copy the binary to the first cn node
./1_copy_binary.sh en 3 # copy the binary to the third en node
./2_initialize_nodes.sh # delete and initialize the all nodes
./2_initialize_nodes.sh cn 1 # delete and initialize the first cn
./2_initialize_nodes.sh en 3 # delete and initialize the third en
./3_ccstart.sh # start all nodes
./3_ccstart.sh cn 1 # start the first cn
./3_ccstart.sh en 3 # start the third en
./4_ccstop.sh # stop all nodes
./4_ccstop.sh cn 1 # stop the first cn
./4_ccstop.sh en 3 # stop the third en 
./5_ccattach.sh cn 1 # attach the first cn
./5_ccattach.sh en 3 # attach the third en
./6_logs.sh cn 1 # tail the log of the first cn
./6_logs.sh en 3 # tail the log of the third en
./7_monitoring.sh start
./7_monitoring.sh stop
```

## TroubleShooting

### How to check nodeAddress and kni

```
$ egrep -R -o "nodeAddress=0x[0-9a-fA-F]+" cn*/data/logs | sort
cn1/data/logs/kcnd.out:nodeAddress=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
cn2/data/logs/kcnd.out:nodeAddress=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
cn3/data/logs/kcnd.out:nodeAddress=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
cn4/data/logs/kcnd.out:nodeAddress=0x90F79bf6EB2c4f870365E785982E1f101E93b906
```

```
$ cat cn1/data/static-nodes.json
[
    "kni://8318535b54105d4a7aae60c08fc45f9687181b4fdfc625bd1a753fa7397fed753547f11ca8696646f2f3acb08e31016afac23e630c5d11f59f61fef57b0d2aa5@0.0.0.0:32323?discport=0\u0026ntype=cn",
    "kni://ba5734d8f7091719471e7f7ed6b9df170dc70cc661ca05e688601ad984f068b0d67351e5f06073092499336ab0839ef8a521afd334e53807205fa2f08eec74f4@0.0.0.0:32325?discport=0\u0026ntype=cn",
    "kni://9d9031e97dd78ff8c15aa86939de9b1e791066a0224e331bc962a2099a7b1f0464b8bbafe1535f2301c72c2cb3535b172da30b02686ab0393d348614f157fbdb@0.0.0.0:32327?discport=0\u0026ntype=cn",
    "kni://20b871f3ced029e14472ec4ebc3c0448164942b123aa6af91a3386c1c403e0ebd3b4a5752a2b6c49e574619e6aa0549eb9ccd036b9bbc507e1f7f9712a236092@0.0.0.0:32329?discport=0\u0026ntype=cn"
]
```

