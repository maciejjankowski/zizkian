// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
(() => {
  'use strict';
  const config = JSON.parse(document.getElementById('lab-config').textContent);
  const fixture = document.getElementById('fixture'), record = document.getElementById('record');
  const run = document.getElementById('run'), report = document.getElementById('report');
  const label = document.getElementById('result-label'), engine = document.getElementById('engine-status');
  let worker, ready = false, busy = false, id = 0, timer, checkedText;
  function changed() {
    if (checkedText !== record.value) {
      label.textContent = 'Edited: run again to check this version';
      report.textContent = 'This version has not been checked.';
    }
  }
  function load() {
    id++; busy = false; clearTimeout(timer); run.disabled = !ready;
    record.value = JSON.stringify(config.fixtures[fixture.value], null, 2);
    document.getElementById('fixture-note').textContent = config.notes[fixture.value];
    checkedText = undefined; label.textContent = 'No record checked yet';
    report.textContent = 'Run the checker to inspect this record.';
  }
  function fail(message) {
    busy = false; clearTimeout(timer); run.disabled = !ready;
    label.textContent = 'Unable to check'; report.textContent = message;
  }
  function start() {
    ready = false; run.disabled = true;
    worker = new Worker(new URL(config.worker, document.baseURI));
    const boot = setTimeout(() => {worker.terminate(); fail('Runtime download timed out. Reload or use the native CLI.'); engine.textContent = 'Runtime unavailable';}, 30000);
    worker.onerror = () => {clearTimeout(boot); ready = false; engine.textContent = 'Runtime unavailable'; fail('Worker failed. Reload or use the native CLI.');};
    worker.onmessage = ({data}) => {
      if (data.kind === 'ready') {clearTimeout(boot); ready = true; engine.textContent = 'Prolog ready · checks run locally'; run.disabled = false; return;}
      if (data.id !== undefined && data.id !== id) return;
      if (data.kind === 'error') {clearTimeout(boot); fail(data.message); return;}
      if (data.kind === 'result') {
        busy = false; clearTimeout(timer); run.disabled = false;
        if (record.value !== checkedText) {changed(); return;}
        label.textContent = `${data.report.status}: ${data.report.verdict.replaceAll('_', ' ')} · structural check`;
        report.textContent = JSON.stringify(data.report, null, 2);
      }
    };
    worker.postMessage({kind: 'init', engine: new URL(config.engine, document.baseURI).href, runtime: new URL(config.runtime, document.baseURI).href, rules: new URL(config.rules, document.baseURI).href});
  }
  run.addEventListener('click', () => {
    if (!ready || busy) return;
    busy = true; run.disabled = true; checkedText = record.value; id++;
    label.textContent = 'Checking this record…'; report.textContent = 'Running Prolog locally.';
    timer = setTimeout(() => {worker.terminate(); ready = false; fail('Execution timed out. Reload or simplify the record.'); engine.textContent = 'Runtime stopped';}, 5000);
    worker.postMessage({kind: 'audit', id, text: checkedText});
  });
  fixture.addEventListener('change', load);
  document.getElementById('reset').addEventListener('click', load);
  record.addEventListener('input', changed);
  document.getElementById('download').addEventListener('click', () => {
    const url = URL.createObjectURL(new Blob([record.value], {type: 'application/json'}));
    const anchor = document.createElement('a'); anchor.href = url; anchor.download = 'zizkian-record.json'; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  load(); start();
})();
