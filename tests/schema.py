"""Verify the published shape contract and generated schema freshness."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SchemaTests(unittest.TestCase):
    def test_export_describes_actual_typed_contract(self):
        result = subprocess.run(["swipl", "-q", "-s", "scripts/export_schema.pl"],
                                cwd=ROOT, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        schema = json.loads(result.stdout)
        props = schema["properties"]
        self.assertEqual(schema["additionalProperties"], False)
        self.assertEqual(props["owner"]["type"], "string")
        self.assertEqual(props["coaching_invited"]["type"], "boolean")
        self.assertEqual(props["mode"]["enum"], ["consulting", "coaching"])
        self.assertEqual(props["readings"]["items"]["properties"]["response"]["enum"],
                         ["unasked", "accepted", "rejected"])
        self.assertEqual(set(schema["required"]), {"id", "mode", "coaching_invited", "brief",
                         "desired_result", "owner", "lenses", "ordinary", "return_cut",
                         "evidence", "readings", "outcome"})
        version = (ROOT / "VERSION").read_text().strip()
        self.assertEqual(schema["$id"], f"https://maciejjankowski.com/zizkian/schema/record-{version}.schema.json")
        published = json.loads((ROOT / f"schema/record-{version}.schema.json").read_text())
        self.assertEqual(published, schema, "Regenerate the schema after changing schema/2")


if __name__ == "__main__":
    unittest.main()
