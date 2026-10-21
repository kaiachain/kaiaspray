#!/bin/bash
# Rehearse the deferred permissionless migration as three stages:
#   1. Prepare a legacy AddressBookV1 + CnStakingV3 + PDV1 state.
#   2. Move the GC stake through redeem -> claim -> PDV2 stake, then swap ABv1.
#   3. Publish ABv2DataContract and let the configured fork install ABv2.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LEGACY_GC_STAKE=${LEGACY_GC_STAKE:-5000000}
LEGACY_USER_STAKE_UNIT=${LEGACY_USER_STAKE_UNIT:-1000}
LEGACY_STAKE_LOCKUP=${LEGACY_STAKE_LOCKUP:-30}
VAL_ACTIVE=6
KIP113=0x0000000000000000000000000000000000000403
TEST_V3_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mock_contracts/TestCnStakingV3.sol"

state_path() {
  printf '%s\n' "${GOVSETUP_STATE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs/01-state.env}"
}

state_get() {
  local file key=$1
  file=$(state_path)
  [ -f "$file" ] || return 0
  sed -n "s/^${key}=//p" "$file" | tail -1
}

state_set() {
  local key=$1 value=$2 file dir tmp
  file=$(state_path); dir=${file%/*}
  mkdir -p "$dir" || die "cannot create state directory: $dir"
  tmp=$(mktemp "${file}.tmp.XXXXXX") || die "cannot create state file"
  if [ -f "$file" ]; then
    awk -F= -v key="$key" '$1 != key { print }' "$file" > "$tmp"
  fi
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$file" || die "cannot update state file"
}

has_live_contract() {
  local address=$1 code
  [ -n "$address" ] && ! same_addr "$address" "$ZERO" || return 1
  code=$(cast code "$address" --rpc-url "$RPC" 2>/dev/null) || return 1
  has_contract_code "$code"
}

initialize_state() {
  local file genesis stored
  file=$(state_path)
  genesis=$(cast block 0 --rpc-url "$RPC" --json 2>/dev/null \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["hash"])') \
    || die "cannot read genesis hash"
  stored=$(state_get GENESIS_HASH)
  if [ -n "$stored" ] && [ "$stored" != "$genesis" ]; then
    mkdir -p "${file%/*}"
    : > "$file"
  fi
  state_set GENESIS_HASH "$genesis"
  state_set CHAIN_ID "$CHAIN_ID"
  state_set FORK_BLOCK "$FORK_BLOCK"
}

validator_nodes() {
  local keyfile key node gcid
  gcid=0
  for keyfile in "$HOMEDIR"/homi-output/keys/nodekey[0-9]*; do
    [ -f "$keyfile" ] || continue
    gcid=$((gcid + 1))
    key=0x$(cat "$keyfile")
    node=$(cast wallet address --private-key "$key" 2>/dev/null) || die "cannot derive nodeId from $keyfile"
    printf '%s %s\n' "$node" "$gcid"
  done
}

binding_bin() {
  local binding=$1
  [ -f "$binding" ] || die "contract binding not found: $binding"
  python3 - "$binding" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'Bin: "(0x[0-9a-fA-F]+)"', text)
if not match:
    raise SystemExit("bytecode not found in " + sys.argv[1])
print(match.group(1))
PY
}

compile_test_v3() {
  command -v solc >/dev/null 2>&1 || die "solc is required to compile TestCnStakingV3"
  [ -f "$TEST_V3_SOURCE" ] || die "TestCnStakingV3 source not found: $TEST_V3_SOURCE"
  solc --evm-version paris --bin "$TEST_V3_SOURCE" 2>/dev/null \
    | awk '/^Binary:$/ { getline; print; exit }'
}

public_delegation_v1_initcode() {
  local cn_staking=$1 owner=$2 gcid=$3 artifact bytecode args
  artifact=${PDV1_ARTIFACT:-$KAIACODE/contracts/kaia-system-contracts/contracts-v1.0/artifacts/contracts/PublicDelegation/PublicDelegation.sol/PublicDelegation.json}
  [ -f "$artifact" ] || die "PublicDelegationV1 artifact not found: $artifact"
  bytecode=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["bytecode"])' "$artifact") \
    || die "cannot read PublicDelegationV1 bytecode"
  args=$(cast abi-encode 'constructor(address,(address,address,uint256,string))' \
    "$cn_staking" "($owner,$owner,0,LegacyGC-$gcid)") \
    || die "cannot encode PublicDelegationV1 constructor"
  printf '%s%s\n' "$bytecode" "${args#0x}"
}

abv1_info() {
  cast call "$ADDRESS_BOOK" 'getCnInfo(address)(address,address,address)' "$1" \
    --rpc-url "$RPC" 2>/dev/null | awk '{print $1}' | paste -sd' ' -
}

wait_until_block() {
  local target=$1 now
  while :; do
    now=$(cast block-number --rpc-url "$RPC" 2>/dev/null) || die "lost RPC connection"
    [ "$now" -ge "$target" ] && return
    sleep 1
  done
}

latest_timestamp() {
  cast block latest --rpc-url "$RPC" --json 2>/dev/null \
    | python3 -c 'import json,sys; v=json.load(sys.stdin)["timestamp"]; print(int(v,16) if isinstance(v,str) else v)'
}

big_sub() {
  python3 -c 'import sys; print(int(sys.argv[1]) - int(sys.argv[2]))' "$1" "$2"
}

big_mul() {
  python3 -c 'import sys; print(int(sys.argv[1]) * int(sys.argv[2]))' "$1" "$2"
}

big_delta_matches() {
  python3 -c 'import sys; raise SystemExit(0 if int(sys.argv[2]) - int(sys.argv[1]) == int(sys.argv[3]) else 1)' \
    "$1" "$2" "$3"
}

wait_until_timestamp() {
  local target=$1 now
  while :; do
    now=$(latest_timestamp) || die "cannot read latest block timestamp"
    [ "$now" -ge "$target" ] && return
    sleep 1
  done
}

register_record() {
  local name=$1 address=$2 active now activation
  active=$(rpc_call "$REGISTRY" 'getActiveAddr(string)(address)' "$name")
  if same_addr "$active" "$address"; then
    printf '%s\n' "$active"
    return
  fi
  now=$(cast block-number --rpc-url "$RPC")
  activation=$((now + 2))
  [ "$activation" -le $((FORK_BLOCK - 2)) ] \
    || die "not enough blocks to activate Registry record $name before block $((FORK_BLOCK - 1))"
  rpc_send "register $name" "$REGISTRY" 'register(string,address,uint256)' "$name" "$address" "$activation"
  wait_until_block "$activation"
  active=$(rpc_call "$REGISTRY" 'getActiveAddr(string)(address)' "$name")
  same_addr "$active" "$address" || die "Registry did not activate $name=$address"
  printf '%s\n' "$active"
}

preflight() {
  local count remaining required registry_owner ab_type
  require_deferred
  count=$(validator_nodes | grep -c . | tr -d ' ')
  [ "$count" -gt 1 ] || die "at least two validators are required for the ABv1 unregister/register swap"
  remaining=$((FORK_BLOCK - HEAD))
  if [ "$(state_get STEP2_COMPLETE)" = true ]; then
    required=20
  elif [ "$(state_get STEP1_COMPLETE)" = true ]; then
    required=$((50 + count * 5))
  else
    required=$((100 + count * 10))
  fi
  if [ "$remaining" -lt "$required" ]; then
    die "fork block is too close: $remaining blocks remain; the unfinished stages need about $required. Recreate the network with a later HOMI_PERMISSIONLESS_BLOCK."
  fi
  [ "${HOMI_PUBLIC_DELEGATION:-false}" != true ] \
    || die "HOMI_PUBLIC_DELEGATION must be false; setup 01 deploys PDV2 through real transactions"
  [ "${HOMI_REGISTRY_MOCK:-false}" != true ] \
    || die "HOMI_REGISTRY_MOCK must be false; setup 01 uses the production Registry"
  case " ${HOMI_ADDITIONAL_OPTIONS:-} " in
    *" --address-book-mock "*) die "remove --address-book-mock; setup 01 uses production AddressBookV1" ;;
  esac
  registry_owner=$(rpc_call "$REGISTRY" 'owner()(address)')
  same_addr "$registry_owner" "$ADMIN" \
    || die "Registry owner is $registry_owner, but setup admin is $ADMIN"
  ab_type=$(rpc_call "$ADDRESS_BOOK" 'CONTRACT_TYPE()(string)' | tr -d '"')
  [ "$ab_type" != AddressBookMock ] || die "0x400 is AddressBookMock; recreate without --address-book-mock"
}

ensure_fund_contracts() {
  local poc kir kpf
  poc=$(rpc_call "$ADDRESS_BOOK" 'pocContractAddress()(address)')
  kir=$(rpc_call "$ADDRESS_BOOK" 'kirContractAddress()(address)')
  kpf=$(state_get KPF)
  if same_addr "$poc" "$ZERO"; then
    poc=$(rpc_deploy "deploy KIF" "$FUND_STUB_INITCODE") || die "cannot deploy KIF stub"
    rpc_send "register KIF" "$ADDRESS_BOOK" 'submitUpdatePocContract(address,uint256)' "$poc" 1
  fi
  if same_addr "$kir" "$ZERO"; then
    kir=$(rpc_deploy "deploy KEF" "$FUND_STUB_INITCODE") || die "cannot deploy KEF stub"
    rpc_send "register KEF" "$ADDRESS_BOOK" 'submitUpdateKirContract(address,uint256)' "$kir" 1
  fi
  if ! has_live_contract "$kpf"; then
    kpf=$(rpc_deploy "deploy KPF" "$FUND_STUB_INITCODE") || die "cannot deploy KPF stub"
    state_set KPF "$kpf"
  fi
  state_set KIF "$poc"; state_set KEF "$kir"
  fact "KIF / PoC" "$poc"
  fact "KEF / KIR" "$kir"
  fact "KPF" "$kpf"
}

prepare_legacy_gc() {
  local node=$1 gcid=$2 owner_key test_bin v3 pdv1 initcode args info
  local owner_shares test_index keyfile key who held amount
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  v3=$(state_get "GC_${gcid}_V3")
  if ! has_live_contract "$v3"; then
    test_bin=$(compile_test_v3)
    args=$(cast abi-encode 'constructor(address,address,uint256)' "$node" "$node" "$LEGACY_STAKE_LOCKUP") \
      || die "cannot encode TestCnStakingV3 constructor"
    v3=$(rpc_deploy "deploy V3 gc-$gcid" "0x${test_bin}${args#0x}") || die "cannot deploy TestCnStakingV3"
    state_set "GC_${gcid}_V3" "$v3"
  fi
  [ -n "$(state_get "GC_${gcid}_V3_BLOCK")" ] \
    || state_set "GC_${gcid}_V3_BLOCK" "$(contract_deploy_block "$v3")"

  pdv1=$(state_get "GC_${gcid}_PDV1")
  if ! has_live_contract "$pdv1"; then
    initcode=$(public_delegation_v1_initcode "$v3" "$node" "$gcid")
    pdv1=$(rpc_deploy "deploy PDV1 gc-$gcid" "$initcode") || die "cannot deploy PublicDelegationV1"
    state_set "GC_${gcid}_PDV1" "$pdv1"
  fi
  [ -n "$(state_get "GC_${gcid}_PDV1_BLOCK")" ] \
    || state_set "GC_${gcid}_PDV1_BLOCK" "$(contract_deploy_block "$pdv1")"

  if ! same_addr "$(rpc_call "$v3" 'publicDelegation()(address)')" "$pdv1"; then
    SEND_KEY=$owner_key rpc_send "pair PDV1 gc-$gcid" "$v3" 'setPublicDelegation(address)' "$pdv1"
  fi

  info=$(abv1_info "$node")
  if ! printf '%s\n' "$info" | grep -qi "$v3"; then
    rpc_send "register V3 gc-$gcid" "$ADDRESS_BOOK" \
      'submitRegisterCnStakingContract(address,address,address)' "$node" "$v3" "$pdv1"
  fi

  owner_shares=$(rpc_call "$pdv1" 'balanceOf(address)(uint256)' "$node" | awk '{print $1}')
  if [ "${owner_shares:-0}" = 0 ]; then
    SEND_KEY=$owner_key SEND_VALUE=${LEGACY_GC_STAKE}ether rpc_send "stake GC gc-$gcid" "$pdv1" 'stake()'
  fi

  test_index=$gcid
  keyfile="$HOMEDIR/homi-output/keys_test/testkey$test_index"
  if [ -f "$keyfile" ]; then
    key=0x$(cat "$keyfile")
    who=$(cast wallet address --private-key "$key")
    held=$(rpc_call "$pdv1" 'balanceOf(address)(uint256)' "$who" | awk '{print $1}')
    if [ "${held:-0}" = 0 ]; then
      amount=$(big_mul "$gcid" "$LEGACY_USER_STAKE_UNIT")
      SEND_KEY=$key SEND_VALUE=${amount}ether rpc_send "stake user gc-$gcid" "$pdv1" 'stake()'
    fi
  fi

  state_set "GC_${gcid}_NODE" "$node"
  state_set "GC_${gcid}_MIGRATION_OWNER" "$node"
  fact "gc-$gcid legacy entry" "V3 $(short "$v3") / PDV1 $(short "$pdv1")"
  subfact "GC operating stake" "$(kaia "$(rpc_call "$pdv1" 'balanceOf(address)(uint256)' "$node" | awk '{print $1}')") pdKAIA"
  subfact "V3 staking" "$(kaia "$(rpc_call "$v3" 'staking()(uint256)' | awk '{print $1}')") KAIA"
}

run_legacy_state() {
  local constructed activated node gcid count
  stage_header "01" 1 3 "Prepare the legacy AddressBookV1 state"
  steps 5
  step "Check the pre-fork migration window"
  fact "chain head" "$HEAD"
  fact "permissionless fork" "$FORK_BLOCK"
  fact "remaining" "$((FORK_BLOCK - HEAD)) blocks"
  fact "TestCnStakingV3.STAKE_LOCKUP" "$LEGACY_STAKE_LOCKUP seconds (production: 7 days)"

  step "Configure production AddressBookV1"
  constructed=$(rpc_call "$ADDRESS_BOOK" 'isConstructed()(bool)')
  if [ "$constructed" != true ]; then
    rpc_send "construct ABv1" "$ADDRESS_BOOK" 'constructContract(address[],uint256)' "[$ADMIN]" 1
  fi
  fact "adminList" "[$ADMIN]"
  fact "requirement" "1"

  step "Deploy and register the fund contracts"
  ensure_fund_contracts

  step "Deploy and register TestCnStakingV3 and PublicDelegationV1"
  count=0
  while read -r node gcid; do
    [ -n "$node" ] || continue
    prepare_legacy_gc "$node" "$gcid"
    count=$((count + 1))
  done <<< "$(validator_nodes)"
  state_set GC_COUNT "$count"

  step "Activate AddressBookV1 and verify legacy balances"
  activated=$(rpc_call "$ADDRESS_BOOK" 'isActivated()(bool)')
  if [ "$activated" != true ]; then
    rpc_send "activate ABv1" "$ADDRESS_BOOK" 'submitActivateAddressBook()'
  fi
  fact "AddressBookV1.isActivated()" "$(rpc_call "$ADDRESS_BOOK" 'isActivated()(bool)')"
  fact "legacy council" "$count CnStakingV3 / PublicDelegationV1 entries"
  state_set STEP1_COMPLETE true
  stage_done
}

deploy_contract_once() {
  local state_key=$1 label=$2 initcode=$3 address
  address=$(state_get "$state_key")
  if ! has_live_contract "$address"; then
    address=$(rpc_deploy "$label" "$initcode") || die "$label failed"
    state_set "$state_key" "$address"
  fi
  [ -n "$(state_get "${state_key}_BLOCK")" ] \
    || state_set "${state_key}_BLOCK" "$(contract_deploy_block "$address")"
  printf '%s\n' "$address"
}

factory_pair_for_owner() {
  local factory=$1 owner=$2 logs
  logs=$(cast logs --address "$factory" --from-block 0 --to-block latest \
    --rpc-url "$RPC" --json 2>/dev/null) || return 1
  OWNER="$owner" python3 -c '
import json, os, sys
owner = os.environ["OWNER"].lower().removeprefix("0x")
signature = "87e576388f908fa28dd98074396103e586efe1e1a1c523831df5a717fc26359f"
for log in json.load(sys.stdin):
    topics = log.get("topics", [])
    if len(topics) >= 3 and topics[0].lower().removeprefix("0x") == signature:
        if topics[2].lower()[-40:] == owner:
            print("0x" + topics[1][-40:], "0x" + log["data"][-40:])
            break
' <<< "$logs"
}

deploy_v4_infrastructure() {
  local cn_bin pd_bin beacon_bin factory_bin args
  local cn_impl pd_impl cn_beacon pd_beacon factory
  cn_bin=$(binding_bin "$KAIACODE/contracts/bindings/cnstakingv4/CnStakingV4.go")
  pd_bin=$(binding_bin "$KAIACODE/contracts/bindings/publicdelegation/PublicDelegation.go")
  beacon_bin=$(binding_bin "$KAIACODE/contracts/bindings/beacon/UpgradeableBeacon.go")
  factory_bin=$(binding_bin "$KAIACODE/contracts/bindings/cnstakingv4factory/CnStakingV4Factory.go")
  cn_impl=$(deploy_contract_once CN_IMPL "deploy V4 impl" "$cn_bin")
  pd_impl=$(deploy_contract_once PD_IMPL "deploy PDV2 impl" "$pd_bin")
  args=$(cast abi-encode 'constructor(address,address)' "$cn_impl" "$ADMIN")
  cn_beacon=$(deploy_contract_once CN_BEACON "deploy V4 beacon" "${beacon_bin}${args#0x}")
  args=$(cast abi-encode 'constructor(address,address)' "$pd_impl" "$ADMIN")
  pd_beacon=$(deploy_contract_once PD_BEACON "deploy PDV2 beacon" "${beacon_bin}${args#0x}")
  args=$(cast abi-encode 'constructor(address,address)' "$cn_beacon" "$pd_beacon")
  factory=$(deploy_contract_once V4_FACTORY "deploy V4 factory" "${factory_bin}${args#0x}")
  register_record CnStakingFactory "$factory" >/dev/null
  fact "CnStakingV4 implementation" "$cn_impl"
  fact "PublicDelegationV2 implementation" "$pd_impl"
  fact "CnStakingV4Factory" "$factory"
}

deploy_v4_gc() {
  local node=$1 gcid=$2 factory owner_key predicted v4 pdv2 pd_args
  v4=$(state_get "GC_${gcid}_V4"); pdv2=$(state_get "GC_${gcid}_PDV2")
  if has_live_contract "$v4" && has_live_contract "$pdv2"; then
    fact "gc-$gcid deployment" "V4 $(short "$v4") / PDV2 $(short "$pdv2")"
    return
  fi
  factory=$(state_get V4_FACTORY)
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  pd_args="($node,$node,0,GC-$gcid)"
  predicted=$(factory_pair_for_owner "$factory" "$node")
  if [ -n "$predicted" ]; then
    v4=$(printf '%s\n' "$predicted" | awk '{print $1}')
    pdv2=$(printf '%s\n' "$predicted" | awk '{print $2}')
  else
  predicted=$(cast call "$factory" \
    'deployCnStakingWithPD(address,(address,address,uint256,string))(address,address)' \
    "$node" "$pd_args" --from "$node" --value 1000000000 --rpc-url "$RPC" 2>/dev/null) \
    || die "cannot predict V4/PDV2 addresses for gc-$gcid"
    v4=$(printf '%s\n' "$predicted" | awk 'NR == 1 {print $1}')
    pdv2=$(printf '%s\n' "$predicted" | awk 'NR == 2 {print $1}')
    SEND_KEY=$owner_key SEND_VALUE=1000000000 rpc_send "deploy V4/PD2 gc-$gcid" "$factory" \
      'deployCnStakingWithPD(address,(address,address,uint256,string))' "$node" "$pd_args"
  fi
  has_live_contract "$v4" || die "predicted V4 was not deployed: $v4"
  has_live_contract "$pdv2" || die "predicted PDV2 was not deployed: $pdv2"
  state_set "GC_${gcid}_V4" "$v4"; state_set "GC_${gcid}_PDV2" "$pdv2"
  state_set "GC_${gcid}_V4_BLOCK" "$(contract_deploy_block "$v4")"
  state_set "GC_${gcid}_PDV2_BLOCK" "$(contract_deploy_block "$pdv2")"
  fact "gc-$gcid deployment" "V4 $(short "$v4") / PDV2 $(short "$pdv2")"
}

redeem_legacy_gc() {
  local node=$1 gcid=$2 owner_key v3 pdv1 shares before_staking before_unstaking ids request_id info value unlock
  [ "$(state_get "GC_${gcid}_REDEEMED")" = true ] && return
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  v3=$(state_get "GC_${gcid}_V3"); pdv1=$(state_get "GC_${gcid}_PDV1")
  shares=$(rpc_call "$pdv1" 'balanceOf(address)(uint256)' "$node" | awk '{print $1}')
  [ "${shares:-0}" != 0 ] || die "gc-$gcid has no GC-owned PDV1 shares to migrate"
  before_staking=$(rpc_call "$v3" 'staking()(uint256)' | awk '{print $1}')
  before_unstaking=$(rpc_call "$v3" 'unstaking()(uint256)' | awk '{print $1}')
  SEND_KEY=$owner_key rpc_send "redeem PDV1 gc-$gcid" "$pdv1" 'redeem(address,uint256)' "$node" "$shares"
  ids=$(cast call "$pdv1" 'getUserRequestIds(address)(uint256[])' "$node" --rpc-url "$RPC" 2>/dev/null)
  request_id=$(printf '%s\n' "$ids" | tr -d '[],' | awk '{print $NF}')
  [[ $request_id =~ ^[0-9]+$ ]] || die "cannot read gc-$gcid withdrawal request id"
  info=$(cast call "$v3" 'getApprovedStakingWithdrawalInfo(uint256)(address,uint256,uint256,uint8)' \
    "$request_id" --rpc-url "$RPC" 2>/dev/null)
  value=$(printf '%s\n' "$info" | sed -n '2s/ .*//p')
  unlock=$(printf '%s\n' "$info" | sed -n '3s/ .*//p')
  state_set "GC_${gcid}_REQUEST_ID" "$request_id"
  state_set "GC_${gcid}_MIGRATED_VALUE" "$value"
  state_set "GC_${gcid}_WITHDRAWABLE_FROM" "$unlock"
  state_set "GC_${gcid}_REDEEMED" true
  fact "gc-$gcid redeem" "$(kaia "$value") KAIA requested"
  subchange "V3 unstaking" "$(kaia "$before_unstaking")" \
    "$(kaia "$(rpc_call "$v3" 'unstaking()(uint256)' | awk '{print $1}')") KAIA"
  subchange "V3 effective staking" "$(kaia "$(big_sub "$before_staking" "$before_unstaking")")" \
    "$(kaia "$(big_sub \
      "$(rpc_call "$v3" 'staking()(uint256)' | awk '{print $1}')" \
      "$(rpc_call "$v3" 'unstaking()(uint256)' | awk '{print $1}')")") KAIA"
}

claim_legacy_gc() {
  local node=$1 gcid=$2 owner_key v3 pdv1 request_id value unlock staking_before unstaking_before request_state
  [ "$(state_get "GC_${gcid}_CLAIMED")" = true ] && return
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  v3=$(state_get "GC_${gcid}_V3"); pdv1=$(state_get "GC_${gcid}_PDV1")
  request_id=$(state_get "GC_${gcid}_REQUEST_ID")
  value=$(state_get "GC_${gcid}_MIGRATED_VALUE")
  unlock=$(state_get "GC_${gcid}_WITHDRAWABLE_FROM")
  request_state=$(cast call "$v3" \
    'getApprovedStakingWithdrawalInfo(uint256)(address,uint256,uint256,uint8)' \
    "$request_id" --rpc-url "$RPC" 2>/dev/null | awk 'NR == 4 {print $1}')
  if [ "$request_state" = 1 ]; then
    state_set "GC_${gcid}_CLAIMED" true
    fact "gc-$gcid claim" "$(kaia "$value") KAIA already released to the GC owner"
    return
  fi
  [ "$request_state" = 0 ] \
    || die "gc-$gcid withdrawal cannot be claimed (state=$request_state)"
  wait_until_timestamp "$unlock"
  staking_before=$(rpc_call "$v3" 'staking()(uint256)' | awk '{print $1}')
  unstaking_before=$(rpc_call "$v3" 'unstaking()(uint256)' | awk '{print $1}')
  SEND_KEY=$owner_key rpc_send "claim PDV1 gc-$gcid" "$pdv1" 'claim(uint256)' "$request_id"
  request_state=$(cast call "$v3" \
    'getApprovedStakingWithdrawalInfo(uint256)(address,uint256,uint256,uint8)' \
    "$request_id" --rpc-url "$RPC" 2>/dev/null | awk 'NR == 4 {print $1}')
  [ "$request_state" = 1 ] \
    || die "gc-$gcid withdrawal was not transferred (state=$request_state); recreate the network and rerun before the claim window expires"
  state_set "GC_${gcid}_CLAIMED" true
  fact "gc-$gcid claim" "$(kaia "$value") KAIA released to the GC owner"
  subchange "V3 staking" "$(kaia "$staking_before")" \
    "$(kaia "$(rpc_call "$v3" 'staking()(uint256)' | awk '{print $1}')") KAIA"
  subchange "V3 unstaking" "$(kaia "$unstaking_before")" \
    "$(kaia "$(rpc_call "$v3" 'unstaking()(uint256)' | awk '{print $1}')") KAIA"
}

stake_v4_gc() {
  local node=$1 gcid=$2 owner_key v4 pdv2 value before after
  [ "$(state_get "GC_${gcid}_STAKED_V4")" = true ] && return
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  v4=$(state_get "GC_${gcid}_V4"); pdv2=$(state_get "GC_${gcid}_PDV2")
  value=$(state_get "GC_${gcid}_MIGRATED_VALUE")
  before=$(rpc_call "$v4" 'staking()(uint256)' | awk '{print $1}')
  SEND_KEY=$owner_key SEND_VALUE=$value rpc_send "stake PDV2 gc-$gcid" "$pdv2" 'stake()'
  after=$(rpc_call "$v4" 'staking()(uint256)' | awk '{print $1}')
  big_delta_matches "$before" "$after" "$value" \
    || die "gc-$gcid V4 staking delta does not match claimed value"
  state_set "GC_${gcid}_STAKED_V4" true
  fact "gc-$gcid stake" "$(kaia "$value") KAIA into PDV2"
  subchange "V4 staking" "$(kaia "$before")" "$(kaia "$after") KAIA"
}

swap_abv1_gc() {
  local node=$1 gcid=$2 owner_key v3 pdv1 v4 pdv2 info
  v3=$(state_get "GC_${gcid}_V3"); pdv1=$(state_get "GC_${gcid}_PDV1")
  v4=$(state_get "GC_${gcid}_V4"); pdv2=$(state_get "GC_${gcid}_PDV2")
  info=$(abv1_info "$node")
  if printf '%s\n' "$info" | grep -qi "$v4"; then state_set "GC_${gcid}_SWAPPED" true; return; fi
  owner_key=$(node_private_key "$node") || die "cannot find node key for $node"
  if [ "$(rpc_call "$v4" 'isInitialized()(bool)')" != true ]; then
    SEND_KEY=$owner_key rpc_send "set legacy gc-$gcid" "$v4" \
      'setLegacyAbv1Info(address,address)' "$node" "$pdv2"
  fi
  rpc_send "unregister V3 gc-$gcid" "$ADDRESS_BOOK" 'submitUnregisterCnStakingContract(address)' "$node"
  rpc_send "register V4 gc-$gcid" "$ADDRESS_BOOK" \
    'submitRegisterCnStakingContract(address,address,address)' "$node" "$v4" "$pdv2"
  info=$(abv1_info "$node")
  printf '%s\n' "$info" | grep -qi "$v4" || die "gc-$gcid ABv1 swap did not install V4"
  state_set "GC_${gcid}_SWAPPED" true
  fact "gc-$gcid AddressBookV1 entry" "migrated"
  subchange "stakingContract" "$v3" "$v4"
  subchange "rewardAddress" "$pdv1" "$pdv2"
}

run_stake_migration() {
  local node gcid count
  stage_header "01" 2 3 "Migrate CnStakingV3 and PublicDelegationV1 to V4 and V2"
  steps 6
  step "Deploy the production V4 infrastructure"
  deploy_v4_infrastructure
  step "Deploy CnStakingV4 and PublicDelegationV2 for each GC"
  while read -r node gcid; do deploy_v4_gc "$node" "$gcid"; done <<< "$(validator_nodes)"
  step "Redeem the GC operating shares from PublicDelegationV1"
  while read -r node gcid; do redeem_legacy_gc "$node" "$gcid"; done <<< "$(validator_nodes)"
  step "Claim the approved CnStakingV3 withdrawals"
  while read -r node gcid; do claim_legacy_gc "$node" "$gcid"; done <<< "$(validator_nodes)"
  step "Stake the released KAIA into PublicDelegationV2"
  while read -r node gcid; do stake_v4_gc "$node" "$gcid"; done <<< "$(validator_nodes)"
  step "Replace the AddressBookV1 entries"
  count=0
  while read -r node gcid; do swap_abv1_gc "$node" "$gcid"; count=$((count + 1)); done <<< "$(validator_nodes)"
  fact "AddressBookV1 result" "$count entries now point to production CnStakingV4 / PublicDelegationV2"
  state_set STEP2_COMPLETE true
  stage_done
}

deploy_abv2_data() {
  local impl_bin data_bin epoch args impl snapshot abv1 bls ctor kpf data
  impl=$(state_get ABV2_IMPL)
  if ! has_live_contract "$impl"; then
    impl_bin=$(binding_bin "$KAIACODE/contracts/bindings/addressbookv2/AddressBookV2.go")
    epoch=${HOMI_VRANK_EPOCH:-86400}; [ -n "$epoch" ] || epoch=86400
    args=$(cast abi-encode 'constructor(uint256)' "$epoch")
    impl=$(deploy_contract_once ABV2_IMPL "deploy ABv2 impl" "${impl_bin}${args#0x}")
  fi
  data=$(state_get ABV2_DATA)
  if has_live_contract "$data"; then printf '%s\n' "$data"; return; fi
  snapshot=$(mktemp "${TMPDIR:-/tmp}/abv2-snapshot.XXXXXX.json") || die "cannot create snapshot"
  abv1=$(cast call "$ADDRESS_BOOK" \
    'getAllAddressInfo()(address[],address[],address[],address,address)' --rpc-url "$RPC" 2>/dev/null)
  bls=$(cast call "$KIP113" 'getAllBlsInfo()(address[],(bytes,bytes)[])' --rpc-url "$RPC" 2>/dev/null)
  kpf=$(state_get KPF)
  ABV1_ALL="$abv1" BLS="$bls" VAL_ACTIVE="$VAL_ACTIVE" \
  INITIAL_OWNER="$ADMIN" INITIAL_SUSPENDER="$ADMIN" INITIAL_CONFIGURATOR="$ADMIN" \
  KEF_ADDRESS="$(state_get KEF)" KIF_ADDRESS="$(state_get KIF)" KPF_ADDRESS="$kpf" \
    python3 "$SNAPSHOT_TOOL" > "$snapshot" || { rm -f "$snapshot"; die "cannot build ABv2 snapshot"; }
  data_bin=$(binding_bin "$KAIACODE/contracts/bindings/abv2data/ABv2DataContract.go")
  ctor=$(python3 "$SNAPSHOT_TOOL" --ctor "$snapshot") || { rm -f "$snapshot"; die "cannot encode ABv2 snapshot"; }
  args=$(cast abi-encode \
    'constructor(address,(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,address,address,address[],(address,address,address,address,uint256,uint256,(bytes,bytes),string,string,uint8)[]))' \
    "$impl" "$ctor") || { rm -f "$snapshot"; die "cannot ABI-encode ABv2DataContract"; }
  rm -f "$snapshot"
  data=$(deploy_contract_once ABV2_DATA "deploy ABv2 data" "${data_bin}${args#0x}")
  printf '%s\n' "$data"
}

run_abv2_transition() {
  local data active now code node gcid v4 pdv2 state count
  stage_header "01" 3 3 "Publish AddressBookV2 migration data and activate the fork"
  steps 5
  step "Read the final AddressBookV1 council"
  count=$(validator_nodes | grep -c . | tr -d ' ')
  fact "migration source" "$count production CnStakingV4 / PublicDelegationV2 entries"
  fact "BLS source" "KIP113 at $KIP113"
  step "Deploy AddressBookV2 and ABv2DataContract"
  data=$(deploy_abv2_data)
  fact "AddressBookV2 implementation" "$(state_get ABV2_IMPL)"
  fact "ABv2DataContract" "$data"
  step "Register the migration data before the fork parent"
  register_record ABv2DataContract "$data" >/dev/null
  active=$(rpc_call "$REGISTRY" 'getActiveAddr(string)(address)' ABv2DataContract)
  fact "Registry.getActiveAddr(ABv2DataContract)" "$active"
  now=$(cast block-number --rpc-url "$RPC")
  [ "$now" -le $((FORK_BLOCK - 2)) ] \
    || die "ABv2DataContract became active too late (head=$now, fork parent=$((FORK_BLOCK - 1)))"
  step "Wait for the configured permissionless fork"
  wait_until_block "$FORK_BLOCK"
  now=$(cast block-number --rpc-url "$RPC")
  fact "permissionless fork" "active at block $now"
  step "Verify AddressBookV2 and the migrated validators"
  code=$(cast code "$ADDRESS_BOOK" --rpc-url "$RPC")
  [ $(((${#code} - 2) / 2)) -lt 1000 ] || die "0x400 was not replaced by the ABv2 proxy"
  count=0
  while read -r node gcid; do
    v4=$(state_get "GC_${gcid}_V4"); pdv2=$(state_get "GC_${gcid}_PDV2")
    state=$(rpc_call "$ADDRESS_BOOK" 'getNodeState(address)(uint8)' "$node" | awk '{print $1}')
    [ "$state" = "$VAL_ACTIVE" ] || die "gc-$gcid is not ValActive after the fork: $state"
    cast call "$ADDRESS_BOOK" 'getCnInfo(address)(address,address,bool)' "$node" --rpc-url "$RPC" 2>/dev/null \
      | grep -qi "$v4" || die "gc-$gcid ABv2 staking contract mismatch"
    fact "gc-$gcid" "ValActive; V4 $(short "$v4"); PDV2 $(short "$pdv2")"
    count=$((count + 1))
  done <<< "$(validator_nodes)"
  fact "AddressBookV2 result" "$count migrated validators active"
  state_set STEP3_COMPLETE true
  stage_done
}

render_print() {
  local node gcid v3 pdv1 v4 pdv2 moved status
  load_env
  initialize_state
  printf 'Permissionless migration\n\n'
  printf '  chainId: %s\n  head: %s\n  fork block: %s\n' "$CHAIN_ID" "$HEAD" "$FORK_BLOCK"
  if [ "$HEAD" -ge "$FORK_BLOCK" ]; then status=active; else status=pre-fork; fi
  printf '  status: %s\n\nInfrastructure\n\n' "$status"
  printf '  CnStakingV4 implementation: %s (block %s)\n' "$(state_get CN_IMPL)" "$(state_get CN_IMPL_BLOCK)"
  printf '  PublicDelegationV2 implementation: %s (block %s)\n' "$(state_get PD_IMPL)" "$(state_get PD_IMPL_BLOCK)"
  printf '  CnStakingV4Factory: %s (block %s)\n' "$(state_get V4_FACTORY)" "$(state_get V4_FACTORY_BLOCK)"
  printf '  AddressBookV2 implementation: %s (block %s)\n' "$(state_get ABV2_IMPL)" "$(state_get ABV2_IMPL_BLOCK)"
  printf '  ABv2DataContract: %s (block %s)\n\nGC migrations\n\n' "$(state_get ABV2_DATA)" "$(state_get ABV2_DATA_BLOCK)"
  while read -r node gcid; do
    v3=$(state_get "GC_${gcid}_V3"); pdv1=$(state_get "GC_${gcid}_PDV1")
    v4=$(state_get "GC_${gcid}_V4"); pdv2=$(state_get "GC_${gcid}_PDV2")
    moved=$(state_get "GC_${gcid}_MIGRATED_VALUE")
    printf '  gc-%s: %s\n' "$gcid" "$node"
    printf '    legacy: TestCnStakingV3 %s (block %s)\n' "$v3" "$(state_get "GC_${gcid}_V3_BLOCK")"
    printf '    legacy: PublicDelegationV1 %s (block %s)\n' "$pdv1" "$(state_get "GC_${gcid}_PDV1_BLOCK")"
    printf '    current: CnStakingV4 %s (block %s)\n' "$v4" "$(state_get "GC_${gcid}_V4_BLOCK")"
    printf '    current: PublicDelegationV2 %s (block %s)\n' "$pdv2" "$(state_get "GC_${gcid}_PDV2_BLOCK")"
    if [[ $moved =~ ^[0-9]+$ ]]; then printf '    moved: %s KAIA\n' "$(kaia "$moved")"; fi
    printf '\n'
  done <<< "$(validator_nodes)"
}

print_output() {
  local save=false arg output_dir output_file statuses
  for arg in "$@"; do case "$arg" in --save) save=true ;; *) die "unknown print option: $arg (use --save)" ;; esac; done
  if [ "$save" = false ]; then render_print; return; fi
  output_dir=${GOVSETUP_OUTPUT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"}
  mkdir -p "$output_dir" || die "cannot create output directory: $output_dir"
  output_file="$output_dir/01-print-$(date +%Y%m%d-%H%M%S).txt"
  render_print | tee "$output_file"
  statuses=("${PIPESTATUS[@]}")
  [ "${statuses[0]}" -eq 0 ] || return "${statuses[0]}"
  [ "${statuses[1]}" -eq 0 ] || return "${statuses[1]}"
  printf 'stored print output: %s\n' "$output_file" >&2
}

main() {
  if [ "${1:-}" = print ]; then shift; print_output "$@"; return; fi
  [ "$#" -eq 0 ] || die "setup 01 accepts no arguments except: print [--save]"
  tx_counter_init
  trap tx_counter_cleanup EXIT
  load_env
  initialize_state
  preflight
  if [ "$(state_get STEP1_COMPLETE)" = true ]; then
    stage_header "01" 1 3 "Prepare the legacy AddressBookV1 state"
    fact "status" "already complete"
    printf '\n'
  else
    run_legacy_state
  fi
  if [ "$(state_get STEP2_COMPLETE)" = true ]; then
    stage_header "01" 2 3 "Migrate CnStakingV3 and PublicDelegationV1 to V4 and V2"
    fact "status" "already complete"
    printf '\n'
  else
    run_stake_migration
  fi
  if [ "$(state_get STEP3_COMPLETE)" = true ]; then
    stage_header "01" 3 3 "Publish AddressBookV2 migration data and activate the fork"
    fact "status" "already complete"
    printf '\n'
  else
    run_abv2_transition
  fi
  printf 'Inspect: ./11_govsetup.sh 01 print [--save]\n\n'
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
