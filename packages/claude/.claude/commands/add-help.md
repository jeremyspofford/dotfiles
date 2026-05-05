Bake a --help block into a personal slash command, making it self-documenting and discoverable via /<command> --help. Idempotent via marker comments — re-runs replace cleanly.

Usage: `/add-help [--all] [--refresh] [--dry-run] [-h|--help] [COMMAND_NAME]`

## Input

$ARGUMENTS

<!-- BEGIN HELP -->
## Step 0: Print help and exit if --help/-h

If `$ARGUMENTS` is exactly `--help`, `-h`, or the only non-empty token (ignoring leading/trailing whitespace) is `--help` or `-h`, print the usage block below to the user and stop immediately. Do not parse the body, do not load conventions, do not call any tools, do not write any files.

```
================================================================================
/add-help — Help
================================================================================

Bake a --help block into a personal slash command. Re-runs cleanly via marker
comments. Generated help is synthesized from the command's actual content
(description, flags, examples) — review with --dry-run before committing.

Usage:
  /add-help <command-name>          Bake --help into ~/.claude/commands/<name>.md
                                    (skipped if a help block already exists)
  /add-help --all                   Bake into every personal command without one
  /add-help --refresh <name>        Replace the existing help block (idempotent)
  /add-help --refresh --all         Replace help in every personal command
  /add-help --dry-run <name>        Show what would be inserted, don't write
  /add-help --dry-run --all         Show diffs for all targets
  -h, --help                        Show this help and exit

Behavior:
  - Operates ONLY on ~/.claude/commands/*.md (personal commands).
  - Plugin commands and skills are NOT modified — those are upstream files.
  - Always edits the dotfiles source path, never the symlink directly.
  - Inserts AFTER the description line, BEFORE the first "## " heading.
  - Wraps with <!-- BEGIN HELP --> / <!-- END HELP --> markers around the
    entire ## Step 0 block for idempotent re-runs.
  - Refuses to write to any command file not symlinked to dotfiles
    (per the dotfiles enforcement rule); surfaces it for migration instead.

Examples:
  # Bake --help into one command
  /add-help wiki-capture

  # Preview what would be added across all commands missing help
  /add-help --dry-run --all

  # Refresh help on a command after editing its body or flags
  /add-help --refresh littlebird-meeting

================================================================================
```
<!-- END HELP -->

## Step 1: Load conventions and the dotfiles rule

Read these once at the start of execution:

- `~/.claude/projects/-mnt-c-Users-jerem-Obsidian-Vault/memory/feedback_dotfiles_enforcement.md` — the dotfiles enforcement rule. Core directive: edit dotfiles source, never the symlink. Use `readlink -f` to resolve targets.

If the memory file doesn't exist at that path, look for `feedback_dotfiles_enforcement.md` under the active memory directory referenced by `MEMORY.md`. The rule is the same wherever it lives.

## Step 2: Parse arguments

Tokens to recognize from `$ARGUMENTS`:

- `--all` — operate on every personal command.
- `--refresh` — replace existing help blocks (otherwise skip files that already have one).
- `--dry-run` — print proposed changes as unified diffs, do not write.
- `--help`, `-h` — already handled in Step 0; if you reached Step 2, these were not the only arguments.
- Any non-flag token → command name (e.g., `wiki-capture`, `littlebird-meeting`). Strip a leading `/` if present.

Validation:

- If neither `--all` nor a command name was given, prompt: "Which command? (or use --all)". One line, no filler.
- If both `--all` and a command name were given, prefer `--all` and warn that the name was ignored.
- `--refresh` and `--dry-run` may appear with or without `--all` and without conflict.

## Step 3: Resolve target command(s)

For a single target named `<name>`:

1. Compute symlink path: `~/.claude/commands/<name>.md`. If it does not exist, stop and report: "No personal command named `<name>` at ~/.claude/commands/<name>.md".
2. Resolve to dotfiles source: run `readlink -f ~/.claude/commands/<name>.md`. The result MUST start with `~/workspace/dotfiles/packages/claude/.claude/commands/` (after path expansion). If not, **stop** and report:
   ```
   <name> is not symlinked to dotfiles. Migrate it first per the dotfiles
   enforcement rule, then re-run /add-help. Suggested commands:

     mkdir -p ~/workspace/dotfiles/packages/claude/.claude/commands
     mv ~/.claude/commands/<name>.md ~/workspace/dotfiles/packages/claude/.claude/commands/
     ln -s ../../workspace/dotfiles/packages/claude/.claude/commands/<name>.md ~/.claude/commands/<name>.md
   ```
3. The dotfiles path from step 2 is the **edit target**. Never write to the symlink directly.

For `--all`:

- List every `*.md` file in `~/.claude/commands/`.
- Resolve each as above.
- Skip files that don't symlink to dotfiles, and accumulate them in a `needs-migration` list to surface in the final summary.

## Step 4: Detect existing help block

For each resolved target, read the dotfiles source file. Determine help block state:

1. **Marker comments present** — file contains `<!-- BEGIN HELP -->` and `<!-- END HELP -->`: canonical state. The block between (and including) the markers is the existing help.
   - If `--refresh`: prepare to replace between markers, inclusive.
   - Otherwise: skip with status `skipped (already has help)`.

