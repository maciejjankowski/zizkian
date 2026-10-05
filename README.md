# The Zizkian

**A framework for readings that can lose.**

Ask what a question takes for granted. Offer a reading. Say what would defeat it.
Examine what the analyst gains from that reading. Then make an owned choice:
test it, change the decision, or retain the original brief.

The Zizkian combines a small question library with an executable Prolog checker.
The checker makes selected omissions and contradictory declarations visible.
It does not discover motives or establish that an explanation is true.
Every report says `evidence_verified: false` and names the human review still
required. The numerical attention matrix belongs to a separate historical essay;
it supplies no operating weights, truth score or decision authority.

Version **0.3.1**, experimental. Public home:
**https://maciejjankowski.com/zizkian/**. Repository:
**https://github.com/maciejjankowski/zizkian**.

## Try the first proof

[Edit a reading in the browser lab](https://maciejjankowski.com/zizkian/lab.html).
Run the actual rules locally using SWI-Prolog WebAssembly. No account or model is
required. Try the deliberately fabricated evidence records: they pass the
structural checks and demonstrate why a pass cannot establish truth.

With SWI-Prolog already installed, run from this repository:

```sh
swipl -q -s proof/refutable.pl
```

The result demonstrates a finite witness:

```text
supported fictional reading    -> pass
defeating observation added    -> blocked: defeated_reading
reading withdrawn; brief kept  -> pass: awaiting_closure_review
```

The one-word description is **refutable**. The proof concerns a declared reading
in this implementation. It does not establish a real-world diagnosis or superior
decision quality.

## Check your own record

Copy an example, change its question, observations and proposed next step, then:

```sh
swipl -q -s src/check.pl -- examples/hypothesis.json
```

Exit `0`: the record passes; `1`: reasoning rules block it; `2`: invalid input.
Every violation has a named rule, target and explanation. Explicitly untested
checks remain visible as warnings. No finding is a permitted conclusion.

See [the input contract](docs/checker.md). A passing record still requires human
review of source relevance, test quality and participant authority.
Use the record when an interpretation may change a test or decision. If the
ordinary explanation already answers the brief, retain it; a deeper reading is
optional. The [coverage table](docs/checker.md#method-coverage) separates executable
checks from responsibilities the method leaves to people.

## Learn the method

- [Method and invariants](docs/method.md)
- [Field guide: nine Mermaid maps, examples and ten exercises](docs/guide.md)
- [Consulting prompts](prompts/consulting.md), [coaching prompts](prompts/coaching.md)
  and [WWZS? provocation](prompts/wwzs.md)
- [Licensing rationale and polemic](docs/licensing-polemic.md)
- [Evaluation protocol and failure criteria](docs/evaluation.md)
- [Provenance and claim boundaries](docs/provenance.md)

Optional background: [the historical conceptual essay](docs/essay.md) preserves
the requested Hamiltonian analogy. It is outside the executable method.

## What is implemented

The Prolog module validates an explicit schema, evidence references, reading
status, declared falsifiers, ordinary alternatives, participant invitation and
closure. It excludes attention weights and participant rejection from support.
It returns a complete violation list rather than an unexplained score.

Nine fixtures and 40 rule tests are included. CLI regression checks cover the
fixtures, malformed inputs and operation outside the checkout directory.
JSON types are checked before conversion. Native and browser paths share strict
JSON parsing and the same schema. The [versioned shape schema](schema/record-0.3.1.schema.json)
is generated from that field definition; it cannot replace the reasoning audit.
The attention matrix is a conceptual illustration; the checker does not use it.
No model, network service or dispatcher is needed to run the checker.
The browser worker has a five-second execution timeout and bounded JSON input.
Resetting a pending check terminates its worker. Runtime failures can be retried
without discarding edits. Tests cover deadlines and stale replies.
Node.js is required by the WASM/native parity tests, not by the native CLI.
Vendored runtime components retain their own licenses; see
[third-party notices](THIRD_PARTY_NOTICES.md).

## Run the checks and build the package

```sh
sh test.sh
python3 scripts/build_release.py
python3 scripts/validate_release.py
```

The check runner uses installed SWI-Prolog and Python 3's standard library.
The release builder creates a deterministic source ZIP and a static website
bundle under `dist/`. Prebuilt HTML is included; Ruby or Jekyll is not required
to use the checker or create the release archives.

The site has a proof explorer using checked Prolog output. Its JavaScript selects
recorded reports; it does not run a second implementation of the checker.
Mermaid rendering uses a pinned external script with source fallback.
See [publishing and local QA instructions](docs/publishing.md).

## License

This is a **source-available, noncommercial** release.
Code: **PolyForm Noncommercial 1.0.0**. Documentation, diagrams, prompts and
fictional example content: **CC BY-NC-SA 4.0**. See [LICENSE](LICENSE),
[scope](docs/licensing.md) and [the polemic](docs/licensing-polemic.md).

The public release offers no commercial license. Its noncommercial position
applies to the author as a project policy too. This policy does not rewrite the
standard license terms or claim ownership of abstract methods.

## Current evidence

This release contains running code, fictional examples and a formal witness.
It has no controlled outcome benchmark or client-validation study. Whether the
method adds value over a plain decision checklist is an open question. The
evaluation protocol defines how to test it and when to retire extra machinery.
Claims of novelty or breakthrough performance require evidence beyond packaging.

The CI workflow runs the rules and release checks on GitHub. Local HTTP browser
review covered the desktop proof transitions, phone navigation and table labels,
and all nine Mermaid diagrams at readable widths. This is a limited interface
review, not a full accessibility audit or an outcome benchmark.
The static validator checks local links and recorded outputs, not visual behavior.
