// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
let checker;
self.onmessage = async ({data}) => {
  try {
    if (data.kind === 'init') {
      importScripts(data.engine, data.runtime + 'swipl-web.js');
      const response = await fetch(data.rules);
      if (!response.ok) throw new Error('Could not download the checker rules.');
      const rules = await response.text();
      const runtime = await SWIPL({arguments: ['-q'], locateFile: f => data.runtime + f});
      checker = await ZizkianEngine.createChecker(runtime, rules);
      self.postMessage({kind: 'ready'});
    } else if (data.kind === 'audit' && checker) {
      self.postMessage({kind: 'result', id: data.id, report: checker.audit(data.text)});
    }
  } catch (error) {
    self.postMessage({kind: 'error', id: data.id, message: error.message});
  }
};
