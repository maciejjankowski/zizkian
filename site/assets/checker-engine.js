// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
(function (scope) {
  'use strict';
  function validateInput(text) {
    if (typeof text !== 'string' || new TextEncoder().encode(text).length > 65536)
      throw new Error('Record exceeds the browser limit of 64 KiB.');
    const value = JSON.parse(text);
    if (!value || Array.isArray(value) || typeof value !== 'object')
      throw new Error('Supply one JSON object.');
    let nodes = 0;
    function visit(v, depth) {
      if (depth > 20) throw new Error('Record exceeds 20 nested levels.');
      if (++nodes > 10000) throw new Error('Record exceeds 10000 values.');
      if (Array.isArray(v) && v.length > 500) throw new Error('An array exceeds 500 entries.');
      if (v && typeof v === 'object') Object.values(v).forEach(x => visit(x, depth + 1));
    }
    visit(value, 0);
    return value;
  }
  async function createChecker(runtime, rules) {
    await runtime.prolog.load_string(rules, 'zizkian.pl');
    if (!runtime.prolog.query('current_predicate(zizkian:audit/2)').once().success)
      throw new Error('Checker rules could not be loaded.');
    return {audit(text) {
      validateInput(text);
      const result = runtime.prolog.query(
        'atom_json_dict(Json,Case,[value_string_as(atom),default_tag(data)]),zizkian:audit(Case,Report),atom_json_dict(Out,Report,[])',
        {Json: text}, {string: 'atom'}).once();
      if (!result.success || typeof result.Out !== 'string')
        throw new Error(result.message || 'Checker execution limit reached; simplify the record.');
      return JSON.parse(result.Out);
    }};
  }
  const api = {validateInput, createChecker};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else scope.ZizkianEngine = api;
})(globalThis);
