"""Check links, embedded checker results, source freshness and release integrity.

SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
"""
import hashlib
import json
import re
import subprocess
import zipfile
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

from build_release import DIST, ROOT, VERSION, check_prebuilt, digest, source_files


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.ids = set()
        self.duplicates = []
        self.proof = ""
        self.in_proof = False
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "td" and "data-label" in attrs:
            label = attrs["data-label"]
            ensure(bool(label.strip()) and label == ' '.join(label.split()), f"Malformed mobile table label: {label!r}")
        if "id" in attrs:
            if attrs["id"] in self.ids:
                self.duplicates.append(attrs["id"])
            self.ids.add(attrs["id"])
        for name in ("href", "src"):
            if name in attrs:
                self.links.append(attrs[name])
        if tag == "script" and attrs.get("id") == "proof-data":
            self.in_proof = True

    def handle_endtag(self, tag):
        if tag == "script":
            self.in_proof = False

    def handle_data(self, text):
        if self.in_proof:
            self.proof += text


def ensure(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    check_prebuilt()
    public = DIST / "zizkian"
    pages = {path: Page(path.read_text()) for path in sorted(public.glob("*.html"))}
    ensure(len(pages) == 14, "Expected landing page, browser lab and twelve document pages")
    checked = 0
    for path, page in pages.items():
        title = re.search(r'<title>(.*?)</title>', path.read_text(), flags=re.S)
        ensure(title and not title.group(1).strip().startswith('|'), f"Missing page title: {path.name}")
        ensure(not page.duplicates, f"Duplicate anchors in {path.name}: {page.duplicates}")
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                ensure(url.scheme in ("https", "http"), f"Unsupported URL: {link}")
                continue
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            if target.is_dir():
                target /= "index.html"
            ensure(target.is_relative_to(public.resolve()), f"Link escapes site: {link}")
            ensure(target.is_file(), f"Missing target in {path.name}: {link}")
            if url.fragment:
                ensure(target in pages and unquote(url.fragment) in pages[target].ids, f"Missing anchor in {path.name}: {link}")
            checked += 1
    llms = (public / "llms.txt").read_text()
    ensure(f"Version {VERSION}," in llms, "Stale llms.txt release version")
    for link in re.findall(r"\]\(([^)]+)\)", llms):
        url = urlsplit(link)
        if url.scheme or url.netloc:
            ensure(url.scheme in ("https", "http"), f"Unsupported llms.txt URL: {link}")
            continue
        target = (public / unquote(url.path)).resolve()
        ensure(target.is_relative_to(public.resolve()), f"Link escapes llms.txt site: {link}")
        ensure(target.is_file(), f"Missing llms.txt target: {link}")
        if url.fragment:
            ensure(target in pages and unquote(url.fragment) in pages[target].ids,
                   f"Missing llms.txt anchor: {link}")
        checked += 1
    data = json.loads(pages[public / "index.html"].proof)
    ensure(set(data) == {"supported", "defeated", "withdrawn"}, "Proof stages incomplete")
    for stage, recorded in data.items():
        path = ROOT / "examples" / (stage + ".json")
        result = subprocess.run(["swipl", "-q", "-s", str(ROOT / "src/check.pl"), "--", str(path)], capture_output=True, text=True)
        ensure(result.returncode == (1 if stage == "defeated" else 0), f"Unexpected proof exit: {stage}")
        ensure(recorded["report"] == json.loads(result.stdout), f"Stale report: {stage}")
        ensure(recorded["report"]["schema_version"] == VERSION, f"Report version differs from release: {stage}")
        ensure(recorded["report"]["evidence_verified"] is False, f"Report claims evidence verification: {stage}")
        ensure(recorded["case"] == json.loads(path.read_text()), f"Stale input: {stage}")
    guide = (ROOT / "docs/guide.md").read_text()
    diagrams = re.findall(r"```mermaid\n(.*?)```", guide, flags=re.S)
    charts = sorted((ROOT / "charts").glob("*.mmd"))
    ensure(len(diagrams) == len(charts) == 9, "Expected nine diagrams")
    ensure(all(a.strip() == b.read_text().strip() for a, b in zip(diagrams, charts)), "Chart sources differ from guide")
    exercises = guide.split("## 12. Exercises:")[1].split("## 13.")[0]
    ensure(len(re.findall(r"^\d+\. ", exercises, flags=re.M)) == 10, "Expected ten exercises")
    manifest = json.loads((public / "manifest.json").read_text())
    ensure(manifest["version"] == VERSION, "Wrong manifest version")
    actual = {path.relative_to(public).as_posix(): digest(path) for path in public.rglob("*") if path.is_file() and path != public / "manifest.json"}
    ensure(actual == manifest["sha256"], "Publication manifest mismatch")
    source = DIST / f"zizkian-{VERSION}.zip"
    website = DIST / f"zizkian-site-{VERSION}.zip"
    for path, base, files in ((source, ROOT, list(source_files())), (website, public, [p for p in public.rglob("*") if p.is_file()])):
        expected = {"zizkian/" + p.relative_to(base).as_posix(): p.read_bytes() for p in files}
        with zipfile.ZipFile(path) as archive:
            ensure(archive.testzip() is None, f"Corrupt archive: {path.name}")
            ensure(set(archive.namelist()) == set(expected), f"Archive contents differ: {path.name}")
            ensure(all(archive.read(name) == content for name, content in expected.items()), f"Archive bytes differ: {path.name}")
    ensure((public / "downloads" / source.name).read_bytes() == source.read_bytes(), "Public source download differs")
    checksums = ''.join(f"{digest(path)}  {path.name}\n" for path in (source, website))
    ensure((DIST / "SHA256SUMS").read_text() == checksums, "Archive checksum list differs")
    prohibited = ("/Users/mj", "_handoffs/", "P002", "discord.com/api/webhooks", "mailto:", "\u2014")
    for path in source_files():
        if 'vendor' in path.parts:
            continue  # Immutable third-party bytes are checked below, not edited prose.
        text = path.read_text()
        for token in prohibited:
            # The validator's own list is an intentional scan pattern.
            if path.name == "validate_release.py":
                continue
            ensure(token not in text, f"Private path or unsupported content in {path.relative_to(ROOT)}: {token!r}")
    vendor = ROOT / 'site/assets/vendor/swipl-8.2.1'
    vendor_manifest = json.loads((vendor / 'manifest.json').read_text())
    ensure({p.name for p in vendor.iterdir() if p.is_file() and p.name != 'manifest.json'} == set(vendor_manifest['sha256']), 'Unexpected vendor file inventory')
    for name, expected in vendor_manifest['sha256'].items():
        ensure(digest(vendor / name) == expected, f'Vendor bytes changed: {name}')
    print(f"Validated {len(pages)} pages, {checked} local links/assets, 3 live Prolog report comparisons, 9 charts, 10 exercises and both archives.")
    print("Browser rendering and external link availability are separate checks.")


if __name__ == "__main__":
    main()
