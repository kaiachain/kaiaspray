# Kaia Analytics Tool

A command-line tool for collecting and analyzing node operation data.

## Features

- Common Analysis
  - Collect logs from the last N days
  - Exported grafana metrics (e.g. number of rpc calls)
  - System metrics
    - Top Result (cpu and memory usage)
    - Disk Usage (df -h)
    - Process Information (ps -ef | grep k{node})
    - System logs (e.g. dmesg - killed system logs)

- Network connection
  - admin.peers, admin.nodeInfo RPC call
  - peer count per type

- Consensus data
  - kaia.getBlockWithConsensusInfo
  - istanbul.getValidators
  - istanbul.getDemotedValidators
  - kaia.getCouncil
  - kaia.getCommittee
  - governance.getStakingInfo
  - kaia.getRewards

- Governance data
  - decoded voteData if data not empty
  - decoded governanceData if data not empty
  - decoded extraData

- Compress to zip file

## Getting Started

### Prerequisites

The following tools are required:
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl jq zip nc

# yum
sudo yum install curl jq zip nc
```

### Installation

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/kaiachain/kaiaspray/main/analytics-tool/analyze.sh
```

2. Make it executable:
```bash
chmod +x analyze.sh
```

### Basic Usage
Set next paths to yours
```bash
LOG_PATH="/var/kcnd/data/logs/kcnd.out"
BIN_PATH="/usr/bin/kcn"
IPC_URL="/var/kcnd/data/klay.ipc"
RPC_URL="http://localhost:8551"
```

1. Run complete analysis:
```bash
# NOTE: monitor should be enabled

./analyze.sh --tail-lines 10000 --log-path $LOG_PATH --monitor-port 61001
```

2. Collect only gov-data (collect via rpc):
```bash
./analyze.sh --gov-data-only --bin-path $BIN_PATH --rpc-endpoint $RPC_URL --block-height 5
```

3. Collect only consensus-data (collect via ipc):

```bash
# NOTE: If you're querying on a full node, only (multiples of 1024 + 1 or recent) block nums are available.

 ./analyze.sh --consensus-only --rpc-endpoint $IPC_URL --bin-path $BIN_PATH --block-height 1025
```

4. Collect only network-data (collect via ipc):
```bash
./analyze.sh --network-only --rpc-endpoint $IPC_URL --bin-path $BIN_PATH
```

## Export the output
The result is stored in output folder.
You can compress the output directory to zip file.
```bash
./analyze.sh --compress-output
```

You can upload the compressed zip file to s3.
NOTE: 
```bash
# NOTE: aws-cli should be installed
ZIP_FILE=
S3_BUCKET=
aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$ZIP_FILE"
```