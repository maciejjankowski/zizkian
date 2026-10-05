// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
(() => {
  'use strict';
  const config = JSON.parse(document.getElementById('lab-config').textContent);
  const fixture = document.getElementById('fixture'), record = document.getElementById('record');
  const run = document.getElementById('run'), report = document.getElementById('report');
  const label = document.getElementById('result-label'), engine = document.getElementById('engine-status');
  const retry = document.getElementById('retry-runtime');
  let worker, ready = false, busy = false, id = 0, timer, boot, checkedText;
  function changed() {
    if (checkedText !== record.value) {
      label.textContent = 'Edited: run again to check this version';
      report.textContent = 'This version has not been checked.';
    }
  }
  function load() {
    if (busy) start();
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
  function stop(message) {
    worker?.terminate(); worker = undefined;
    clearTimeout(boot); ready = false; engine.textContent = 'Runtime unavailable';
    retry.hidden = false; fail(message);
  }
  function start() {
    worker?.terminate(); clearTimeout(timer); clearTimeout(boot);
    ready = false; busy = false; run.disabled = true; retry.hidden = true;
    engine.textContent = 'Loading the local Prolog runtime…';
    const current = worker = new Worker(new URL(config.worker, document.baseURI));
    boot = setTimeout(() => stop('Runtime download timed out. Retry or use the native CLI.'), 30000);
    worker.onerror = () => {if (current === worker) stop('Worker failed. Retry or use the native CLI.');};
    worker.onmessage = ({data}) => {
      if (current !== worker) return;
      if (data.kind === 'ready') {clearTimeout(boot); ready = true; engine.textContent = 'Prolog ready · checks run locally'; run.disabled = false; return;}
      if (data.id !== undefined && data.id !== id) return;
      if (data.kind === 'error') {
        if (data.id === undefined) stop(data.message);
        else fail(data.message);
        return;
      }
      if (data.kind === 'result') {
        busy = false; clearTimeout(timer); run.disabled = false;
        if (record.value !== checkedText) {changed(); return;}
        label.textContent = `${data.report.verdict.replaceAll('_', ' ')} · ${data.report.status} · evidence unverified`;
        report.textContent = JSON.stringify(data.report, null, 2);
      }
    };
    worker.postMessage({kind: 'init', engine: new URL(config.engine, document.baseURI).href, runtime: new URL(config.runtime, document.baseURI).href, rules: new URL(config.rules, document.baseURI).href});
  }
  run.addEventListener('click', () => {
    if (!ready || busy) return;
    busy = true; run.disabled = true; checkedText = record.value; id++;
    label.textContent = 'Checking this record…'; report.textContent = 'Running Prolog locally.';
    timer = setTimeout(() => stop('Execution timed out. Simplify the record and retry the runtime.'), 5000);
    worker.postMessage({kind: 'audit', id, text: checkedText});
  });
  fixture.addEventListener('change', load);
  document.getElementById('reset').addEventListener('click', load);
  retry.addEventListener('click', start);
  record.addEventListener('input', changed);
  document.getElementById('download').addEventListener('click', () => {
    const url = URL.createObjectURL(new Blob([record.value], {type: 'application/json'}));
    const anchor = document.createElement('a'); anchor.href = url; anchor.download = 'zizkian-record.json'; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  load(); start();
})();
