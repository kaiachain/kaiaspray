#!/bin/bash
# Shared helpers for the numbered gov_setup workflows.
#
# Setup scripts source this file and report their internal stages with
# step/kv/ok/skip, so that a reader of the terminal output can tell what is
# running, what it read, and what it changed.

set -o pipefail

# Foundry nightly warnings are not actionable for this workflow and otherwise
# drown out the setup summary because almost every read is a `cast` command.
export FOUNDRY_DISABLE_NIGHTLY_WARNING=${FOUNDRY_DISABLE_NIGHTLY_WARNING:-1}
GOVSETUP_VERBOSE=${GOVSETUP_VERBOSE:-0}

GOV_SETUP_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) \
  || { echo "cannot resolve gov_setup directory" >&2; exit 1; }
LOCAL_DEPLOY_DIR=$(cd "$GOV_SETUP_DIR/.." && pwd) \
  || { echo "cannot resolve local-deploy directory" >&2; exit 1; }
SNAPSHOT_TOOL="$GOV_SETUP_DIR/snapshot.py"

# ---------------------------------------------------------------- presentation

if [ -t 1 ]; then
  C_STEP=$'\033[1;33m'; C_OK=$'\033[32m'; C_SKIP=$'\033[90m'
  C_WARN=$'\033[33m';   C_ERR=$'\033[31m'; C_OFF=$'\033[0m'
else
  C_STEP=; C_OK=; C_SKIP=; C_WARN=; C_ERR=; C_OFF=
fi

RULE='══════════════════════════════════════════════════════════'
STEP_TOTAL=0 STEP_NO=0 STEP_START=0 STAGE_TX_START=0

verbose() { [ "$GOVSETUP_VERBOSE" = 1 ]; }

tx_counter_init() {
  GOVSETUP_TX_FILE=$(mktemp "${TMPDIR:-/tmp}/govsetup-tx.XXXXXX") \
    || die "cannot create transaction counter"
  export GOVSETUP_TX_FILE
}
tx_counter_cleanup() { [ -n "${GOVSETUP_TX_FILE:-}" ] && rm -f "$GOVSETUP_TX_FILE"; }
tx_count() {
  if [ -n "${GOVSETUP_TX_FILE:-}" ] && [ -f "$GOVSETUP_TX_FILE" ]; then
    wc -l < "$GOVSETUP_TX_FILE" | tr -d ' '
  else
    printf '0\n'
  fi
}

stage_header() {
  STEP_START=$(date +%s)
  STAGE_TX_START=$(tx_count)
  printf -- '- Step %s/%s: %s\n' "$2" "$3" "$4"
}

stage_done() {
  local now transactions
  now=$(tx_count)
  transactions=$(( now - STAGE_TX_START ))
  printf '  - Transactions: %s\n' "$transactions"
  printf '  - Elapsed: %ss\n\n' "$(( $(date +%s) - STEP_START ))"
}

# Kept for detailed output and for the independent `print` catalogue.
hdr()   { STEP_START=$(date +%s); printf '\n%s · %s\n%s\n\n' "$1" "$2" "$RULE"; }
steps() { STEP_TOTAL=$1 STEP_NO=0; }
step()  {
  local title=$1
  STEP_NO=$((STEP_NO+1))
  if verbose; then
    printf '%s STEP %d/%d  %s%s\n' "$C_STEP" "$STEP_NO" "$STEP_TOTAL" "$title" "$C_OFF"
  else
    printf '  - [%d/%d]: %s\n' "$STEP_NO" "$STEP_TOTAL" "$title"
  fi
}
fact()      { printf '    - %s: %s\n' "$1" "$2"; }
fact_line() { printf '    - %s\n' "$1"; }
subfact()   { printf '      - %s: %s\n' "$1" "$2"; }
change()    { printf '    - %s: %s -> %s\n' "$1" "$2" "$3"; }
subchange() { printf '      - %s: %s -> %s\n' "$1" "$2" "$3"; }
group() { verbose && printf '   %s──%s %s\n' "$C_SKIP" "$C_OFF" "$1"; return 0; }
kv()    { verbose && printf '   %-16s %s\n' "$1" "$2"; return 0; }
ok()    { verbose && printf '   %s✔%s %s\n\n' "$C_OK" "$C_OFF" "$1"; return 0; }
skip()  {
  if verbose; then printf '   %s↷ skipped — %s%s\n\n' "$C_SKIP" "$1" "$C_OFF"
  else printf '    - No change: %s\n' "$1"
  fi
}
noop()  { verbose && printf '   %-16s %s↷ %s%s\n' "$1" "$C_SKIP" "$2" "$C_OFF"; return 0; }
progress() {
  if verbose; then printf '   %s\n' "$1"
  else printf '    - Progress: %s\n' "$1"
  fi
}
warn()  {
  if verbose; then printf '   %s⚠ %s%s\n' "$C_WARN" "$1" "$C_OFF"
  else printf '    - Warning: %s\n' "$1"
  fi
}
die()   { printf '\n   %s✘ %s%s\n\n' "$C_ERR" "$1" "$C_OFF" >&2; exit 1; }
done_banner() { printf '%s\ndone · %d/%d steps · %ds\n\n' "$RULE" "$STEP_NO" "$STEP_TOTAL" "$(( $(date +%s) - STEP_START ))"; }

