"""Regenerate the prebuilt site. Optional authoring tool: Ruby + kramdown/GFM.

SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
"""
import argparse
import hashlib
import html
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
HOME = "https://maciejjankowski.com/zizkian/"
PAGES = {
    "guide": "docs/guide.md", "method": "docs/method.md",
    "essay": "docs/essay.md", "checker": "docs/checker.md",
    "licensing": "docs/licensing.md",
    "licensing-polemic": "docs/licensing-polemic.md",
    "evaluation": "docs/evaluation.md", "provenance": "docs/provenance.md",
    "publishing": "docs/publishing.md",
    "consulting": "prompts/consulting.md", "coaching": "prompts/coaching.md",
    "wwzs": "prompts/wwzs.md",
}


def header():
    return '''<a class="skip" href="#main">Skip to content</a>
<header><div class="header-inner"><a class="brand" href="index.html" aria-label="The Zizkian home"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M3 4h26L8 28h21M3 28L29 4" fill="none" stroke="currentColor" stroke-width="3"/></svg>The Zizkian</a><button class="nav-toggle" type="button" aria-expanded="false" aria-controls="navigation">Menu</button><nav id="navigation" aria-label="Main"><a href="guide.html">Field guide</a><a href="checker.html">Checker</a><a href="licensing-polemic.html">Why noncommercial?</a><a href="downloads/zizkian-0.1.0.zip">Source package</a></nav></div></header>'''


def footer():
    return '''<footer><p>Maciej Jankowski · The Zizkian 0.1.0 · Experimental</p><p><a href="licensing.html">Noncommercial license scope</a> · <a href="provenance.html">Provenance</a> · <a href="evaluation.html">Evidence and failure criteria</a> · <a href="publishing.html">Build and publish</a></p></footer>'''


def version_assets(page):
    return re.sub(r'(?:assets/)(?:site\.css|site\.js|diagrams\.js)',
                  lambda match: match.group(0) + '?v=' + hashlib.sha256(
                      (SITE / match.group(0)).read_bytes()).hexdigest()[:12], page)


