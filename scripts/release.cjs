/**
 * Purpose: Run release-please while keeping automatic versions at 0.x.
 * Release-please proposes and publishes releases. Only the owner can authorize 1.0.0.
 * Usage: bash scripts/release.sh [--dry-run].
 * Parameters: --dry-run prevents writes; GITHUB_REPOSITORY selects owner/repo.
 * GITHUB_TOKEN grants content and pull-request write access.
 * A pull request proposes a repository change.
 * Example: bash scripts/release.sh --dry-run.
 * Exit codes: 0 success/help; 1 validation or API failure; 2 invalid arguments.
 * The API is GitHub's programming interface. The Bash wrapper logs through logger.sh.
 * Author: Jeremy Spofford / Aria Labs; Version: read from VERSION.
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
  const [owner, repo, extra] = (process.env.GITHUB_REPOSITORY || '').split('/');
  if (!owner || !repo || extra || !process.env.GITHUB_TOKEN) {
    throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required.');
  }
  const github = await GitHub.create({ owner, repo, token: process.env.GITHUB_TOKEN });
  await runRelease(createManifest(github, version, raw), { dryRun: process.argv.includes('--dry-run') });
}

function createManifest(github, version, raw) {
  registerVersioningStrategy('zero-major', () => new ZeroMajor());
  registerChangelogNotes('keep-a-changelog', () => new KeepAChangelog());
  // Explicit configuration prevents remote release-as overrides bypassing the strategy.
  return new Manifest(github, 'main', { '.': {
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
}

async function runRelease(manifest, { dryRun = false } = {}) {
  const candidates = await manifest.buildPullRequests();
  // The public API returns ReleasePullRequest[], not internal CandidateReleasePullRequest wrappers.
  for (const candidate of candidates) {
    assertZero(candidate.version);
    console.log('Release-please proposal: ' + candidate.version);
  }
  const releases = await manifest.buildReleases();
  for (const candidate of releases) assertZero(candidate.tag.version);
  if (candidates.length === 0 && releases.length === 0) {
    console.log('No releasable changes or pending releases; nothing to publish.');
    return;
  }
  if (dryRun) {
    console.log('Dry run: no GitHub writes.');
    return;
  }
  await manifest.createReleases();
  await manifest.createPullRequests();
}

if (require.main === module) {
  main().catch(error => { console.error(error.stack); process.exitCode = 1; });
}

module.exports = { createManifest, runRelease };
