#!/bin/sh
set -eu
zizkian_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$zizkian_root"
command -v swipl >/dev/null
command -v python3 >/dev/null
swipl -q -s tests/test_zizkian.pl -g run_tests -t halt
python3 tests/cli.py
python3 tests/schema.py
swipl -q -s proof/refutable.pl
node tests/wasm.cjs
node tests/lab-controller.cjs