short() { printf '%s…%s' "${1:0:6}" "${1: -4}"; }
# Addresses come back checksummed from calls but lowercase from receipts.
same_addr() {
  [ "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" = \
    "$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')" ]
}
kaia() {
  python3 -c 'import sys; print(f"{int(sys.argv[1])/10**18:,.9f}".rstrip("0").rstrip("."))' "${1:-0}"
}
is_positive_integer() { [[ $1 =~ ^[1-9][0-9]*$ ]]; }

has_contract_code() {
  [ -n "$1" ] && [ "$1" != "0x" ] && [ "$1" != "0x0" ]
}

# Print the first block at which an address has runtime code. This is 0 for
# permissionless contracts allocated by homi in genesis, and the receipt block
# for contracts deployed later by a setup. The lookup deliberately uses the
# running chain instead of properties.sh so the result can be handed to an
# external indexer as its deployBlock.
contract_deploy_block() { # contract_deploy_block <address> [head]
  local address=$1 head=${2:-} code low high mid
  [ -n "$address" ] && ! same_addr "$address" "$ZERO" || return 1
  if [ -z "$head" ]; then
    head=$(cast block-number --rpc-url "$RPC" 2>/dev/null) || return 2
  fi

  code=$(cast code "$address" --block "$head" --rpc-url "$RPC" 2>/dev/null) || return 2
  has_contract_code "$code" || return 1

  code=$(cast code "$address" --block 0 --rpc-url "$RPC" 2>/dev/null) || return 2
  if has_contract_code "$code"; then
    printf '0\n'
    return 0
  fi

  low=1; high=$head
  while [ "$low" -lt "$high" ]; do
    mid=$(( (low + high) / 2 ))
    code=$(cast code "$address" --block "$mid" --rpc-url "$RPC" 2>/dev/null) || return 2
    if has_contract_code "$code"; then
      high=$mid
    else
      low=$(( mid + 1 ))
    fi
  done
  printf '%s\n' "$low"
}

# Count logs matching one event signature on one contract. Keeping this next to
# contract_deploy_block makes the print command a useful fixture audit as well
# as a contract catalogue exporter.
event_log_count() { # event_log_count <address> <from-block> <to-block> <signature>
  local address=$1 from=$2 to=$3 signature=$4 logs
  logs=$(cast logs --address "$address" --from-block "$from" --to-block "$to" \
    --rpc-url "$RPC" --json "$signature" 2>/dev/null) || return 1
  python3 -c 'import json, sys; print(len(json.load(sys.stdin)))' <<< "$logs"
}

# ------------------------------------------------------------------- constants

# shellcheck disable=SC2034 # Used by scripts that source this library.
ADDRESS_BOOK=0x0000000000000000000000000000000000000400
REGISTRY=0x0000000000000000000000000000000000000401
ZERO=0x0000000000000000000000000000000000000000

# Minimal stub returning uint256(1) for every call. AddressBook V1 will not
# activate until a PoC (KIF) and a KIR (KEF) contract are registered, and it
# version-checks them via getPocVersion()/getKirVersion(). Mainnet has the real
# funds here; locally the node only ever reads the addresses back out.
# shellcheck disable=SC2034 # Used by scripts that source this library.
FUND_STUB_INITCODE=0x69600160005260206000f3600052600a6016f3

INITDATA_SIG='getInitData()((address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,address,address,address[],(address,address,address,address,uint256,uint256,(bytes,bytes),string,string,uint8)[]))'

# ----------------------------------------------------------------- environment

