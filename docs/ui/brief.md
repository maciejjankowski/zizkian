# Publication interface brief

Person: a first-time reader considering the method, a facilitator inspecting it,
or a developer evaluating the checker. Laptop and phone; mouse, keyboard or touch.
Loop: understand the claim -> inspect a record -> add a defeater -> withdraw ->
read the method or download the source.
Frequency: one short exploration per visit; repeated proof transitions are easy.
Consequence: lab controls execute edited JSON locally in a WebAssembly worker;
no control submits the record to a server or changes external state.
Tier 1: question, proof stages, current report and explanation visible together.
Tier 2: full JSON, diagrams, field guide, prompts, licensing polemic and downloads.
Implemented: editable JSON browser lab using the existing Prolog module.
Deferred: online Prolog service, account system,
model router, ratings and commercial services.
Reviewed viewports: default desktop browser (1288px wide); phone 390x844.
Review on 2026-10-05 through the local HTTP QA server: proof transitions,
phone menu closure and table labels, nine rendered diagrams with source panels,
and diagrams fitted to page width with optional enlargement for detail. Static assets have content
hashes in their URLs so updated rendering reaches returning readers.
Public-domain browser review was denied by browser permissions. This local
review does not claim a full accessibility audit or cross-browser coverage.

## Visual direction

The central object is a defeasible record: one explanation visibly loses its
eligibility while its evidence is retained. The interface should make that
change legible before inviting a download.

Palette: cloud #edf3f7, paper #ffffff, ink #172c3e, ocean #235b77,
amber #8c570c and leaf #266044. Typography: Helvetica Neue/Arial for reading and
headings, ui-monospace for actual code and report excerpts. Clear left alignment,
a wide proof stage beneath a compact opening, then an index of the reading path.
No success score, accreditation claim or fabricated performance graph.

## Behavior

The three proof buttons choose stored outputs generated from the included Prolog
fixtures. The full-record disclosure shows the selected fixture. Mobile navigation
uses a labelled toggle and closes when a destination is chosen. Every state has
a textual verdict, not color alone. Keyboard focus remains visible.
Document diagrams retain their Mermaid source when the renderer is unavailable.

## Browser lab review, 2026-10-05

Actual WebAssembly execution verified in the local HTTP QA browser: supported,
defeated, withdrawn, irrelevant evidence, plausible fabrication, missing owner,
no finding and rejection trap. An arbitrary edit removing the owner produced a
schema error; malformed JSON produced an error, and reset restored the fixture.
Editing cleared the previous report and marked the record unchecked.
Downloaded JSON matched the selected plausible-fabrication fixture.
At 390x844, document width was 390px and editor/report width was 342px, with
no horizontal page overflow. Mobile menu opened and closed. Desktop runtime
loaded successfully, including Apache's application/wasm response.
Native/WASM parity and input bounds are automated checks. Browser compatibility
outside this local Brave review and empirical decision quality remain untested.
