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
    def check_document(self, content):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "record.json"
            path.write_text(content)
            return run_cli(path)

    def test_json_types_survive_parsing(self):
        for field, value, rule in [
            ("owner", True, "invalid_text"), ("owner", False, "invalid_text"),
            ("owner", None, "invalid_text"), ("owner", 42, "invalid_text"),
            ("coaching_invited", "false", "invalid_boolean"),
            ("coaching_invited", "true", "invalid_boolean"),
            ("mode", True, "invalid_status"),
        ]:
            with self.subTest(field=field, value=value):
                case = json.loads((ROOT / "examples/supported.json").read_text())
                case[field] = value
                code, report = self.check_document(json.dumps(case))
                self.assertEqual((code, report["status"]), (2, "invalid"))
                self.assertIn(rule, [v["rule"] for v in report["violations"]])

    def test_nested_text_requires_json_string(self):
        case = json.loads((ROOT / "examples/supported.json").read_text())
        case["evidence"][0]["source"] = None
        code, report = self.check_document(json.dumps(case))
        self.assertEqual((code, report["status"]), (2, "invalid"))
        self.assertIn("case.evidence.1.source", [v["target"] for v in report["violations"]])

    def test_quoted_boolean_and_null_are_valid_text(self):
        case = json.loads((ROOT / "examples/supported.json").read_text())
        for text in ["true", "false", "null", "Newline\n日本語 😀"]:
            with self.subTest(text=text):
                case["owner"] = text
                code, report = self.check_document(json.dumps(case))
                self.assertEqual((code, report["status"]), (0, "pass"))

    def test_valid_utf8_scalar_boundaries(self):
        case = json.loads((ROOT / "examples/supported.json").read_text())
        for scalar in [0x7f, 0x80, 0x7ff, 0x800, 0xd7ff, 0xe000, 0xffff, 0x10000, 0x10ffff]:
            with self.subTest(scalar=hex(scalar)):
                case["owner"] = "Owner " + chr(scalar)
                code, report = self.check_document(json.dumps(case, ensure_ascii=False))
                self.assertEqual((code, report["status"]), (0, "pass"))

    def test_strict_json_syntax(self):
        content = (ROOT / "examples/supported.json").read_text().strip()
        malformed = ["\ufeff" + content, content[:-1] + ",}",
                     '{"coaching_invited":01}', '{"coaching_invited":1.}',
                     '{"owner":"a","owner":"b"}', '{}\u00a0',
                     '{"owner":"\\ud800"}', '{"owner":"\\udfff"}']
        malformed += [content.replace('"Improve onboarding"', '"Improve' + chr(c) + 'onboarding"')
                      for c in [0, 9, 10, 13, 28]]
        for text in malformed:
            with self.subTest(document=repr(text[:40])):
                code, report = self.check_document(text)
                self.assertEqual((code, report["status"]), (2, "invalid"))
                self.assertIn("input_error", [v["rule"] for v in report["violations"]])

    def test_invalid_utf8_file_is_rejected_before_decode(self):
        content = (ROOT / "examples/supported.json").read_bytes()
        for bad in [b"\xff", b"\x80", b"\xc2\xff", b"\xe2\x82", b"\xc0\xaf",
                    b"\xe0\x81\x81", b"\xf0\x80\x81\x81", b"\xed\xa0\x80", b"\xf4\x90\x80\x80"]:
            with self.subTest(bytes=bad), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "bad-encoding.json"
                path.write_bytes(content.replace(b"Product lead", bad))
                code, report = run_cli(path)
                self.assertEqual((code, report["status"]), (2, "invalid"))
                self.assertIn("input_error", [v["rule"] for v in report["violations"]])

    def test_nine_fixtures_outside_checkout(self):
        expected = {
            "supported": (0, "pass"), "defeated": (1, "blocked"),
            "withdrawn": (0, "pass"), "no-finding": (0, "pass"),
            "hypothesis": (0, "pass"), "rejection-trap": (1, "blocked"),
            "false-evidence": (0, "pass"), "plausible-fabrication": (0, "pass"),
            "incomplete": (2, "invalid"),
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
        self.assertEqual(report["scope"], "declared_record_only")
        self.assertIs(report["evidence_verified"], False)

    def test_missing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            code, report = run_cli(Path(directory) / "not-present.json")
            self.assertEqual((code, report["status"]), (2, "invalid"))


if __name__ == "__main__":
    unittest.main()
