# .githooks

Tracked git hooks for the dotfiles repo. Activated by:

```bash
git config core.hooksPath .githooks
```

`install.sh` runs this command automatically on a fresh clone, so you only need to worry about it if you cloned the repo before this directory existed.

## Hooks

### `pre-commit`

Lints staged shell scripts with [shellcheck](https://www.shellcheck.net/). Catches real bugs before they hit `main`. Specifically catches `SC2168` (`local` outside function — the bug that broke `install.sh` and motivated this whole hook).

**What it lints:**
- Files with `*.sh` or `*.bash` extension
- Files named `install.sh`, `bootstrap.sh`, `install`, or `bootstrap`
- Any other staged file whose first line is a `#!/usr/bin/env bash` (or `sh`) shebang

**What it does NOT lint:**
- `.zshrc`, `.zsh` files (shellcheck has weak zsh support)
- `.bashrc`, `.bash_profile`, `.aliases`, etc. — opt-in by adding `# shellcheck shell=bash` at the top of the file

**If shellcheck isn't installed:** the hook prints a warning and exits 0 (does not block the commit). Install it with `brew install shellcheck` (macOS) or `sudo apt-get install shellcheck` (Debian/Ubuntu), or re-run `./install.sh`.

**To bypass intentionally:** `git commit --no-verify`

## Adding a new hook

1. Drop a file in this directory named after the git hook (e.g. `pre-push`, `commit-msg`)
2. Make it executable: `chmod +x .githooks/pre-push`
3. Commit it. The hook activates immediately for anyone with `core.hooksPath` set.

Note that `core.hooksPath` is a per-repo git config setting and lives in `.git/config`, which is not tracked. Fresh clones need to run `install.sh` (or `git config core.hooksPath .githooks` manually) to opt in.
