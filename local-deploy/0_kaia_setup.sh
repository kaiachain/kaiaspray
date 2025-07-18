#!/bin/bash
source ./properties.sh

modifyNNData()
{
  NODE_TYPE=$1
  NUM_OF_NODE=$2
  PORT_BASE=$3

  if [ $NUM_OF_NODE = 0 ]; then
    return
  fi

  for ((num = 1; num <= NUM_OF_NODE; num++))
  do
    PORT=$(( 32323 + (PORT_BASE+num-1)*2 ))
    RPC_PORT=$(( 8551 + PORT_BASE+num - 1 ))
    WS_PORT=$(( 8651 + PORT_BASE+num - 1 ))
    PROMETHEUS_PORT=$(( 61001 + PORT_BASE + num - 1))

    echo $NODE_TYPE$num ": " $PORT $RPC_PORT $WS_PORT $PROMETHEUS_PORT
    cd $HOMEDIR && mkdir $NODE_TYPE$num
    cd $NODE_TYPE$num && mkdir bin && mkdir conf && mkdir data
    mkdir data/klay && mkdir data/keystore

    CONF_DIR="conf/k"$NODE_TYPE"d.conf"
    DAEMON_DIR="bin/k"$NODE_TYPE"d"

    cp $KAIACODE/build/packaging/linux/$CONF_DIR $CONF_DIR
    cp $KAIACODE/build/packaging/linux/$DAEMON_DIR $DAEMON_DIR

    sed -i.bak "s/NETWORK=.*/#NETWORK=/g" $CONF_DIR
    sed -i.bak "s/NETWORK_ID=.*/NETWORK_ID="$NETWORK_ID"/g" $CONF_DIR
    sed -i.bak "s/PORT=32323/PORT="$PORT"/g" $CONF_DIR
    sed -i.bak "s/RPC_ENABLE=.*/RPC_ENABLE=1/g" $CONF_DIR
    sed -i.bak "s/RPC_API=.*/RPC_API=\"admin,debug,kaia,miner,net,personal,rpc,txpool,web3,eth,istanbul,governance\"/g" $CONF_DIR
    sed -i.bak "s/RPC_PORT=.*/RPC_PORT="$RPC_PORT"/g" $CONF_DIR
    sed -i.bak "s/WS_ENABLE=.*/WS_ENABLE=1/g" $CONF_DIR
    sed -i.bak "s/WS_API=.*/WS_API=\"admin,debug,kaia,miner,net,personal,rpc,txpool,web3,eth,istanbul,governance\"/g" $CONF_DIR
    sed -i.bak "s/WS_PORT=.*/WS_PORT="$WS_PORT"/g" $CONF_DIR
    sed -i.bak "s/AUTO_RESTART=.*/AUTO_RESTART=1/g" $CONF_DIR
    sed -i.bak "s/MULTICHANNEL=.*/MULTICHANNEL=1/g" $CONF_DIR
    sed -i.bak "s|DATA_DIR=.*|DATA_DIR=${HOMEDIR}/${NODE_TYPE}${num}/data|g" ${CONF_DIR}

    if [ $NODE_TYPE = "cn" ]; then
      # copy nodekey & keystore & passwd file from homi-output to cn dir
      cp ../homi-output/keys/nodekey$num data/klay/nodekey
      cp ../homi-output/keys/keystore$num data/keystore
      cp ../homi-output/keys/passwd$num conf/pwd.txt
      echo "" >> conf/pwd.txt
      # set REWARDBASE and unlock at kcnd.conf
      sed -i.bak "s/REWARDBASE=.*/REWARDBASE=\""`cat ../homi-output/keys/reward$num`"\"/g" $CONF_DIR
      # set proper port number at static-nodes.json
      sed -i.bak $((num+1))"s/:"$((32323+PORT_BASE+num-1))"/:"$PORT"/g" ../homi-output/scripts/static-nodes.json
    elif [ $NODE_TYPE = "pn" ]; then
      # copy nodekey from homi-output to pn dir
      cp ../homi-output/keys_pn/nodekey$num data/klay/nodekey
      # set proper port number at static-nodes.json
      sed -i.bak $((num+1))"s/:"$((32323+PORT_BASE+num-1))"/:"$PORT"/g" ../homi-output/scripts_pn/static-nodes.json
    fi

    rm "$CONF_DIR.bak"
    cd ..
  done

  # copy static-nodes.json file to each node directory
  for ((num = 1; num <= NUM_OF_NODE; num++))
  do
    if [ $NODE_TYPE = "cn" ]; then
      cp homi-output/scripts/static-nodes.json $NODE_TYPE$num/data/static-nodes.json
    elif [ $NODE_TYPE = "pn" ]; then
      if [ $NUMOFCN = 0 ]; then
        echo "FAILED: If you want to run the PN, provide the static-nodes.json at homi-output/scripts/static-nodes.json"
        return
      fi
      cp homi-output/scripts/static-nodes.json $NODE_TYPE$num/data/static-nodes.json
    elif [ $NODE_TYPE = "en" ]; then
      if [ $NUMOFPN = 0 ]; then
        echo "FAILED: If you want to run the EN, provide the static-nodes.json at homi-output/scripts_pn/static-nodes.json"
        return
      fi
      cp homi-output/scripts_pn/static-nodes.json $NODE_TYPE$num/data/static-nodes.json
    fi
  done
}

