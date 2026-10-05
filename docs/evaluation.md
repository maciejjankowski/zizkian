# Evaluation protocol

## Present status

The editable browser lab makes a specific limitation reproducible. The
irrelevant-evidence and plausible-fabrication fixtures pass; removing the owner
fails the schema. These are diagnostic examples, not an outcome benchmark.
The worker and native CLI use the same Prolog module; parity tests compare their
complete reports on all nine fixtures.

The code and fictional fixtures are exercised. There is no client-validation
study or controlled benchmark of decision quality. A finite refutability witness
shows an encoded rule can remove a reading's eligibility; it does not demonstrate
the framework's empirical superiority.

## Question

Does the Zizkian change evidence quality, useful tests or owned decisions compared
with a plain checklist using question, evidence, alternative, owner and next step?

## Proposed comparison

Use the same authorized or fictional cases under both methods. Include ordinary
problems, ambiguous evidence, irrelevant sources, refused interpretations and
cases where no reframing is warranted. Preserve complete outputs and time spent.
Predeclare the case set and rubric before seeing results. Keep model, context and
time budget comparable; rotate which method is used first when the design allows.

Ask a reviewer unaware of the branding to assess:

- Unsupported factual or motive claims, with their evidence references.
- Whether ordinary alternatives were actually examined.
- Specificity and adequacy of defeating tests.
- Respect for invitation, rejection and ownership.
- Changes to a test or decision that follow from evidence.
- Appropriate no-finding closure.
- Time and effort required.

Report disagreements and null results. Multiple role prompts are not independent
sources. Human ratings need a disclosed rubric; a score alone is not calibration.
Do not claim causal improvement from a single exercise.

## Preregistration worksheet

This is an unrun pilot design. Before starting, timestamp a record with the case
IDs and source permissions, methods, reviewers, model versions if used, order
assignment and analysis plan. Changes after viewing results must be labelled
exploratory. Fictional fixtures can exercise workflow; they cannot establish
client benefit.

Use at least one case in each class: ordinary instruction sufficient; constraint
mistaken for ideology; evidence genuinely warrants a changed decision; irrelevant
evidence; plausible fabrication; rejected interpretation; unasked coaching;
analyst favors the intervention. State the chosen case count before running.
Do not substitute the checker outputs for the human reviews below.

| Criterion | 0 | 1 | 2 |
|---|---|---|---|
| Evidence relevance | Missing or unrelated | Plausible, unresolved | Specific source bears on this claim |
| Defeating test | Cannot lose | Could lose, ambiguous result | Observable result distinguishes the selected explanation from its strongest alternative |
| Ordinary alternative | Absent or strawman | Named, unchecked | Strong alternative fairly examined |
| Participant authority | Refusal overridden or invitation invented | Unresolved authority | Actual invitation and accepted next step established, or closure respected |
| Consequence | More interpretation only | Additional question | Useful owned test, justified change or appropriate closure |

Use two independent reviewers if available; preserve each rating and explanation
before reconciliation. Hide method names where feasible and disclose whether the
outputs reveal them anyway. Record elapsed time, added unsupported motive claims,
refusals handled incorrectly and disagreements. Report paired differences by case
and the raw outputs, not just an aggregate score.

For this pilot, predeclare that any overridden refusal is a stop-and-redesign
event. If the Zizkian adds time but improves no evidence assessment, useful test
or appropriate closure over the checklist, prefer the checklist. A favorable
small pilot only justifies a larger comparison; it is not proof of effectiveness.

## Output comprehension check

Before claiming usability for strangers, show `supported`, `plausible-fabrication`
and `defeated` reports without a facilitator's explanation. Ask what the program
checked, whether it verified sources, and whether the participant may act on a
pass. The intended answers distinguish declared relationships from truth and
authority. Record misunderstandings before correcting them. If anyone treats a
pass as source verification or authorization, revise the language and repeat
with new readers. This check has not been run with independent human readers.

## Failure criteria

If the method sounds more profound but adds unsupported suspicion, delays a
decision, makes refusal harder or yields no additional test, remove the extra
machinery. If structured false evidence passes and users treat the report as
certification, correct the presentation and evidence-review process.

## Release checks versus outcome evidence

`sh test.sh` checks program behavior and CLI output. Release validation checks
archive contents, links and generated proof data. A browser review assesses the
site. None of these substitutes for the comparison above. An unrun CI workflow
or uninspected diagram is not reported as passed.
