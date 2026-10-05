# Browser lab design

The lab evaluates edited JSON with the existing `src/zizkian.pl` rules. It adds
no model, scoring function, evidence authentication or alternate JavaScript
implementation of the reasoning rules. The ordinary explanation can survive.

`lab.js` manages the editor and result. `lab-worker.js` downloads the pinned,
same-origin SWI-Prolog runtime and the content-versioned rules. The adapter
passes a JSON string as a bound Prolog value to `audit_json/2`
and returns the complete audit report. User text is never interpolated into a
goal or consulted as Prolog. The worker has a five-second wall-time limit;
runtime loading has a separate thirty-second timeout.

The adapter rejects input above 64 KiB, twenty nested levels, 500 entries in one
array or 10000 total values. These limits bound the demo, not the native schema.
The resource scan runs on raw input before duplicate object keys can hide a large
subtree. Strict syntax, typed schema validation and reasoning stay in Prolog.
The editor marks changed records as unchecked, ignores replies to older requests
and lets users reset or download the current JSON. There is no persistent storage.
Resetting or changing the fixture during an audit terminates that worker and
boots a new one. Old workers cannot restore readiness or overwrite results.
Execution, bootstrap and worker failures show a retry control that preserves edits.

The runtime is vendored from official `swipl-wasm@8.2.1`, which reports
SWI-Prolog 10.1.15. No build or package install is needed to use the lab. Runtime
notices, source pointers and immutable hashes ship with both archives.

Verification: native PlUnit and CLI checks, actual WASM/native report parity,
bound-input injection probe, strict syntax and typed JSON regressions,
raw duplicate-key bounds, controller deadline/recovery checks, desktop and
phone browser review. A pass demonstrates program behavior, not good decisions.
