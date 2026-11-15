/**
 * Purpose: run upstream release-please behind the owner's 0.x gate.
 * Usage: bash scripts/release.sh [--dry-run].
 * Parameters: GITHUB_TOKEN, GITHUB_REPOSITORY; --dry-run prevents writes.
 * Example: bash scripts/release.sh --dry-run.
 * Exit codes: 0 success/help, 1 validation/API failure, 2 invalid arguments.
 * Author: Jeremy Spofford / Aria Labs; version read from VERSION.
 * Log messages are routed through the Bash wrapper's logger.sh.
 */
const fs = require('node:fs');
const { GitHub, Manifest, registerVersioningStrategy, registerChangelogNotes } = require('release-please');
const { Version } = require('release-please/build/src/version');
const { assertZero, ZeroMajor, KeepAChangelog } = require('./release-policy.cjs');

async function main() {
  const version = fs.readFileSync('VERSION', 'utf8').trim();
  assertZero(version);
  const cached = JSON.parse(fs.readFileSync('.release-please-manifest.json', 'utf8'))['.'];
  if (cached !== version) throw new Error('Derived release manifest differs from VERSION.');
  const raw = JSON.parse(fs.readFileSync('release-please-config.json', 'utf8'));
  if (JSON.stringify(raw).includes('"release-as"')) throw new Error('release-as is forbidden');
  if (raw.versioning !== 'zero-major' || raw['version-file'] !== 'VERSION') {
    throw new Error('Release policy must use zero-major and VERSION.');
  }
  registerVersioningStrategy('zero-major', () => new ZeroMajor());
  registerChangelogNotes('keep-a-changelog', () => new KeepAChangelog());
  const [owner, repo, extra] = (process.env.GITHUB_REPOSITORY || '').split('/');
  if (!owner || !repo || extra || !process.env.GITHUB_TOKEN) {
    throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required.');
  }
  const github = await GitHub.create({ owner, repo, token: process.env.GITHUB_TOKEN });
  // Explicit configuration prevents remote release-as overrides bypassing the strategy.
  const manifest = new Manifest(github, 'main', { '.': {
    releaseType: 'simple',
    versionFile: 'VERSION',
    versioning: 'zero-major',
    bumpMinorPreMajor: true,
    bumpPatchForMinorPreMajor: false,
    changelogType: 'keep-a-changelog',
    includeComponentInTag: false,
    changelogSections: [
      ...['feat', 'fix', 'chore', 'docs', 'ci', 'build', 'refactor', 'perf', 'test', 'style', 'revert']
        .map(type => ({ type, section: type, hidden: false })),
    ],
  } }, { '.': Version.parse(version) }, {
    bootstrapSha: raw['bootstrap-sha'],
  });
  const candidates = await manifest.buildPullRequests();
  for (const candidate of candidates) {
    assertZero(candidate.pullRequest.version);
    console.log('Release-please proposal: ' + candidate.pullRequest.version);
  }
  const releases = await manifest.buildReleases();
  for (const candidate of releases) assertZero(candidate.tag.version);
  if (process.argv.includes('--dry-run')) {
    console.log('Dry run: no GitHub writes.');
    return;
  }
  await manifest.createReleases();
  await manifest.createPullRequests();
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
