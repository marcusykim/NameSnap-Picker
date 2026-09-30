import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import ts from 'typescript';

const source = await readFile(new URL('../app/namesnap-web-app.tsx', import.meta.url), 'utf8');
const ast = ts.createSourceFile('picker.tsx', source, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
const component = ast.statements.find(s => ts.isFunctionDeclaration(s) && s.name?.text === 'NameSnapWebApp');
const handlers = new Set(['cancelPendingSpin', 'finishPick', 'spin', 'resetPool', 'removeEntry', 'undoLastAdd', 'clearPool']);
const declarations = component.body.statements.filter(s => ts.isVariableStatement(s) && s.declarationList.declarations.some(d => handlers.has(d.name.getText(ast))));
const compiled = ts.transpileModule(declarations.map(s => s.getText(ast)).join('\n'), { compilerOptions: { target: ts.ScriptTarget.ES2022 } }).outputText;

function fixture(mode = 'wheel', options = {}) {
  const state = { entries: options.entries ?? [{id:'a', name:'Alex', drawNumber:1, included:true}, {id:'b', name:'Alex', drawNumber:2, included:true}], excluded:[], lastAdded:['b'], history:[], winners:[], spinning:false, rotation:options.rotation ?? 0 };
  let now = 0, nextTimer = 1;
  const scheduled = new Map();
  const update = (key) => value => { state[key] = typeof value === 'function' ? value(state[key]) : value; };
  const env = {
    useCallback: fn => fn, makeId: () => `result-${state.winners.length}`, randomIndex: () => options.selectedIndex ?? 0,
    renumberEntries: values => values.map((entry,index) => ({...entry,drawNumber:index+1})),
    activeEntries: state.entries, mode, noRepeats: options.noRepeats ?? true, isSpinning: false, lastAddedIds: state.lastAdded,
    timersRef: {current:[]}, spinGenerationRef: {current:0}, spinningRef: {current:false},
    dismissWinner: () => {}, presentWinner: winner => state.winners.push(winner),
    setEntries: update('entries'), setExcludedIds: update('excluded'), setLastAddedIds: update('lastAdded'), setHistory: update('history'), setIsSpinning: update('spinning'), setLiveName: () => {}, setRotation: update('rotation'),
    performance: {now: () => now}, window: {setTimeout: (fn,delay) => { const id=nextTimer++; scheduled.set(id,{fn,at:now+delay}); return id; }, clearTimeout: id => scheduled.delete(id)},
  };
  const initialize = new Function('env', 'const {' + Object.keys(env).join(',') + '}=env;\n' + compiled + '\nreturn {' + [...handlers].filter(name => compiled.includes('const '+name+' =')).join(',') + '};');
  const actions = initialize(env);
  const advance = (duration=5000) => {
    const end = now+duration;
    for (let guard=0; guard<1000; guard++) {
      const next = [...scheduled].filter(([,v]) => v.at<=end).sort((a,b) => a[1].at-b[1].at)[0];
      if (!next) {now=end; return;}
      const [id,value]=next; scheduled.delete(id); now=value.at; value.fn();
    }
    throw new Error('Timer loop did not settle');
  };
  return {state, actions, advance};
}

test('wheel: every selected segment lands at the pointer and commits the same contestant', () => {
  for (const count of [1,2,3,7,16,40,100,500]) {
    const entries = Array.from({length:count}, (_,index) => ({id:`entry-${index}`,name:index%2 ? 'Alex' : `007-${index}`,drawNumber:index*3+1,included:true}));
    for (const rotation of [0,-725,13925.5]) {
      for (let selectedIndex=0; selectedIndex<count; selectedIndex++) {
        const f=fixture('wheel',{entries,rotation,selectedIndex});
        f.actions.spin();
        // Canvas segments start at the top; CSS rotation must put this
        // contestant's segment center back at the fixed top pointer.
        const centerAtPointer = ((f.state.rotation + (selectedIndex+0.5)*360/count)%360+360)%360;
        assert.ok(Math.min(centerAtPointer,360-centerAtPointer)<1e-8,`count=${count}, index=${selectedIndex}, rotation=${rotation}`);
        f.advance();
        assert.equal(f.state.winners[0].number,entries[selectedIndex].drawNumber);
        assert.equal(f.state.winners[0].name,entries[selectedIndex].name);
        assert.deepEqual(f.state.excluded,[entries[selectedIndex].id]);
      }
    }
  }
});

test('repeat mode commits a result without consuming the selected contestant', () => {
  for (const mode of ['classic','wheel']) {
    const f=fixture(mode,{noRepeats:false,selectedIndex:1});
    f.actions.spin(); f.advance();
    assert.equal(f.state.winners[0].number,2);
    assert.equal(f.state.winners[0].name,'Alex');
    assert.deepEqual(f.state.excluded,[]);
  }
});

for (const mode of ['classic','wheel']) {
  for (const mutation of ['clearPool','resetPool','removeEntry','undoLastAdd']) {
    test(`${mode}: ${mutation} cancels the pending result`, () => {
      const f=fixture(mode);
      f.actions.spin();
      f.actions[mutation]('a');
      f.advance();
      assert.deepEqual(f.state.winners, []);
      assert.deepEqual(f.state.history, []);
      assert.equal(f.state.spinning,false);
    });
  }
  test(`${mode}: two synchronous spin triggers commit one result`, () => {
    const f=fixture(mode);
    f.actions.spin(); f.actions.spin(); f.advance();
    assert.equal(f.state.winners.length,1);
    assert.equal(f.state.winners[0].name,'Alex');
    assert.equal(f.state.winners[0].number,1);
    assert.deepEqual(f.state.excluded,['a']);
  });
}
