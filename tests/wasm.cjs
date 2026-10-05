// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const {createChecker, validateInput} = require('../site/assets/checker-engine.js');

function nativeReport(text) {
  const directory = fs.mkdtempSync(path.join(require('node:os').tmpdir(), 'zizkian-json-'));
  try {
    const file = path.join(directory, 'case.json'); fs.writeFileSync(file, text);
    const result = spawnSync('swipl', ['-q', '-s', 'src/check.pl', '--', file], {cwd: root, encoding: 'utf8'});
    assert.ok([0, 1, 2].includes(result.status), result.stderr);
    return JSON.parse(result.stdout);
  } finally {fs.rmSync(directory, {recursive: true});}
}

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
  // Literal expectations catch shared rule failures that parity alone misses.
  for (const [field, value, rule] of [
    ['owner', true, 'invalid_text'], ['owner', null, 'invalid_text'],
    ['coaching_invited', 'false', 'invalid_boolean'], ['mode', true, 'invalid_status']
  ]) {
    const text = JSON.stringify({...supported, [field]: value});
    const report = checker.audit(text);
    assert.equal(report.status, 'invalid', `${field}=${value}`);
    assert.ok(report.violations.some(v => v.rule === rule));
    assert.deepEqual(report, nativeReport(text));
  }
  const valid = JSON.stringify(supported);
  for (const text of [valid.slice(0, -1) + ',}', '\ufeff' + valid,
    valid.replace('Improve onboarding', 'Improve\nonboarding'),
    valid.replace('Improve onboarding', 'Improve\u0000onboarding'),
    '{"owner":"a","owner":"b"}', '{} trailing', '{"owner":"\\ud800"}',
    '{"owner":01}', '{"owner":1.}', '{', 'null', '[]']) {
    const report = checker.audit(text);
    assert.equal(report.status, 'invalid', JSON.stringify(text.slice(0, 40)));
    assert.deepEqual(report, nativeReport(text));
  }
  for (const owner of ['false', 'null', 'Newline\n日本語 😀'])
    assert.equal(checker.audit(JSON.stringify({...supported, owner})).status, 'pass');
  // Input strings are bound data, never interpolated executable Prolog.
  supported.brief = "x'), halt(42), ('quoted <script> and 日本語";
  assert.equal(checker.audit(JSON.stringify(supported)).status, 'pass');
  delete supported.owner;
  assert.equal(checker.audit(JSON.stringify(supported)).status, 'invalid');
  for (const value of ['{', 'null', '[]', '"record"', '{} trailing']) assert.throws(() => validateInput(value));
  assert.throws(() => validateInput(' '.repeat(65537)), /64 KiB/);
  assert.throws(() => validateInput('é'.repeat(32769)), /64 KiB/);
  assert.throws(() => validateInput(JSON.stringify({a: Array(501).fill(1)})), /500/);
  assert.throws(() => validateInput('{"a":[' + Array(501).fill('1').join(',') + '],"a":1}'), /500/);
  assert.throws(() => validateInput('{"a":' + '['.repeat(12000) + '0' + ']'.repeat(12000) + ',"a":1}'), /20/);
  // Root, outer array and 20 inner arrays contribute 22 values; 9978 leaves make 10000.
  const atLimit = {a: [...Array.from({length: 19}, () => Array(500).fill(1)), Array(478).fill(1)]};
  assert.doesNotThrow(() => validateInput(JSON.stringify(atLimit)));
  atLimit.a[19].push(1);
  const aboveLimit = JSON.stringify(atLimit);
  assert.throws(() => validateInput(aboveLimit), /10000/);
  assert.throws(() => validateInput(aboveLimit.slice(0, -1) + ',"a":1}'), /10000/);
  let boundary = 0; for (let n = 0; n < 20; n++) boundary = {a: boundary};
  assert.doesNotThrow(() => validateInput(JSON.stringify(boundary)));
  assert.throws(() => validateInput(JSON.stringify({a: boundary})), /20/);
  let deep = {}; for (let n = 0; n < 22; n++) deep = {a: deep};
  assert.throws(() => validateInput(JSON.stringify(deep)), /20/);
  console.log(`WASM/native parity: ${cases} fixtures; injection, missing field and bounded input checks passed.`);
})().catch(error => {console.error(error); process.exitCode = 1;});
