#!/usr/bin/env python3
"""Build and inspect ABv2DataContract InitData snapshots."""

import argparse
import ast
import json
import os
import re
import sys


CAST_HEX = re.compile(r"\b0x[0-9a-fA-F]+\b")
CAST_INT_HINT = re.compile(r"\b(\d+)\s*\[[^\]]*\]")


def parse_cast(raw):
    """Turn cast's tuple/array rendering into Python values."""
    normalized = CAST_HEX.sub(lambda match: repr(match.group(0)), raw.strip())
    normalized = CAST_INT_HINT.sub(r"\1", normalized)
    return ast.literal_eval(normalized)


def parse_lines(raw):
    """Parse cast output that contains one return value per line."""
    return [parse_cast(line) for line in raw.splitlines() if line.strip()]


def require_length(label, values, minimum):
    if len(values) < minimum:
        raise ValueError(
            f"{label} returned {len(values)} value(s); expected at least {minimum}"
        )


def require_aligned(label, *values):
    lengths = [len(value) for value in values]
    if len(set(lengths)) != 1:
        raise ValueError(f"{label} arrays have different lengths: {lengths}")


def parse_init_data(raw):
    data = parse_cast(raw)
    require_length("getInitData", data, 15)
    require_aligned("getInitData node", data[13], data[14])
    for node_id, info in zip(data[13], data[14]):
        require_length(f"validator {node_id}", info, 10)
    return data


def load_json(path):
    with open(path, encoding="utf-8") as source:
        return json.load(source)


def cast_string(value):
    """Quote a string for Foundry's tuple parser."""
    return json.dumps(value, ensure_ascii=False)


def emit_ctor(path):
    snapshot = load_json(path)
    node_ids = snapshot["nodeIds"]
    infos = snapshot["infos"]
    require_aligned("snapshot node", node_ids, infos)

    encoded_infos = []
    for info in infos:
        encoded = dict(info)
        encoded["name"] = cast_string(info["name"])
        encoded["metadata"] = cast_string(info["metadata"])
        encoded_infos.append(
            "({manager},{stakingContract},{rewardAddress},{voterAddress},"
            "{timeoutAt},{gcId},({blsPublicKey},{blsPop}),{name},{metadata},{state})".format(
                **encoded
            )
        )

    fields = [
        snapshot["initialOwner"],
        snapshot["initialSuspender"],
        snapshot["initialConfigurator"],
        snapshot["pfsThreshold"],
        snapshot["cfsThreshold"],
        snapshot["pauseTimeout"],
        snapshot["idleTimeout"],
        snapshot["maxNodeCount"],
        snapshot["maxValActivePausedCount"],
        snapshot["maxCandReadyCount"],
        snapshot["kefAddress"],
        snapshot["kifAddress"],
        snapshot["kpfAddress"],
        f"[{','.join(node_ids)}]",
        f"[{','.join(encoded_infos)}]",
    ]
    print(f"({','.join(map(str, fields))})")