def shell(title, slug, content, diagrams=False):
    scripts = '<script src="assets/site.js" defer></script>'
    if diagrams:
        scripts += '<script src="https://cdn.jsdelivr.net/npm/mermaid@12.1.0/dist/mermaid.min.js" defer></script><script src="assets/diagrams.js" defer></script>'
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} | The Zizkian</title><meta name="description" content="A framework for readings that can lose. Method, executable Prolog rules, examples and noncommercial licensing."><meta name="author" content="Maciej Jankowski"><link rel="canonical" href="{HOME}{slug}"><link rel="stylesheet" href="assets/site.css">{scripts}</head><body>{header()}{content}{footer()}</body></html>
'''


def rewrite_link(match):
    href = html.unescape(match.group(1))
    if ":" in href or href.startswith("#"):
        return match.group(0)
    path, sep, fragment = href.partition("#")
    filename = Path(path).name
    candidates = {Path(value).name: key + ".html" for key, value in PAGES.items()}
    if filename in candidates:
        path = candidates[filename]
    elif path.startswith("../"):
        path = path[3:]
    elif filename == "attention-matrix.yaml":
        path = "docs/attention-matrix.yaml"
    return 'href="' + html.escape(path + (sep + fragment if sep else ""), quote=True) + '"'


def transform(body):
    body = re.sub(r'href="([^"]+)"', rewrite_link, body)
    def diagram(match):
        source = match.group(1)
        return '<figure><figcaption>Scroll wide diagrams horizontally to keep the text readable.</figcaption><pre class="mermaid">' + source + '</pre><details><summary>Editable Mermaid source</summary><pre><code>' + source + '</code></pre></details></figure>'
    body = re.sub(r'<pre><code class="language-mermaid">(.*?)</code></pre>', diagram, body, flags=re.S)
    def table(match):
        value = match.group(0)
        labels = re.findall(r'<th\b[^>]*>(.*?)</th>', value, flags=re.S)
        labels = [' '.join(html.unescape(re.sub('<[^>]+>', '', label)).split()) for label in labels]
        def row(row_match):
            cells = iter(labels)
            return re.sub(r'<td>', lambda _: '<td data-label="' + html.escape(next(cells, ""), quote=True) + '">', row_match.group(0))
        value = re.sub(r'<tr>.*?</tr>', row, value, flags=re.S)
        return '<div class="table-scroll">' + value + '</div>'
    return re.sub(r'<table>.*?</table>', table, body, flags=re.S)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-dir", type=Path, help="Optional existing Bundler project containing kramdown/GFM")
    args = parser.parse_args()
    ruby = 'require "kramdown"; require "kramdown-parser-gfm"; puts Kramdown::Document.new(File.read(ARGV[0]), input: "GFM", hard_wrap: false).to_html'
    command = ["ruby", "-W0", "-e", ruby]
    if args.bundle_dir:
        command = ["bundle", "exec"] + command
    manifest = {}
    for slug, source in PAGES.items():
        path = ROOT / source
        body = subprocess.check_output(command + [str(path)], cwd=args.bundle_dir or ROOT, text=True)
        title = next(line[2:].strip() for line in path.read_text().splitlines() if line.startswith("# "))
        body = transform(body)
        intro = '<p class="doc-nav"><a href="index.html">Home</a><a href="guide.html">Guide</a><a href="downloads/zizkian-0.1.0.zip">Download source</a></p>'
        if slug == "guide":
            intro += '<p id="diagram-status" class="note" role="status">Diagrams render when the pinned Mermaid script is available. Editable sources remain below.</p>'
        output = shell(title, slug + ".html", '<main id="main" class="doc">' + intro + body + '</main>', slug == "guide")
        (SITE / (slug + ".html")).write_text(version_assets(output))
        manifest[slug + ".html"] = {source: hashlib.sha256(path.read_bytes()).hexdigest()}
    data = {}
    for stage in ("supported", "defeated", "withdrawn"):
        case = ROOT / "examples" / (stage + ".json")
        result = subprocess.run(["swipl", "-q", "-s", str(ROOT / "src/check.pl"), "--", str(case)], capture_output=True, text=True)
        assert result.returncode in (0, 1), result.stderr
        data[stage] = {"case": json.loads(case.read_text()), "report": json.loads(result.stdout)}
    template = (SITE / "index.template.html").read_text()
    template = template.replace("@@HEADER@@", header()).replace("@@FOOTER@@", footer())
    template = template.replace("@@PROOF_DATA@@", json.dumps(data, ensure_ascii=False).replace("<", "\\u003c"))
    template = template.replace("@@INITIAL_REPORT@@", html.escape(json.dumps(data["supported"]["report"], indent=2)))
    template = template.replace("@@INITIAL_CASE@@", html.escape(json.dumps(data["supported"]["case"], indent=2)))
    (SITE / "index.html").write_text(version_assets(template))
    inputs = ["site/index.template.html", "scripts/render_site.py", "src/check.pl", "src/zizkian.pl"] + ["examples/" + stage + ".json" for stage in data]
    manifest["index.html"] = {source: hashlib.sha256((ROOT / source).read_bytes()).hexdigest() for source in inputs}
    manifest["_renderer"] = {"scripts/render_site.py": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    manifest["_assets"] = {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                           for path in sorted((SITE / "assets").glob("*")) if path.is_file()}
    (SITE / "page-sources.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    urls = [HOME] + [HOME + slug + ".html" for slug in PAGES]
    sitemap = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + ''.join('<url><loc>' + url + '</loc></url>' for url in urls) + '</urlset>\n'
    (SITE / "sitemap.xml").write_text(sitemap)
    print(f"Rendered {len(PAGES) + 1} pages with actual Prolog reports.")


if __name__ == "__main__":
    main()
