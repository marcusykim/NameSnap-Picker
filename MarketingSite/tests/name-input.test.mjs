import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import ts from 'typescript';

// Exercise production helpers without a browser or live payment requests.
const source = await readFile(new URL('../app/namesnap-web-app.tsx', import.meta.url), 'utf8');
const ast = ts.createSourceFile('picker.tsx', source, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
const names = new Set(['makeId', 'parseNames', 'normalizedName', 'namesExcludingDuplicates', 'stagedInputRows', 'writeInputNames', 'renumberEntries', 'restoreStoredEntries']);
const helpers = ast.statements.filter(s => ts.isFunctionDeclaration(s) && names.has(s.name?.text)).map(s => s.getText(ast)).join('\n');
const compiled = ts.transpileModule(helpers + '\nexport {' + [...names].join(',') + '};', { compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 } }).outputText;
const picker = await import('data:text/javascript;base64,' + Buffer.from(compiled).toString('base64'));

test('numeric handles survive paste, editor and serialization', () => {
  const values = ['2pac', '007', '50 Cent', '7-11', '4.5', '100', '1 Direction', '1.Maya', '123-abc'];
  assert.deepEqual(picker.parseNames(values.join('\n')), values);
  const encoded = picker.writeInputNames(values);
  assert.deepEqual(picker.parseNames(encoded), values);
  assert.deepEqual(picker.stagedInputRows(encoded), values);
});

test('numbered lists, commas, CRLF and blank separators preserve individual names', () => {
  assert.deepEqual(picker.parseNames(' 1. Zoë\r\n2) 李雷,3- Jean-Luc, ,4. O’Connor\n5. 🐸 frog '), ['Zoë', '李雷', 'Jean-Luc', 'O’Connor', '🐸 frog']);
});

test('10000-name round trip preserves order and repeated occurrences', () => {
  const values = Array.from({length: 10000}, (_, i) => i % 19 === 0 ? '007' : `${i}user 🐸 é`);
  const encoded = picker.writeInputNames(values);
  assert.deepEqual(picker.parseNames(encoded), values);
  assert.deepEqual(picker.stagedInputRows(encoded), values);
});

test('duplicate skipping compares normalized names and preserves spelling', () => {
  assert.deepEqual(picker.namesExcludingDuplicates(['José', ' JOSE ', 'Casey', 'casey', '007', '2pac'], ['josé']), ['Casey', '007', '2pac']);
});

test('duplicate display names retain distinct identities and inclusion after restore/delete', () => {
  const saved = [{ id: 'one', name: ' Alex ', included: false, drawNumber: 88 }, { id: 'two', name: 'Alex', included: true, drawNumber: 4 }];
  const restored = picker.restoreStoredEntries(saved);
  assert.deepEqual(restored, [{ id: 'one', name: 'Alex', included: false, drawNumber: 1 }, { id: 'two', name: 'Alex', included: true, drawNumber: 2 }]);
  assert.deepEqual(picker.renumberEntries(restored.filter(e => e.id !== 'one')), [{ id: 'two', name: 'Alex', included: true, drawNumber: 1 }]);
  assert.equal(saved[0].name, ' Alex ');
});

test('invalid saved rows are discarded and valid rows receive identities', () => {
  const restored = picker.restoreStoredEntries([null, {}, {name:''}, {name:'   '}, {name:'007'}, {name:42}, {name:'2pac', id: 'known'}]);
  assert.deepEqual(restored.map(e => e.name), ['007', '2pac']);
  assert.ok(restored[0].id.length);
  assert.equal(restored[1].id, 'known');
  assert.deepEqual(restored.map(e => e.drawNumber), [1,2]);
});