2. **Heading-only / legacy** — file contains `## Step 0: Print help and exit if --help/-h` (or close variant) but no marker comments: legacy help block written before this skill existed.
   - If `--refresh`: find the boundaries — start at the legacy `## Step 0:` heading, end at the line before the next top-level heading (`## ` at column 0) OR end of file if no further `##` headings. Prepare to replace this region with a marker-wrapped block.
   - Otherwise: skip with status `skipped (legacy help — use --refresh to migrate to marker convention)`.

3. **Conflicting Step 0** — file contains a `## Step 0:` whose title is NOT about help (e.g., `## Step 0: Initialize state`):
   - **Stop** for this target and surface: `<name> has a non-help ## Step 0. Refusing to overwrite or renumber automatically. Inspect the file and either rename the existing Step 0 or remove it before re-running.`

4. **No help block, no conflict**: prepare for fresh insertion.

## Step 5: Generate the help block

Read the target file in full. Synthesize a help block by extracting:

- **Description** — first non-empty line of the file (the commands convention).
- **Usage line** — search the file for an explicit `Usage:` line near the top. If present, copy it verbatim. If absent, synthesize as `/<name> [OPTIONS] [ARGS]`.
- **Options** — scan the body for `--<flag>` patterns and adjacent prose. List each flag with a one-line description. If no flags exist, write `  (no options)` on a single indented line.
- **Behavior / side effects** — read sections like `Hard rules`, `Side effects`, `Process`, or the numbered Steps. Distill 2-4 bullet lines describing what the command actually does — NOT a full restatement. Focus on writes, file paths touched, external calls.
- **Examples** — pull from existing example sections in the body when present. If none exist, synthesize 1-2 realistic invocations from the command's purpose. **Mark synthesized examples** with `  # (synthesized)` so the user can verify them with `--dry-run`.

Output format — wrap the entire `## Step 0` section in markers:

```
<!-- BEGIN HELP -->
## Step 0: Print help and exit if --help/-h

If `$ARGUMENTS` is exactly `--help`, `-h`, or the only non-empty token (ignoring leading/trailing whitespace) is `--help` or `-h`, print the usage block below to the user and stop immediately. Do not parse the body, do not load conventions, do not call any tools, do not write any files.

` ` `
================================================================================
/<name> — Help
================================================================================

<description>

Usage:
  /<name> <usage line>

Options:
  <flag>          <one-line description>
  ...

Behavior:
  - <2-4 lines of side effects / what it does>

Examples:
  # <example purpose>
  /<name> <example invocation>

  ...

================================================================================
` ` `
<!-- END HELP -->
```

(The `` ` ` ` `` above represents the literal triple-backtick code fence; remove the spaces between the backticks when generating the actual block. The skill body uses spaced backticks here only to avoid breaking this skill file's own markdown rendering.)

## Step 6: Insert or replace

For each target file:

- **Fresh insertion** (no existing block): place the new block after the file's description region (line 1 + any directly-following `Usage:` line + the blank line that follows) and BEFORE the first `## ` heading. If the file has no `## ` headings, insert at end. Use one blank line above and one blank line below the inserted block for visual separation.
- **Marker-bracketed replacement**: replace lines from `<!-- BEGIN HELP -->` through `<!-- END HELP -->` (inclusive) with the new block.
- **Legacy heading-bracketed replacement**: replace from the legacy `## Step 0:` heading line through the line before the next `##` heading (or EOF) with the new marker-wrapped block.

For `--dry-run`:

- Do not write. Print a unified diff per target (use `-` for removed lines, `+` for added) directly into the conversation.
- For `--all --dry-run`, group diffs by file with a clear header per file.

For real writes:

- Use `Edit` (or `Read` + `Write`) on the **dotfiles source path**, never the symlink.
- Modify only the marker region (or insertion zone). Do not touch any line outside it.

## Step 7: Confirm

Print a tight summary:

- Per-target status: `created` / `replaced` / `skipped (already has help)` / `skipped (legacy)` / `skipped (not in dotfiles)` / `skipped (Step 0 conflict)` / `dry-run`.
- For `--all` runs: total counts at the end.
- For files in `needs-migration` (non-dotfiles), list them under a `Migrate to dotfiles:` heading with the suggested `mv` + `ln -s` commands.
- For `--dry-run`: end with `Re-run without --dry-run to apply.`

## Hard rules

- **Always edit the dotfiles source path, not the symlink.** Use `readlink -f` to resolve. Per `feedback_dotfiles_enforcement.md`.
- **Never operate on plugin commands or skills.** This skill targets `~/.claude/commands/*.md` only. Plugin files are upstream-managed and changes are wiped on update.
- **Never operate on personal skills (`~/.claude/skills/*/SKILL.md`).** Skills don't have a `--help` invocation pattern in the same way commands do. If `--help` for skills becomes desirable later, that's a separate skill.
- **Marker comments are canonical.** Heading-only legacy blocks are migrated to markers on first `--refresh`.
- **Refuse to bake into commands not symlinked to dotfiles.** Surface migration instructions instead of silently writing to a non-synced path.
- **Refuse to overwrite a non-help `## Step 0`.** Renumbering existing steps is too risky to automate; let the user resolve manually.
- **Preserve everything outside the marker region.** Hard guarantee — touch only the help block and one blank line of separation above/below it.
