/**
 * Purpose: Reject automatic releases outside 0.x and format release notes.
 * Release-please proposes releases. Keep a Changelog defines the note format.
 * Usage: import from release.cjs; test with node --test tests/release-policy.test.cjs.
 * Parameters: strategy and note inputs from release-please's programming interface.
 * Example: new ZeroMajor().bump(Version.parse('0.0.1'), commits).
 * Exit codes: this library throws for forbidden releases; the wrapper reports failure.
 * Author: Jeremy Spofford / Aria Labs; Version: project version comes from VERSION.
 */
const { DefaultVersioningStrategy } = require('release-please/build/src/versioning-strategies/default');
const { Version } = require('release-please/build/src/version');

function assertZero(version) {
  const parsed = typeof version === 'string' ? Version.parse(version) : version;
  if (parsed.major !== 0 || parsed.preRelease || !/^0\.\d+\.\d+$/.test(parsed.toString())) {
    throw new Error('Owner gate: automatic releases must remain stable 0.x.y versions.');
  }
  return parsed;
}

class ZeroMajor extends DefaultVersioningStrategy {
  constructor() {
    super({ bumpMinorPreMajor: true, bumpPatchForMinorPreMajor: false });
  }

  bump(version, commits) {
    assertZero(version);
    if (commits.some(commit => commit.notes.some(note => note.title === 'RELEASE AS'))) {
      throw new Error('Release-As overrides are forbidden; 1.0.0 is an owner-only manual release.');
    }
    return assertZero(super.bump(version, commits));
  }
}

class KeepAChangelog {
  async buildNotes(commits, options) {
    assertZero(options.version);
    const sections = { Added: [], Changed: [], Fixed: [] };
    for (const commit of commits) {
      const section = commit.type === 'feat' ? 'Added' : commit.type === 'fix' ? 'Fixed' : 'Changed';
      const text = commit.bareMessage || commit.message.replace(/^[^:]+:\s*/, '');
      sections[section].push('- ' + text.split('\n')[0]);
    }
    const date = new Date().toISOString().slice(0, 10);
    return [
      '## [' + options.version + '] - ' + date,
      ...Object.entries(sections).filter(([, entries]) => entries.length)
        .map(([title, entries]) => '### ' + title + '\n\n' + [...new Set(entries)].join('\n')),
    ].join('\n\n');
  }
}

module.exports = { assertZero, ZeroMajor, KeepAChangelog };
