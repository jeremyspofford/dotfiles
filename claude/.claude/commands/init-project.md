Scaffold a complete Claude configuration for the current project. This replaces and extends the built-in `/init` command — it generates the project `CLAUDE.md` AND the `.claude/settings.json` with hooks tuned to the project's actual toolchain.

## Steps

### 1. Scan the project

Read the current directory thoroughly. Look for:
- Language/runtime indicators: `package.json`, `bun.lockb`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `*.csproj`
- Config files: `mise.toml`, `Makefile`, `Dockerfile`, `docker-compose.yml`, `.env.example`
- Test setup: `vitest.config.*`, `jest.config.*`, `pytest.ini`, `conftest.py`
- Formatter/linter config: `.prettierrc`, `eslint.config.*`, `ruff.toml`, `.golangci.yml`
- Existing Claude config: `CLAUDE.md`, `.claude/settings.json`
- README.md for project description and conventions

### 2. Check for existing config

If `CLAUDE.md` or `.claude/settings.json` already exist, read them and offer to extend rather than overwrite. Present a diff of what would change and confirm before writing.

### 3. Create `CLAUDE.md` at the project root

Structure:
```markdown
# <Project Name>

<1-2 sentence description of what this project does>

## Stack

<language, runtime, key frameworks/libraries>

## Dev Setup

<how to install dependencies and run locally>

## Common Commands

<the commands someone needs day-to-day: dev server, tests, build, lint>

## Conventions

<anything non-obvious: naming patterns, file structure, coding standards>

## Definition of Done

<what needs to pass before a change is complete: tests? types? lint?>
```

Fill in everything you can infer from the codebase. Leave a `<!-- TODO: fill in -->` marker only where you genuinely can't determine the answer.

### 4. Create `.claude/settings.json`

Project-specific permissions and hooks. Build only what the project actually uses:

**Permissions** — add `Bash(<tool>:*)` allows for each tool present in the project (e.g. `vitest`, `pytest`, `ruff`, `cargo`, etc.)

**Hooks** — construct, pipe-test, and verify each hook before writing:

- **Formatter on save**: if a formatter exists (prettier, ruff, gofmt, rustfmt), add a `PostToolUse` hook on `Write|Edit` that formats the changed file. Use `jq -r '.tool_input.file_path // .tool_response.filePath'` to extract the path. Guard by file extension.
- **Linter**: if a linter exists alongside the formatter, add it to the same hook or chain it.
- **Test runner**: if the project has a test runner, add a `PostToolUse` hook on `Write|Edit` that runs the test file when a `*.test.*` or `*_test.*` file is edited. Run only the affected file, not the full suite.

For Aria Labs projects (`~/workspace/arialabs/`): hooks should function as quality gates — non-zero exit blocks the operation. For personal projects: hooks are advisory, wrap with `|| true`.

**Do not add hooks speculatively.** Only add what the project's toolchain supports.

### 5. Add `.claude/` to `.gitignore` if needed

`.claude/settings.json` should be committed (it's team/project config). `.claude/settings.local.json` should not. If `.gitignore` exists, ensure `.claude/settings.local.json` is listed.

### 6. Report

Summarise what was created, what was inferred vs assumed, and what the user still needs to fill in.
