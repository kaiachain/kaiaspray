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
# HOMI_ADDITIONAL_OPTIONS="--istanbul-compatible-blocknumber 1000" # If you want to add additional options, you can add it here.

# Override ADDITIONAL configuration for specific nodes
# Format: OVERRIDE_CONF_ADDITIONAL_{NODE_TYPE}_{INDEX}
# OVERRIDE_CONF_ADDITIONAL_CN_1="--mine --miner.threads=1"
# OVERRIDE_CONF_ADDITIONAL_PN_2="--syncmode=full"
# OVERRIDE_CONF_ADDITIONAL_EN_1="--http.corsdomain=*"
