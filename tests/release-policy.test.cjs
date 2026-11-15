const test = require('node:test');
const assert = require('node:assert/strict');
const { Version } = require('release-please/build/src/version');
const { assertZero, ZeroMajor, KeepAChangelog } = require('../scripts/release-policy.cjs');
const commit = (type, breaking = false, notes = []) => ({
  sha: 'example', type, breaking, notes, message: type + ': improve setup',
  bareMessage: 'Improve setup', scope: '', references: [], footer: '', body: '',
});
for (const [type, breaking, current, expected] of [
  ['fix', false, '0.0.1', '0.0.2'],
  ['chore', false, '0.0.1', '0.0.2'],
  ['docs', false, '0.0.1', '0.0.2'],
  ['feat', false, '0.0.1', '0.1.0'],
  ['feat', true, '0.99.9', '0.100.0'],
  ['fix', true, '0.999.999', '0.1000.0'],
]) {
  test(type + ' from ' + current + ' -> ' + expected, () => {
    assert.equal(new ZeroMajor().bump(Version.parse(current), [commit(type, breaking)]).toString(), expected);
  });
}
test('Release-As cannot bypass the owner gate', () => {
  for (const version of ['1.0.0', '2.0.0', '0.0.2']) {
    assert.throws(() => new ZeroMajor().bump(Version.parse('0.0.1'),
      [commit('fix', false, [{ title: 'RELEASE AS', text: version }])]));
  }
});
test('already production versions fail closed', () => {
  assert.throws(() => new ZeroMajor().bump(Version.parse('1.0.0'), [commit('fix')]));
  assert.throws(() => assertZero('1.0.0'));
});
test('Keep a Changelog headings and plain-language entries', async () => {
  const notes = await new KeepAChangelog().buildNotes([commit('fix')], { version: '0.0.2' });
  assert.match(notes, /^## \[0\.0\.2\] - \d{4}-\d{2}-\d{2}/);
  assert.match(notes, /### Fixed\n\n- Improve setup/);
});