load_env() {
  local properties="$LOCAL_DEPLOY_DIR/properties.sh" rpc_port
  [ -f "$properties" ] || die "properties.sh not found under $LOCAL_DEPLOY_DIR."
  # shellcheck source=/dev/null
  source "$properties"
  command -v cast >/dev/null 2>&1 || die "cast (foundry) is required: https://getfoundry.sh"
  [ -d "$HOMEDIR/cn1" ] || die "cn1 not found under HOMEDIR ($HOMEDIR). Run 0_kaia_setup.sh first."

  rpc_port=$(sed -n 's/^RPC_PORT=\([0-9]*\)$/\1/p' "$HOMEDIR/cn1/conf/kcnd.conf")
  is_positive_integer "$rpc_port" || die "cannot read RPC_PORT from $HOMEDIR/cn1/conf/kcnd.conf"
  RPC="http://localhost:$rpc_port"
  # shellcheck disable=SC2034 # Used by scripts that source this library.
  CHAIN_ID=$(cast chain-id --rpc-url "$RPC" 2>/dev/null) \
    || die "cannot reach the node at $RPC. Is it running? (./3_ccstart.sh)"
  HEAD=$(cast block-number --rpc-url "$RPC")

  # cn1's nodekey is the AddressBook admin patched in by --patch-address-book.
  # Setup 01 also uses each validator nodekey as that GC's migration owner.
  [ -f "$HOMEDIR/homi-output/keys/nodekey1" ] \
    || die "cn1 nodekey not found under $HOMEDIR/homi-output/keys"
  ADMIN_KEY=0x$(cat "$HOMEDIR/homi-output/keys/nodekey1")
  # shellcheck disable=SC2034 # Used by scripts that source this library.
  ADMIN=$(cast wallet address --private-key "$ADMIN_KEY")

  # Read the effective fork block from the running chain rather than trusting
  # the value in properties.sh.
  FORK_BLOCK=$(cast rpc kaia_getChainConfig --rpc-url "$RPC" 2>/dev/null | python3 -c '
import json, sys
print(json.load(sys.stdin).get("permissionlessCompatibleBlock", 0))')
  [[ $FORK_BLOCK =~ ^[0-9]+$ ]] || die "node returned an invalid permissionless fork block: $FORK_BLOCK"
}

require_deferred() {
  [ "${PERMISSIONLESS_MODE:-off}" = "deferred" ] \
    || die "PERMISSIONLESS_MODE must be 'deferred' (currently '${PERMISSIONLESS_MODE:-off}')."
  is_positive_integer "$FORK_BLOCK" \
    || die "permissionless fork block must be greater than zero (currently '$FORK_BLOCK')."
  [ "$HEAD" -lt "$FORK_BLOCK" ] \
    || die "setup 01 must run before the permissionless fork activates (head=$HEAD >= fork=$FORK_BLOCK). Recreate the test network with a future HOMI_PERMISSIONLESS_BLOCK."
}

# ------------------------------------------------------------------------- rpc

rpc_call() { # rpc_call <to> <sig> [args...]
  local to=$1 sig=$2; shift 2
  cast call "$to" "$sig" "$@" --rpc-url "$RPC" 2>/dev/null | head -1
}

# _tx <label> <emit: line|addr> <cast send args...>
# Prints one progress line, aborts on a reverted receipt. With 'addr' it also
# echoes the new contract address on stdout (progress goes to stderr).
_tx() {
  local label=$1 emit=$2; shift 2
  local out
  out=$(cast send --private-key "${SEND_KEY:-$ADMIN_KEY}" --rpc-url "$RPC" --json "$@" 2>&1) || {
    printf '   %-16s %s✘%s\n' "$label" "$C_ERR" "$C_OFF" >&2
    printf '%s\n' "$out" | sed 's/^/       /' >&2
    return 1
  }
  LABEL=$label EMIT=$emit VERBOSE=$GOVSETUP_VERBOSE python3 -c '
import json, os, sys
d = json.loads(sys.stdin.read())
h = d["transactionHash"]
if int(d.get("status", "0x0"), 16) != 1:
    print("   %-16s reverted (tx %s)" % (os.environ["LABEL"], h), file=sys.stderr); sys.exit(1)
if os.environ["VERBOSE"] == "1":
    if os.environ["EMIT"] in ("addr", "addr_block"):
        tail = "→ %s" % d["contractAddress"]
    else:
        gas = format(int(d["gasUsed"], 16), ",")
        tail = "→ tx %s…%s  block %d  gas %s" % (h[:8], h[-4:], int(d["blockNumber"], 16), gas)
    print("   %-16s %s" % (os.environ["LABEL"], tail), file=sys.stderr)
if os.environ["EMIT"] == "addr": print(d["contractAddress"])
if os.environ["EMIT"] == "addr_block":
    print("%s %d" % (d["contractAddress"], int(d["blockNumber"], 16)))
' <<<"$out" || return 1
  [ -n "${GOVSETUP_TX_FILE:-}" ] && printf '1\n' >> "$GOVSETUP_TX_FILE"
}

# rpc_send <label> <to> <sig> [args...]   — honours SEND_KEY / SEND_VALUE
rpc_send() {
  local label=$1 to=$2 sig=$3; shift 3
  _tx "$label" line "$to" "$sig" "$@" ${SEND_VALUE:+--value "$SEND_VALUE"} || die "$label failed"
}

# rpc_deploy <label> <initcode>  — echoes the address; check with || die
# NOTE: cast treats everything after --create as positional, so it goes last.
rpc_deploy() { _tx "$1" addr --create "$2"; }

# rpc_deploy_with_block <label> <initcode> — echoes "address receiptBlock".
# Runtime fixtures persist the receipt block so later print calls do not need
# archive-node state to rediscover when their code first appeared.
rpc_deploy_with_block() { _tx "$1" addr_block --create "$2"; }

# --------------------------------------------------------------- validator data

# Print the private key whose address matches a validator node ID.
node_private_key() {
  local node_id=$1 keyfile key owner
  for keyfile in "$HOMEDIR"/homi-output/keys/nodekey[0-9]*; do
    [ -f "$keyfile" ] || continue
    key=0x$(cat "$keyfile")
    owner=$(cast wallet address --private-key "$key" 2>/dev/null) || continue
    if same_addr "$owner" "$node_id"; then
      printf '%s\n' "$key"
      return 0
    fi
  done
  return 1
}