def build_snapshot():
    abv1 = parse_lines(os.environ["ABV1_ALL"])
    require_length("getAllAddressInfo", abv1, 3)
    node_ids, staking_contracts, reward_addresses = abv1[:3]
    require_aligned(
        "AddressBook V1 council", node_ids, staking_contracts, reward_addresses
    )

    bls_data = parse_lines(os.environ["BLS"])
    require_length("getAllBlsInfo", bls_data, 2)
    bls_ids, bls_keys = bls_data[:2]
    require_aligned("BLS registry", bls_ids, bls_keys)

    old_raw = os.environ.get("OLD", "").strip()
    old = parse_init_data(old_raw) if old_raw else None
    state = int(os.environ["VAL_ACTIVE"])

    bls_by_node = {address.lower(): key for address, key in zip(bls_ids, bls_keys)}
    previous_by_node = (
        {address.lower(): info for address, info in zip(old[13], old[14])}
        if old
        else {}
    )
    taken_gc_ids = {int(info[5]) for info in old[14]} if old else set()

    def next_gc_id():
        candidate = 1
        while candidate in taken_gc_ids:
            candidate += 1
        taken_gc_ids.add(candidate)
        return candidate

    infos = []
    for node_id, staking, reward in zip(node_ids, staking_contracts, reward_addresses):
        node_key = node_id.lower()
        previous = previous_by_node.get(node_key)
        if node_key not in bls_by_node:
            raise ValueError(
                f"no BLS key registered for {node_id} — cannot include it in ABv2DataContract"
            )
        public_key, proof_of_possession = bls_by_node[node_key]
        infos.append(
            {
                # homi sets manager == nodeId; preserve the old data when known.
                "manager": previous[0] if previous else node_id,
                "stakingContract": staking,
                "rewardAddress": reward,
                "voterAddress": previous[3] if previous else node_id,
                "timeoutAt": 0,
                "gcId": int(previous[5]) if previous else next_gc_id(),
                "blsPublicKey": public_key,
                "blsPop": proof_of_possession,
                "name": previous[7] if previous else "",
                "metadata": previous[8] if previous else "",
                "state": state,
                "_known": previous is not None,
            }
        )

    json.dump(
        {
            "implementation": None,
            "initialOwner": old[0] if old else os.environ["INITIAL_OWNER"],
            "initialSuspender": old[1] if old else os.environ["INITIAL_SUSPENDER"],
            "initialConfigurator": old[2] if old else os.environ["INITIAL_CONFIGURATOR"],
            "pfsThreshold": int(old[3]) if old else int(os.environ.get("PFS_THRESHOLD", "2")),
            "cfsThreshold": int(old[4]) if old else int(os.environ.get("CFS_THRESHOLD", "300")),
            "pauseTimeout": int(old[5]) if old else int(os.environ.get("PAUSE_TIMEOUT", "28800")),
            "idleTimeout": int(old[6]) if old else int(os.environ.get("IDLE_TIMEOUT", "2592000")),
            "maxNodeCount": int(old[7]) if old else int(os.environ.get("MAX_NODE_COUNT", "100")),
            "maxValActivePausedCount": int(old[8]) if old else int(os.environ.get("MAX_ACTIVE_PAUSED", "50")),
            "maxCandReadyCount": int(old[9]) if old else int(os.environ.get("MAX_CAND_READY", "3")),
            "kefAddress": old[10] if old else os.environ["KEF_ADDRESS"],
            "kifAddress": old[11] if old else os.environ["KIF_ADDRESS"],
            "kpfAddress": old[12] if old else os.environ["KPF_ADDRESS"],
            "nodeIds": list(node_ids),
            "infos": infos,
        },
        sys.stdout,
        indent=2,
    )
    print()


def snapshot_triples(path):
    snapshot = load_json(path)
    node_ids = snapshot["nodeIds"]
    infos = snapshot["infos"]
    require_aligned("snapshot node", node_ids, infos)
    return sorted(
        (node.lower(), info["stakingContract"].lower(), info["rewardAddress"].lower())
        for node, info in zip(node_ids, infos)
    )


def live_triples(raw):
    data = parse_init_data(raw)
    return sorted(
        (node.lower(), info[1].lower(), info[2].lower())
        for node, info in zip(data[13], data[14])
    )


def emit_validators(raw):
    data = parse_init_data(raw)
    for node_id, info in zip(data[13], data[14]):
        print(node_id, info[1], info[2], info[5])


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--ctor", metavar="SNAPSHOT")
    action.add_argument("--same-as", metavar="SNAPSHOT")
    action.add_argument("--live-triples", action="store_true")
    action.add_argument("--node-count", action="store_true")
    action.add_argument("--validators", action="store_true")
    return parser, parser.parse_args()


def main():
    parser, args = parse_args()
    try:
        if args.ctor:
            emit_ctor(args.ctor)
        elif args.same_as:
            expected = [list(item) for item in snapshot_triples(args.same_as)]
            return 0 if json.load(sys.stdin) == expected else 1
        elif args.live_triples:
            print(json.dumps(live_triples(sys.stdin.read())))
        elif args.node_count:
            print(len(parse_init_data(sys.stdin.read())[13]))
        elif args.validators:
            emit_validators(sys.stdin.read())
        else:
            build_snapshot()
    except (
        KeyError,
        OSError,
        SyntaxError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
    ) as error:
        parser.exit(2, f"snapshot.py: {error}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
