# Third-party runtime notices

The Zizkian's noncommercial licenses do not apply to third-party dependencies.
These components retain their own terms, including commercial permissions.

The browser lab redistributes unmodified runtime files from official
[`swipl-wasm@8.2.1`](https://github.com/SWI-Prolog/npm-swipl-wasm/tree/v8.2.1).
The runtime reports SWI-Prolog 10.1.15. Package tag commit:
`85167290994ede92eab1aa5e399007c031e6cb82`.

Vendored files and retained notices are in
`site/assets/vendor/swipl-8.2.1/` in the source archive and
`assets/vendor/swipl-8.2.1/` in the website archive:

- `swipl-web.js`, `swipl-web.wasm`, `swipl-web.data`: official package bytes.
- `LICENSE.txt`, `SWI-LICENSE`: package and SWI-Prolog Simplified BSD terms.
- `PCRE2-LICENCE.md`: upstream PCRE2 copyright, BSD terms and exception.
- `ZLIB-README`: upstream zlib copyright and license terms.
- `LIBBF-NOTICE`: Fabrice Bellard's retained MIT copyright and permission notice.
- `EMSCRIPTEN-LICENSE`: upstream Emscripten license and runtime-license explanation.
- `manifest.json`: byte hashes, package integrity and exact notice source URLs.

The upstream package's pinned Docker build configuration identifies SWI-Prolog
commit `5db27168f89b15186745ea401fbb99a017413788`, PCRE2 commit
`6f9d7c1373262c541324a16a358785b33ef116cf`, zlib 1.3.2 and Emscripten SDK
6.0.11. It explicitly builds with `USE_GMP=OFF`. See its
[build configuration](https://github.com/SWI-Prolog/npm-swipl-wasm/blob/v8.2.1/build-config.json)
and [Dockerfile](https://github.com/SWI-Prolog/npm-swipl-wasm/blob/v8.2.1/docker/Dockerfile).
Emscripten's notice was retrieved from its upstream main branch; the package
does not supply a separate compiler-license file. This is not a source
reproducibility claim for the compiler toolchain.

The runtime is a dependency, not a Zizkian implementation or endorsement.
The native CLI uses the user's installed SWI-Prolog and its installed licenses.
Mermaid is loaded separately from pinned jsDelivr 12.1.0 on diagram pages,
under its upstream MIT license; its files are not included in this release.
