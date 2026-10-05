"""Build deterministic source and static-site archives using the standard library.

SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
"""
import hashlib
import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
VERSION = (ROOT / "VERSION").read_text().strip()
STAMP = (2026, 10, 6, 0, 0, 0)
EXCLUDED = {"dist", "work", ".git", "__pycache__", ".venv", ".DS_Store"}
ROOT_FILES = {"README.md", "VERSION", "LICENSE", "LICENSE-CODE.md", "LICENSE-DOCS.md", "THIRD_PARTY_NOTICES.md", "CHANGELOG.md", "CONTRIBUTING.md", "SECURITY.md", "CITATION.cff", ".gitignore", "test.sh"}
SOURCE_DIRS = {"src", "proof", "tests", "scripts", "schema", "docs", "prompts", "examples", "charts", "site", ".github"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_files():
    for path in sorted(ROOT.rglob("*")):
        relative = path.relative_to(ROOT)
        if relative.parts[0] not in SOURCE_DIRS and relative.as_posix() not in ROOT_FILES:
            continue
        if any(part.startswith(".") and part not in (".github", ".gitignore", ".htaccess") for part in relative.parts):
            continue
        if not path.is_file() or set(relative.parts) & EXCLUDED or path.suffix == ".pyc":
            continue
        if path.is_symlink():
            raise ValueError(f"Source symlink not allowed: {relative}")
        yield path


def archive(destination, files, base):
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for path in sorted(files):
            name = "zizkian/" + path.relative_to(base).as_posix()
            info = zipfile.ZipInfo(name, STAMP)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            output.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def check_prebuilt():
    manifest = json.loads((ROOT / "site/page-sources.json").read_text())
    for page, inputs in manifest.items():
        if page not in ("_renderer", "_assets") and not (ROOT / "site" / page).is_file():
            raise ValueError(f"Missing prebuilt page: {page}")
        for source, expected in inputs.items():
            if digest(ROOT / source) != expected:
                raise ValueError(f"Stale {page}: rerender after editing {source}")


def main():
    check_prebuilt()
    DIST.mkdir(exist_ok=True)
    public = DIST / "zizkian"
    if public.exists():
        shutil.rmtree(public)
    shutil.copytree(ROOT / "site", public, ignore=shutil.ignore_patterns("*.template.html", "page-sources.json"))
    for folder in ("examples", "charts", "src", "proof", "schema"):
        shutil.copytree(ROOT / folder, public / folder)
    (public / "docs").mkdir()
    shutil.copy2(ROOT / "docs/attention-matrix.yaml", public / "docs/attention-matrix.yaml")
    for name in ("LICENSE", "LICENSE-CODE.md", "LICENSE-DOCS.md", "THIRD_PARTY_NOTICES.md", "VERSION", "CITATION.cff"):
        shutil.copy2(ROOT / name, public / name)
    source = DIST / f"zizkian-{VERSION}.zip"
    archive(source, source_files(), ROOT)
    downloads = public / "downloads"
    downloads.mkdir()
    shutil.copy2(source, downloads / source.name)
    (downloads / "SHA256SUMS").write_text(f"{digest(source)}  {source.name}\n")
    files = {path.relative_to(public).as_posix(): digest(path) for path in sorted(public.rglob("*")) if path.is_file()}
    (public / "manifest.json").write_text(json.dumps({"version": VERSION, "sha256": files}, indent=2, sort_keys=True) + "\n")
    site = DIST / f"zizkian-site-{VERSION}.zip"
    archive(site, [path for path in public.rglob("*") if path.is_file()], public)
    (DIST / "SHA256SUMS").write_text(''.join(f"{digest(path)}  {path.name}\n" for path in (source, site)))
    print(f"Source: {source.name}\nWebsite: {site.name}\nStatic files: {len(files) + 1}\nChecksums: dist/SHA256SUMS")


if __name__ == "__main__":
    main()
