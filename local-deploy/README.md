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
./8_explorer.sh start en 1 1.2.3.4 # fetch data from en1, serve at http://1.2.3.4
./8_explorer.sh start en 1 # fetch data from en1
./8_explorer.sh stop
```

## TroubleShooting
TBD
