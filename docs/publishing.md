# Build and publish

The source package is prepared for `maciejjankowski/zizkian`. The static public
home is prepared for `https://maciejjankowski.com/zizkian/`. Neither destination
is created or updated by the release builder.

## Check and build

From an extracted source checkout, using installed SWI-Prolog, Python 3 and Node.js:

```sh
sh test.sh
python3 scripts/build_release.py
python3 scripts/validate_release.py
```

`dist/zizkian-0.3.0.zip` is a self-contained source archive.
`dist/zizkian-site-0.3.0.zip` contains a `zizkian/` static publication subtree.
`dist/zizkian/` is that same subtree, including a source download and checksums.
No server, model, credentials or database are required by the package.

## Publish the files yourself

Extract the source ZIP into its own directory. Create the empty GitHub repository
yourself if wanted, then run your normal Git workflow there. This package has no
relationship to the surrounding private workspace and includes no private
handoffs, bot configuration or conversation exports.

For the website, extract the site ZIP into your site's publication root, or copy
the generated `dist/zizkian/` subtree into your existing Jekyll repository at
`zizkian/`. Prebuilt pages have no Liquid or frontmatter dependency. Build and
deploy through your existing site process. Keep unrelated website files intact.
Review the rendered pages before public deployment.

## Update the existing local QA copy

From this source directory, after building:

```sh
mkdir -p "$HOME/code/qa-www/zizekian"
cp -R dist/zizkian/. "$HOME/code/qa-www/zizekian/"
```

The existing Apache preview is `http://localhost:18080/zizekian/`. This retains the
earlier preview spelling while the production subtree uses `zizkian`. The command
updates the known QA subtree only. It does not start another server or deploy
publicly. Its destination must be writable in the session where you run it.

## Edit the prebuilt website

Markdown is the authoring source for document pages. `site/index.template.html`
is the landing-page source. The optional authoring renderer needs Ruby with
`kramdown` and `kramdown-parser-gfm`; these are not release dependencies.

```sh
python3 scripts/render_site.py
```

If an existing Bundler project supplies those gems, pass its path with
`--bundle-dir /path/to/project`. The renderer uses the installed Prolog checker
to capture demonstration reports and records input hashes in
`site/page-sources.json`. The release validator rejects stale source hashes.

## Inspect the result

Check the editable lab (including false-evidence, missing-owner and edited
records), the landing page, all three proof states, mobile navigation, mobile tables,
each of the nine diagrams and the diagram source fallback. Review the ten
exercises, license scope, polemic and downloadable archive. Confirm the archives
extract and run away from the authoring workspace.

Static validation and automated rule checks do not substitute for browser review.
The release's current review status is recorded in `docs/ui/brief.md`.
