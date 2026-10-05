# Contributing

Start with a reproducible problem in a fictional or properly authorized record.
State the intended result, current report, expected report and why a rule should
change. Include counterexamples and a no-finding case, not only a compelling
positive example. Do not contribute private transcripts or secrets.

For code changes, add a meaningful regression test and run `sh test.sh`.
The schema is explicit; changes to keys, statuses or verdicts require a version
note, updated examples and updated documentation. Keep the evidence record
separate from opinion, weights and model agreement.
The shape schema is generated from `schema/2`. After a field change, update the
release version and export the matching file with `scripts/export_schema.pl`;
`tests/schema.py` checks freshness. Regenerate prebuilt HTML after document,
fixture, rule or asset changes using the [publishing instructions](docs/publishing.md).

For prompts, identify the new question or decision the change contributes.
A longer prompt is not a gain by itself. For evaluation claims, provide the
case set, comparison, predeclared rubric, outputs and limitations.

Code contributions are offered under PolyForm Noncommercial 1.0.0; authored
documentation and other identified content under CC BY-NC-SA 4.0. Only submit
work you can contribute under those terms. Mark third-party material and its
terms clearly; do not silently import incompatible material.

The project offers no commercial license in this release. License changes are
substantive changes to the project's position, not housekeeping.
