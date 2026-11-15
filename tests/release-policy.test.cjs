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

// Exercise the real pinned Manifest API, stubbing only the GitHub transport.
// Policy-only unit tests cannot catch changes to the proposal return shape.
const { createManifest, runRelease } = require('../scripts/release.cjs');
function releaseFixture(messages, { tagOnly = false, startingVersion = '0.7.12' } = {}) {
  // Seed an isolated repository snapshot; never read the live version or baseline.
  const config = { 'bootstrap-sha': 'a'.repeat(40) };
  const files = {
    VERSION: startingVersion + '\n',
    '.release-please-manifest.json': JSON.stringify({ '.': startingVersion }),
    'CHANGELOG.md': '# Changelog\n',
  };
  const baseline = JSON.parse(files['.release-please-manifest.json'])['.'];
  assert.equal(files.VERSION.trim(), baseline);
  const writes = [];
  const tag = { name: 'v' + baseline, sha: config['bootstrap-sha'] };
  const github = {
    repository: { owner: 'example', repo: 'dotfiles' },
    async *releaseIterator() {
      if (!tagOnly) yield { ...tag, tagName: tag.name, notes: 'Scaffold baseline' };
    },
    async *tagIterator() { yield tag; },
    async *mergeCommitIterator() {
      for (const [index, message] of messages.entries()) {
        yield { sha: 'commit-' + index, message, files: ['scripts/release.cjs'] };
      }
      yield { sha: tag.sha, message: 'Scaffold baseline', files: [] };
      throw new Error('Must stop at the baseline instead of reading legacy history');
    },
    async *pullRequestIterator() {},
    async createPullRequest(pr, branch, message, updates) {
      writes.push({ pr, branch, message, updates });
      return { ...pr, number: 42 };
    },
  };
  return { manifest: createManifest(github, files.VERSION.trim(), config), writes, files };
}

for (const messages of [[], ['Merge pull request #2 from example/maintenance']]) {
  test('no releasable commits completes without writes: ' + JSON.stringify(messages), async () => {
    const { manifest, writes } = releaseFixture(messages);
    assert.deepEqual(await manifest.buildPullRequests(), []);
    await runRelease(manifest);
    assert.deepEqual(writes, []);
  });
}

for (const startingVersion of ['0.0.1', '0.0.2', '0.7.12', '0.42.99']) {
  for (const tagOnly of [false, true]) {
    test('fix increments fixture patch from ' + startingVersion + ', tagOnly=' + tagOnly, async () => {
      const { manifest, writes, files } = releaseFixture(['fix: handle release proposal versions'], {
        tagOnly, startingVersion,
      });
      // Compute the expected patch independently of the versioning code under test.
      const [major, minor, patch] = files.VERSION.trim().split('.').map(Number);
      const expected = [major, minor, patch + 1].join('.');
      await runRelease(manifest);
      assert.equal(writes.length, 1);
      const { pr, updates } = writes[0];
      assert.equal(pr.title, 'chore(main): release ' + expected);
      const update = path => updates.find(item => item.path === path).updater.updateContent(files[path]);
      assert.equal(update('VERSION'), expected + '\n');
      assert.equal(JSON.parse(update('.release-please-manifest.json'))['.'], expected);
      const changelog = update('CHANGELOG.md');
      assert.ok(changelog.includes('## [' + expected + '] - '));
      assert.match(changelog, /### Fixed\n\n- handle release proposal versions/);
      assert.doesNotMatch(changelog, /Scaffold baseline/);
    });
  }
}

test('dry run validates a real proposal without writing', async () => {
  const { manifest, writes } = releaseFixture(['fix: handle release proposal versions']);
  await runRelease(manifest, { dryRun: true });
  assert.deepEqual(writes, []);
});

test('API errors still fail the release runner', async () => {
  const { manifest } = releaseFixture([]);
  manifest.buildPullRequests = async () => { throw new Error('GitHub unavailable'); };
  await assert.rejects(runRelease(manifest), /GitHub unavailable/);
});
