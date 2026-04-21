# MCP Servers

Custom Model Context Protocol servers for Jeremy's tooling, each self-contained
in its own subdirectory. The server *implementations* live here; *which* servers
Claude Code loads at user scope is managed declaratively by
[`manifest.json`](#registration-claude-code) + [`register.sh`](#registration-claude-code).

This directory is **not** stowed — server code is invoked by absolute path, and
the manifest/register flow applies config to `~/.claude.json` via the `claude`
CLI. See [Why not `.mcp.json`?](#why-not-mcpjson) below.

## Convention

Each server lives in its own subdirectory with:
- Its own `package.json`, `tsconfig.json`, tests
- No imports from outside its directory
- Environment variables (e.g. `$WIKI_VAULT`) for any external paths — never hardcoded
- A README explaining what the server exposes

This isolation is the extraction contract: when a server is proven, it can be
`git subtree split` into its own repository without untangling dependencies.

## Servers

- [`memory-capture/`](./memory-capture/) — cross-tool daily-log memory capture
  for `$WIKI_VAULT/Assistant/memory/`.

(Third-party servers like `obsidian` and `sequential-thinking` are listed in
`manifest.json` but not vendored here — they're installed on demand via `npx`.)

## Registration (Claude Code)

Claude Code stores user-scope MCP config inside `~/.claude.json`, a live config
file the app writes to constantly (session state, dismissed tips, per-project
overrides). Stowing that file isn't viable, so the manifest lives here and is
applied via the CLI.

### Files

- **[`manifest.json`](./manifest.json)** — declarative list of user-scope MCP
  servers. `$HOME` and other env placeholders are expanded by `envsubst` at
  registration time, so the manifest stays portable across machines.
- **[`register.sh`](./register.sh)** — sync script. Makes `~/.claude.json`'s
  user-scope `mcpServers` converge exactly on the manifest.

### Semantics

`register.sh` is a **true sync**, not an upsert:

1. Servers in the manifest are (re-)registered at user scope.
2. User-scope servers **not** in the manifest are **unregistered**.

The manifest is the sole source of truth. This means:

- Adding a server on one machine → commit `manifest.json` → pull on another →
  run `register.sh` → it's registered there too.
- Removing a server from the manifest on one machine → propagates the same way.
- Quick experiments via `claude mcp add --scope user ...` get wiped on next
  sync. Use **project scope** (`.mcp.json` at a working directory root) for
  transient servers; promote to the manifest once they're keepers.

### Applying changes

```bash
./register.sh
```

Run after editing `manifest.json`, after a fresh dotfiles install (it's called
automatically from `install.sh`), or any time `claude mcp list` doesn't show
what you expect. Then **restart any running Claude Code sessions** — MCP
servers are spawned at session start, so config changes don't take effect
mid-session.

### Dependencies

`bash` (4+), `jq`, `envsubst` (from `gettext`), `claude` CLI. All available on
the standard dotfiles-bootstrapped system.

### Why not `.mcp.json`?

`.mcp.json` is the **project-scope** filename convention in Claude Code. It's
only read when a session's current working directory is a project root that
contains one, and Claude Code doesn't walk up the directory tree to find it.
There is no file-based user-scope equivalent — user-scope entries live
exclusively inside `~/.claude.json` under `mcpServers`. Hence the CLI-based
sync.

## Cursor

Cursor has its own MCP config at `~/.cursor/mcp.json`, managed by the `cursor`
stow package. Cursor reads that path directly, so no registration step is
required on the Cursor side. If a server should be available to both tools,
add it to both the Cursor config and the Claude manifest.
