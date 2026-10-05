// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
(function (scope) {
  'use strict';
  function browserBounds(text) {
    if (typeof text !== 'string' || new TextEncoder().encode(text).length > 65536)
      throw new Error('Record exceeds the browser limit of 64 KiB.');
    // Bound raw values before JSON.parse can discard duplicate-key subtrees.
    // This is a resource scanner, not the schema or the JSON syntax validator.
    const stack = []; let nodes = 0;
    function valueStart() {
      const parent = stack.at(-1);
      if (parent && !parent.value) return;
      if (stack.length > 20) throw new Error('Record exceeds 20 nested levels.');
      if (++nodes > 10000) throw new Error('Record exceeds 10000 values.');
      if (parent) {
        parent.value = false;
        if (parent.array && ++parent.count > 500) throw new Error('An array exceeds 500 entries.');
      }
    }
    for (let i = 0; i < text.length; i++) {
      const c = text[i]; if (/\s/.test(c)) continue;
      if (c === '"') {
        valueStart();
        while (++i < text.length) {
          if (text[i] === '\\') i++;
          else if (text[i] === '"') break;
        }
      } else if (c === '{' || c === '[') {
        valueStart(); stack.push({array: c === '[', value: c === '[', count: 0});
      } else if (c === '}' || c === ']') stack.pop();
      else if (c === ':') {if (stack.length) stack.at(-1).value = true;}
      else if (c === ',') {if (stack.length) stack.at(-1).value = stack.at(-1).array;}
      else {
        valueStart();
        while (i + 1 < text.length && !/[\s{}\[\],:"]/.test(text[i + 1])) i++;
      }
    }
  }
  function validateInput(text) {
    browserBounds(text);
    const value = JSON.parse(text);
    if (!value || Array.isArray(value) || typeof value !== 'object')
      throw new Error('Supply one JSON object.');
    return value;
  }
  async function createChecker(runtime, rules) {
    await runtime.prolog.load_string(rules, 'zizkian.pl');
    if (!runtime.prolog.query('current_predicate(zizkian:audit_json/2)').once().success)
      throw new Error('Checker rules could not be loaded.');
    return {audit(text) {
      browserBounds(text);
      const result = runtime.prolog.query(
        'zizkian:audit_json(Json,Report),atom_json_dict(Out,Report,[])',
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
