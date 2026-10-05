# The Zizkian

**A framework for readings that can lose.**

Ask what a question takes for granted. Offer a reading. Say what would defeat it.
Examine what the analyst gains from that reading. Then make an owned choice:
test it, change the decision, or retain the original brief.

The Zizkian combines a small question library with an executable Prolog checker.
The checker makes selected omissions and contradictory declarations visible.
It does not discover motives or establish that an explanation is true.

Version **0.1.0**, experimental. Public home:
**https://maciejjankowski.com/zizkian/**. Repository:
**https://github.com/maciejjankowski/zizkian**.

## Try the first proof

With SWI-Prolog already installed, run from this repository:

```sh
swipl -q -s proof/refutable.pl
```

The result demonstrates a finite witness:

```text
supported fictional reading    -> pass
defeating observation added    -> blocked: defeated_reading
reading withdrawn; brief kept  -> pass: no_finding
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

## Learn the method

- [Method and invariants](docs/method.md)
- [Field guide: nine Mermaid maps, examples and ten exercises](docs/guide.md)
- [The conceptual essay](docs/essay.md)
- [Consulting prompts](prompts/consulting.md), [coaching prompts](prompts/coaching.md)
  and [WWZS? provocation](prompts/wwzs.md)
- [Licensing rationale and polemic](docs/licensing-polemic.md)
- [Evaluation protocol and failure criteria](docs/evaluation.md)
- [Provenance and claim boundaries](docs/provenance.md)

## What is implemented

The Prolog module validates an explicit schema, evidence references, reading
status, declared falsifiers, ordinary alternatives, participant invitation and
closure. It excludes attention weights and participant rejection from support.
It returns a complete violation list rather than an unexplained score.

Six fixtures and 35 rule tests are included. CLI regression checks cover the
fixtures, malformed inputs and operation outside the checkout directory.
The attention matrix is a conceptual illustration; the checker does not use it.
No model, network service or dispatcher is needed to run the checker.

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
