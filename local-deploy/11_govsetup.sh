#!/bin/bash
# Run a numbered local-governance setup workflow from gov_setup/NN_*.sh.
#
#   01_permless_migration_setup
#       Complete the deferred AddressBook V1 -> permissionless AddressBook V2
#       migration and verify the naturally scheduled fork.
#
# Setups are discovered from gov_setup/NN_*.sh, so adding one needs no change here.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || exit 1
cd "$SCRIPT_DIR" || exit 1
SETUPS_DIR="$SCRIPT_DIR/gov_setup"

list_setups() {
  local path name
  for path in "$SETUPS_DIR"/[0-9][0-9]_*.sh; do
    [ -f "$path" ] || continue
    name=${path##*/}
    printf '%s\n' "${name%.sh}"
  done
}

setup_path() {
  local query=$1 path name number
  [[ $query =~ ^[0-9][0-9]$ ]] || return 1
  for path in "$SETUPS_DIR"/[0-9][0-9]_*.sh; do
    [ -f "$path" ] || continue
    name=${path##*/}; name=${name%.sh}
    number=${name%%_*}
    if [ "$query" = "$number" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

usage() {
  cat <<USAGE
Usage: $0 <setup-number> [setup-command] [options]
       $0 list

Run one local-governance setup selected by its two-digit number.

  01_permless_migration_setup
      Complete the deferred permissionless migration as one workflow:

      1. Build the pre-fork AddressBookV1 council with TestCnStakingV3 and the
         production PublicDelegationV1, then create GC and user stakes.
      2. Deploy production V4/PDV2, redeem and claim each GC-owned PDV1 stake,
         stake the same KAIA into PDV2, and replace each AddressBookV1 entry.
      3. Deploy and register ABv2DataContract, wait for the configured fork,
         then verify AddressBookV2 and every migrated validator.

Commands:
  01                         run 01_permless_migration_setup
  01 --save-log              run and save the complete console log
  01 --verbose               include per-contract and per-transaction details
  01 print                   print legacy/current addresses and deploy blocks
  01 print --save            print and save under gov_setup/logs
  list                       show the available setup scripts

Options:
  --save-log                 save stdout and stderr from the complete command
  --verbose                  show tx hashes, gas, addresses and other debug details
  print --save               save print output as .txt

PRECONDITION: Setup 01 requires PERMISSIONLESS_MODE=deferred and must start
before the configured permissionless fork activates. It does not override the
fork block or restart the nodes.

Setups:
$(list_setups | sed 's/^/  /')

Examples:
  $0 01
  $0 01 --save-log
  $0 01 --verbose
  $0 01 print
  $0 01 print --save
USAGE
}

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  '') usage; exit 1 ;;
  list) list_setups; exit 0 ;;
  *)
    name=$1; shift
    path=$(setup_path "$name")
    [ -n "$path" ] || { echo "unknown setup number: $name" >&2; usage; exit 1; }
    save_log=false
    verbose=0
    args=()
    for arg in "$@"; do
      case "$arg" in
        --save-log) save_log=true ;;
        --verbose) verbose=1 ;;
        *) args+=("$arg") ;;
      esac
    done

    if [ "$save_log" = true ]; then
      log_dir=${GOVSETUP_LOG_DIR:-"$SETUPS_DIR/logs"}
      mkdir -p "$log_dir" || exit 1
      log_file="$log_dir/${name}-$(date +%Y%m%d-%H%M%S).log"
      printf 'saving command log: %s\n' "$log_file" >&2
      GOVSETUP_VERBOSE=$verbose "$path" "${args[@]}" 2>&1 | tee "$log_file"
      statuses=("${PIPESTATUS[@]}")
      [ "${statuses[0]}" -eq 0 ] || exit "${statuses[0]}"
      exit "${statuses[1]}"
    fi

    GOVSETUP_VERBOSE=$verbose "$path" "${args[@]}"
    ;;
esac
