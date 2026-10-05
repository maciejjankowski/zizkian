// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
// Exercise the real controller with a deterministic host for slow/hung workers.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, '../site/assets/lab.js'), 'utf8');
function host() {
  let time = 0, sequence = 0; const timers = new Map(), workers = [], elements = new Map();
  function element(id) {
    if (!elements.has(id)) elements.set(id, {value: '', textContent: '', disabled: false, hidden: true,
      handlers: {}, addEventListener(event, handler) {this.handlers[event] = handler;}});
    return elements.get(id);
  }
  element('lab-config').textContent = JSON.stringify({worker: 'worker.js', engine: 'engine.js', runtime: './', rules: 'rules.pl',
    fixtures: {one: {id: 'one'}, two: {id: 'two'}}, notes: {one: 'first', two: 'second'}});
  element('fixture').value = 'one';
  class Worker {
    constructor() {this.messages = []; this.stopped = false; workers.push(this);}
    postMessage(message) {this.messages.push(message);}
    terminate() {this.stopped = true;}
    emit(data) {this.onmessage({data});}
  }
  const context = {Worker, URL, Blob, document: {baseURI: 'http://localhost/lab.html', getElementById: element},
    setTimeout(fn, delay) {const key = ++sequence; timers.set(key, {fn, at: time + delay}); return key;},
    clearTimeout(key) {timers.delete(key);}};
  vm.runInNewContext(source, context);
  return {element, workers, click(id) {element(id).handlers.click();},
    advance(ms) {
      const end = time + ms;
      while (true) {
        const due = [...timers].filter(([, t]) => t.at <= end).sort((a, b) => a[1].at - b[1].at)[0];
        if (!due) break;
        time = due[1].at; timers.delete(due[0]); due[1].fn();
      }
      time = end;
    }};
}

// A reset during a hung request cannot leave an unbounded worker running.
{
  const h = host(), old = h.workers[0]; old.emit({kind: 'ready'}); h.click('run'); h.advance(1000);
  h.click('reset'); h.advance(5000);
  assert.equal(old.stopped, true, 'reset must terminate the pending execution');
  assert.equal(h.element('run').disabled, true, 'fresh runtime must be ready before another audit');
  const current = h.workers.at(-1); assert.notEqual(current, old);
  old.emit({kind: 'ready'}); assert.equal(h.element('run').disabled, true, 'stale readiness must not enable checks');
  current.emit({kind: 'ready'}); h.click('run');
  assert.equal(current.messages.at(-1).text, h.element('record').value);
  const id = current.messages.at(-1).id;
  old.emit({kind: 'result', id, report: {status: 'pass', verdict: 'stale'}});
  assert.doesNotMatch(h.element('result-label').textContent, /stale/);
  current.emit({kind: 'result', id, report: {status: 'blocked', verdict: 'revise'}});
  assert.match(h.element('result-label').textContent, /blocked/);
  h.advance(5000); assert.equal(current.stopped, false, 'completed audit must cancel its deadline');
}
// Execution and bootstrap failures are recoverable without discarding edits.
for (const phase of ['execution', 'bootstrap', 'error', 'init-error']) {
  const h = host(), worker = h.workers[0];
  if (phase === 'execution') {worker.emit({kind: 'ready'}); h.click('run'); h.advance(5000);}
  if (phase === 'bootstrap') h.advance(30000);
  if (phase === 'error') worker.onerror();
  if (phase === 'init-error') worker.emit({kind: 'error', message: 'Could not download the checker rules.'});
  assert.equal(worker.stopped, true, phase);
  assert.equal(h.element('run').disabled, true, phase);
  assert.equal(h.element('retry-runtime').hidden, false, phase);
  h.element('record').value = '{"id":"edited"}'; h.click('retry-runtime');
  h.workers.at(-1).emit({kind: 'ready'}); h.click('run');
  assert.equal(h.workers.at(-1).messages.at(-1).text, '{"id":"edited"}', phase);
}
console.log('Lab controller: reset isolation, stale replies, deadlines and recovery passed.');
