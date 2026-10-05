"""Regression checks for the real CLI, using only Python's standard library."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def run_cli(*args, cwd=None):
    result = subprocess.run(
        ["swipl", "-q", "-s", str(ROOT / "src/check.pl"), "--", *map(str, args)],
        cwd=cwd, capture_output=True, text=True, timeout=20,
    )
    return result.returncode, json.loads(result.stdout)


class CliTests(unittest.TestCase):
    def test_six_fixtures_outside_checkout(self):
        expected = {
            "supported": (0, "pass"), "defeated": (1, "blocked"),
            "withdrawn": (0, "pass"), "no-finding": (0, "pass"),
            "hypothesis": (0, "pass"), "rejection-trap": (1, "blocked"),
        }
        with tempfile.TemporaryDirectory() as outside:
            for name, outcome in expected.items():
                with self.subTest(fixture=name):
                    code, report = run_cli(ROOT / f"examples/{name}.json", cwd=outside)
                    self.assertEqual((code, report["status"]), outcome)

    def test_four_bad_documents(self):
        contents = ["", "{invalid", "{}", (ROOT / "examples/supported.json").read_text() + " {}"]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bad.json"
            for index, content in enumerate(contents):
                with self.subTest(document=index):
                    path.write_text(content)
                    code, report = run_cli(path)
                    self.assertEqual((code, report["status"]), (2, "invalid"))

    def test_missing_argument(self):
        code, report = run_cli()
        self.assertEqual((code, report["status"]), (2, "invalid"))

    def test_missing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            code, report = run_cli(Path(directory) / "not-present.json")
            self.assertEqual((code, report["status"]), (2, "invalid"))


if __name__ == "__main__":
    unittest.main()
