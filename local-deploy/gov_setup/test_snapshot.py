import contextlib
import io
import json
import os
import tempfile
import unittest
from unittest import mock

import snapshot


ADDRESS = "0x0000000000000000000000000000000000000001"
NODE = "0x0000000000000000000000000000000000000002"
STAKING = "0x0000000000000000000000000000000000000003"
REWARD = "0x0000000000000000000000000000000000000004"


def init_data(node_ids="[]", infos="[]"):
    return (
        f"({ADDRESS},{ADDRESS},{ADDRESS},1,2,3,4,10,2,3,"
        f"{ADDRESS},{ADDRESS},{ADDRESS},{node_ids},{infos})"
    )


class SnapshotTest(unittest.TestCase):
    def test_build_snapshot_without_genesis_abv2_data(self):
        env = {
            "ABV1_ALL": f"[{NODE}]\n[{STAKING}]\n[{REWARD}]",
            "BLS": f"[{NODE}]\n[(0x12,0x34)]",
            "VAL_ACTIVE": "6",
            "INITIAL_OWNER": ADDRESS,
            "INITIAL_SUSPENDER": ADDRESS,
            "INITIAL_CONFIGURATOR": ADDRESS,
            "KEF_ADDRESS": ADDRESS,
            "KIF_ADDRESS": ADDRESS,
            "KPF_ADDRESS": ADDRESS,
        }
        output = io.StringIO()
        with mock.patch.dict(os.environ, env, clear=True), contextlib.redirect_stdout(
            output
        ):
            snapshot.build_snapshot()

        result = json.loads(output.getvalue())
        self.assertEqual(result["initialOwner"], ADDRESS)
        self.assertEqual(result["pfsThreshold"], 2)
        self.assertEqual(result["cfsThreshold"], 300)
        self.assertEqual(result["nodeIds"], [NODE])
        self.assertEqual(result["infos"][0]["gcId"], 1)
        self.assertEqual(result["infos"][0]["state"], 6)

    def test_build_snapshot_for_new_validator(self):
        env = {
            "ABV1_ALL": f"[{NODE}]\n[{STAKING}]\n[{REWARD}]",
            "BLS": f"[{NODE}]\n[(0x12,0x34)]",
            "OLD": init_data(),
            "VAL_ACTIVE": "6",
        }
        output = io.StringIO()
        with mock.patch.dict(os.environ, env, clear=True), contextlib.redirect_stdout(
            output
        ):
            snapshot.build_snapshot()

        result = json.loads(output.getvalue())
        self.assertEqual(result["nodeIds"], [NODE])
        self.assertEqual(result["infos"][0]["stakingContract"], STAKING)
        self.assertEqual(result["infos"][0]["rewardAddress"], REWARD)
        self.assertEqual(result["infos"][0]["gcId"], 1)
        self.assertFalse(result["infos"][0]["_known"])

    def test_parse_init_data_rejects_misaligned_nodes(self):
        with self.assertRaisesRegex(ValueError, "different lengths"):
            snapshot.parse_init_data(init_data(f"[{NODE}]", "[]"))

    def test_emit_ctor_escapes_string_members(self):
        info = {
            "manager": NODE,
            "stakingContract": STAKING,
            "rewardAddress": REWARD,
            "voterAddress": NODE,
            "timeoutAt": 0,
            "gcId": 1,
            "blsPublicKey": "0x12",
            "blsPop": "0x34",
            "name": 'GC "One"',
            "metadata": "line\nbreak",
            "state": 6,
        }
        data = {
            "initialOwner": ADDRESS,
            "initialSuspender": ADDRESS,
            "initialConfigurator": ADDRESS,
            "pfsThreshold": 1,
            "cfsThreshold": 2,
            "pauseTimeout": 3,
            "idleTimeout": 4,
            "maxNodeCount": 10,
            "maxValActivePausedCount": 2,
            "maxCandReadyCount": 3,
            "kefAddress": ADDRESS,
            "kifAddress": ADDRESS,
            "kpfAddress": ADDRESS,
            "nodeIds": [NODE],
            "infos": [info],
        }

        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as target:
            json.dump(data, target)
            target.flush()
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                snapshot.emit_ctor(target.name)

        self.assertIn('"GC \\"One\\""', output.getvalue())
        self.assertIn('"line\\nbreak"', output.getvalue())

    def test_live_views_share_the_validated_parser(self):
        info = f'({NODE},{STAKING},{REWARD},{NODE},0,7,(0x12,0x34),"GC","",6)'
        raw = init_data(f"[{NODE}]", f"[{info}]")

        self.assertEqual(snapshot.live_triples(raw), [(NODE, STAKING, REWARD)])
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            snapshot.emit_validators(raw)
        self.assertEqual(output.getvalue().strip(), f"{NODE} {STAKING} {REWARD} 7")


if __name__ == "__main__":
    unittest.main()
