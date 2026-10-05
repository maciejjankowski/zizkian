// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const {createChecker, validateInput} = require('../site/assets/checker-engine.js');

(async () => {
  const base = path.join(root, 'site/assets/vendor/swipl-8.2.1/');
  const module = await require(base + 'swipl-web.js')({arguments: ['-q'], locateFile: f => base + f});
  const checker = await createChecker(module, fs.readFileSync(path.join(root, 'src/zizkian.pl'), 'utf8'));
  let cases = 0;
  for (const file of fs.readdirSync(path.join(root, 'examples')).filter(f => f.endsWith('.json'))) {
    const input = fs.readFileSync(path.join(root, 'examples', file), 'utf8');
    const native = spawnSync('swipl', ['-q', '-s', 'src/check.pl', '--', 'examples/' + file], {cwd: root, encoding: 'utf8'});
    assert.ok([0, 1, 2].includes(native.status), native.stderr);
    assert.deepEqual(checker.audit(input), JSON.parse(native.stdout), file);
    cases++;
  }
  const supported = JSON.parse(fs.readFileSync(path.join(root, 'examples/supported.json'), 'utf8'));
  // Input strings are bound data, never interpolated executable Prolog.
  supported.brief = "x'), halt(42), ('quoted <script> and 日本語";
  assert.equal(checker.audit(JSON.stringify(supported)).status, 'pass');
  delete supported.owner;
  assert.equal(checker.audit(JSON.stringify(supported)).status, 'invalid');
  for (const value of ['{', 'null', '[]', '"record"', '{} trailing']) assert.throws(() => validateInput(value));
  assert.throws(() => validateInput(' '.repeat(65537)), /64 KiB/);
  assert.throws(() => validateInput('é'.repeat(32769)), /64 KiB/);
  assert.throws(() => validateInput(JSON.stringify({a: Array(501).fill(1)})), /500/);
  let deep = {}; for (let n = 0; n < 22; n++) deep = {a: deep};
  assert.throws(() => validateInput(JSON.stringify(deep)), /20/);
  console.log(`WASM/native parity: ${cases} fixtures; injection, missing field and bounded input checks passed.`);
})().catch(error => {console.error(error); process.exitCode = 1;});