setupTestAccount()
{
    NODE_TYPE=$1
    NUM_OF_NODE=$2
    TESTACC_START_IDX=$3

    # return when there's no test account
    if [ $NUMOFTESTACCSPERNODE = 0 ]; then
      return
    fi

    for ((num = 1; num <= NUM_OF_NODE; num++))
    do
      NODEDIR=$HOMEDIR/$NODE_TYPE$num
      for ((idx=1; idx<=NUMOFTESTACCSPERNODE; idx++))
      do
        KEYSTOREDIR=$HOMEDIR/homi-output/keys_test/keystore$((TESTACC_START_IDX+(num-1)*NUMOFTESTACCSPERNODE+idx))
        if [ $NODE_TYPE = "cn" ]; then
          cp $KEYSTOREDIR/UTC* $NODEDIR/data/keystore/keystore_test$(($idx+1))
        else
          cp $KEYSTOREDIR/UTC* $NODEDIR/data/keystore/keystore_test$idx
        fi
        echo `cat $KEYSTOREDIR/0x*` >> $NODEDIR/conf/pwd.txt
      done
      echo "generated test accounts at "$NODEDIR

      if [ $NODE_TYPE = "cn" ]; then
        UNLOCKACCS=$(($NUMOFTESTACCSPERNODE+1))
      else
        UNLOCKACCS=$NUMOFTESTACCSPERNODE
      fi
      str=`seq -s, 0 $UNLOCKACCS`
      # Remove trailing comma if it exists
      if [[ $str == *, ]]; then
        str=${str%,}
      fi
      str=${str:0:$((${#str}-2))}
      str="ADDITIONAL=\"--unlock "$str" --password "$NODEDIR/conf/pwd.txt"\""
      sed -i.bak "s|ADDITIONAL=.*|$str|" $NODEDIR/conf/k${NODE_TYPE}d.conf
      rm "$NODEDIR/conf/k${NODE_TYPE}d.conf.bak"
    done
}

configureRemixCors()
{
  NODETYPE="en"
  if [ $NUMOFEN = 0 ]; then
    NODETYPE="cn"
    echo "NUMOFEN is zero. Instead of en1, cn1 will be used for the configuration."
  fi
  CONF_DIR=$HOMEDIR"/${NODETYPE}1/conf/k${NODETYPE}d.conf"
  echo "ADDITIONAL=\"--vmdebug \$ADDITIONAL\"" >> $CONF_DIR
  sed -i.bak "s/RPC_CORSDOMAIN=.*/RPC_CORSDOMAIN=https:\/\/remix.ethereum.org/g" $CONF_DIR
  rm "$CONF_DIR"".bak"
}

configurePrometheus()
{
    NODE_TYPE=$1
    NUM_OF_NODE=$2
    PORT_BASE=$3

    echo "Configuring Prometheus for ${NODE_TYPE}: ${NUM_OF_NODE} nodes"
    for ((num = 1; num <= NUM_OF_NODE; num++))
    do
      CONF_DIR=$HOMEDIR"/${NODE_TYPE}${num}/conf/k${NODE_TYPE}d.conf"
      PROMETHEUS_PORT=$(( 61001 + PORT_BASE + num - 1))
      echo "Setting Prometheus port for ${NODE_TYPE}${NUM_OF_NODE}: ${PROMETHEUS_PORT}"
      sed -i.bak -E "s|^(ADDITIONAL=.*)\"|\1 --prometheusport $PROMETHEUS_PORT\"|" $CONF_DIR
      sed -i.bak "s/METRICS=.*/METRICS=1/g" $CONF_DIR
      sed -i.bak "s/PROMETHEUS=.*/PROMETHEUS=1/g" $CONF_DIR
      rm "$CONF_DIR"".bak"
    done
}

overrideAdditionalConfig()
{
    NODE_TYPE=$1
    NUM_OF_NODE=$2

    echo "Checking for override ADDITIONAL configuration for ${NODE_TYPE}: ${NUM_OF_NODE} nodes"
    for ((num = 1; num <= NUM_OF_NODE; num++))
    do
      CONF_DIR=$HOMEDIR"/${NODE_TYPE}${num}/conf/k${NODE_TYPE}d.conf"
      OVERRIDE_VAR="OVERRIDE_CONF_ADDITIONAL_$(echo $NODE_TYPE | tr '[:lower:]' '[:upper:]')_${num}"
      
      # Check if override variable is defined and not empty
      if [[ -n "${!OVERRIDE_VAR}" ]]; then
        echo "Applying override ADDITIONAL configuration for ${NODE_TYPE}${num}: ${!OVERRIDE_VAR}"
        # Append the override configuration to existing ADDITIONAL
        sed -i.bak -E "s|^(ADDITIONAL=.*)\"|\1 ${!OVERRIDE_VAR}\"|" $CONF_DIR
        rm "$CONF_DIR"".bak"
      fi
    done
}

deploy()
{
  rm -rf cn* pn* en* homi-output homi
  cp $KAIACODE/build/bin/homi homi

  # configure additional homi flags if exists
  NODEKEYSDIR=""
  PATHADDRESSBOOK=""
  if [[ $HOMI_CNKEYS == true ]]; then
    NODEKEYSDIR+="--cn-nodekey-dir nodekeydir/cn-keys "
  fi
  if [[ $HOMI_PNKEYS == true ]]; then
    NODEKEYSDIR+="--pn-nodekey-dir nodekeydir/pn-keys "
  fi
  if [[ $HOMI_ENKEYS == true ]]; then
    NODEKEYSDIR+="--en-nodekey-dir nodekeydir/en-keys "
  fi
  if [[ $HOMI_PATCH_ADDRESSBOOK == true ]]; then
    PATCHADDRESSBOOK="--patch-address-book "
  fi
  if [[ $HOMI_REGISTRY_MOCK == true ]]; then
    REGISTRY_MOCK="--registry-mock "
  fi
  if [[ $HOMI_BAOBAB_TEST == true ]]; then
    HOMI_CONFIG="--baobab-test "
  else
    HOMI_CONFIG="--cypress-test "
  fi
  

  ./homi setup --gen-type=local $HOMI_CONFIG $PATCHADDRESSBOOK $REGISTRY_MOCK $HOMI_ADDITIONAL_OPTIONS \
      --cn-num $NUMOFCN --pn-num $NUMOFPN --en-num $NUMOFEN --chainID $NETWORK_ID \
      --test-num $((NUMOFTESTACCSPERNODE*(NUMOFCN+NUMOFPN+NUMOFEN))) --mnemonic test,junk

  if [[ $HOMI_NUMOF_INITIAL_CN_NUM != 0 ]]; then
    ./homi setup --gen-type=local $HOMI_CONFIG $NODEKEYSDIR $PATCHADDRESSBOOK $REGISTRY_MOCK $HOMI_ADDITIONAL_OPTIONS \
        --cn-num $HOMI_NUMOF_INITIAL_CN_NUM --chainID $NETWORK_ID --output homi-output-tmp
    mv homi-output-tmp/scripts/genesis.json homi-output/scripts/genesis.json
    mv homi-output-tmp/keys/*1 homi-output/keys/

    rm -rf homi-output-tmp
  fi
  sed -i.bak "s/\"chainId\".*/\"chainId\": "$NETWORK_ID",/g" homi-output/scripts/genesis.json
  rm "homi-output/scripts/genesis.json.bak"

  modifyNNData "cn" $NUMOFCN 0
  modifyNNData "pn" $NUMOFPN $NUMOFCN
  modifyNNData "en" $NUMOFEN $NUMOFCN+$NUMOFPN

  sh 1_copy_binary.sh

  setupTestAccount "cn" $NUMOFCN 0
  setupTestAccount "pn" $NUMOFPN NUMOFTESTACCSPERNODE*NUMOFCN
  setupTestAccount "en" $NUMOFEN NUMOFTESTACCSPERNODE*NUMOFCN+NUMOFTESTACCSPERNODE*NUMOFPN

  if [[ $ENFORREMIX = "true" ]]; then
    configureRemixCors
  fi

  configurePrometheus "cn" $NUMOFCN 0
  configurePrometheus "pn" $NUMOFPN $NUMOFCN
  configurePrometheus "en" $NUMOFEN $NUMOFCN+$NUMOFPN

  # override additional config
  overrideAdditionalConfig "cn" $NUMOFCN
  overrideAdditionalConfig "pn" $NUMOFPN
  overrideAdditionalConfig "en" $NUMOFEN
}

# Execute deploy
deploy
