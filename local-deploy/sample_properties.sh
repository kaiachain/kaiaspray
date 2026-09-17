# setup directories
KAIACODE=$HOME/workdir/kaia
HOMEDIR=$HOME/workdir/kaiaspray/local-deploy

# setup some options
NETWORK_ID=949494 # put random NETWORK_ID
NUMOFCN=1
NUMOFPN=1
NUMOFEN=1
NUMOFTESTACCSPERNODE=1

# remix option
REMIX=true # if this is true, set the cors field of the EN to use remix. If EN not available, CN will be used for remix.

# homi - nodekey dir options. If you already using existing nodekeys, locate the nodekeys under nodekey
HOMI_CNKEYS=false
HOMI_PNKEYS=false
HOMI_ENKEYS=false

# homi - some useful options
HOMI_PATCH_ADDRESSBOOK=false # if you set true, the addressbook admin will be the cn1 nodekey.
HOMI_REGISTRY_MOCK=false # if you set true, the bls-registry mock will be registered automatically.
HOMI_NUMOF_INITIAL_CN_NUM=0 # amount NUMOFCN, HOMI_NUMOF_INITIAL_CN_NUM will be addvalidate later.
HOMI_BAOBAB_TEST=false # if you set true, the homi will be setup for baobab testnet.

# homi - permissionless (KIP-311) options
# PERMISSIONLESS_MODE
#   off      : no permissionless flags. AddressBookV1 only.
#   genesis  : AddressBookV2 installed at 0x400 from block 0.
#              HOMI_PATCH_ADDRESSBOOK is a no-op in this mode.
#   deferred : AddressBookV1 stays at 0x400 until HOMI_PERMISSIONLESS_BLOCK.
#              11_govsetup.sh 01 deploys V4/PDV2, moves the GC-owned stake,
#              publishes ABv2DataContract, and waits for the scheduled fork.
#              Requires HOMI_PATCH_ADDRESSBOOK=true so cn1 can administer ABv1.
PERMISSIONLESS_MODE=off
# Fork block for 'deferred'. Choose a future block with enough time to start
# the network and run 11_govsetup.sh 01. The setup prepares the migration and
# waits for this genesis-configured block without overriding or restarting nodes.
HOMI_PERMISSIONLESS_BLOCK=100000000
# Empty uses the homi default (86400). For a short migration test, choose a
# smaller epoch and put HOMI_PERMISSIONLESS_BLOCK on its boundary (e.g. 400/10).
HOMI_VRANK_EPOCH=
# Genesis mode only: deploy each validator with PublicDelegationV2. Deferred
# migration must leave this false because setup 01 deploys V4/PDV2 by transaction.
HOMI_PUBLIC_DELEGATION=false
# HOMI_ADDITIONAL_OPTIONS="--istanbul-compatible-blocknumber 1000" # If you want to add additional options, you can add it here.

# Override ADDITIONAL configuration for specific nodes
# Format: OVERRIDE_CONF_ADDITIONAL_{NODE_TYPE}_{INDEX}
# OVERRIDE_CONF_ADDITIONAL_CN_1="--mine --miner.threads=1"
# OVERRIDE_CONF_ADDITIONAL_PN_2="--syncmode=full"
# OVERRIDE_CONF_ADDITIONAL_EN_1="--http.corsdomain=*"
