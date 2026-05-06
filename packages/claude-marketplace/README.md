# Local Claude Code marketplace (`dotfiles-local`)

A Claude Code plugin marketplace bundled into this dotfiles repo. It registers the local-only plugins maintained alongside the dotfiles, so they install through the same `/plugin install` flow as anything from the official Anthropic marketplace.

## Plugins distributed here

| Name | What it is |
| ---- | ---------- |
| `engineering-stack` | Role-aware engineering orchestrator. See [`plugins/engineering-stack/README.md`](plugins/engineering-stack/README.md). |

## Register on a new machine (one-time)

Inside Claude Code:

```
/plugin marketplace add ~/workspace/dotfiles/packages/claude-marketplace
/plugin install engineering-stack@dotfiles-local
```

After install, restart Claude Code if commands aren't visible. Pick "Install for you (user scope)" when prompted unless you want a project- or repo-scoped install.

## Layout

```
claude-marketplace/
├── .claude-plugin/
│   └── marketplace.json        # this marketplace's manifest (name, plugins[])
└── plugins/
    └── engineering-stack -> ../../claude-engineering-plugin
```

Plugin source dirs live as siblings under `packages/` (e.g. `packages/claude-engineering-plugin/`). They're symlinked into `plugins/` here because the marketplace schema requires plugin sources to resolve as children of the marketplace root — `../` paths are not allowed in `source` fields.

## Iterating on an installed plugin

`/plugin install` *copies* the plugin into `~/.claude/plugins/cache/dotfiles-local/<plugin>/<version>/`. Source edits do **not** propagate live. Two paths:

- **Refresh after edits:** `/plugin install --force <plugin>@dotfiles-local`
- **Active development (live reload):**
  ```bash
  claude --plugin-dir ~/workspace/dotfiles/packages/claude-engineering-plugin
  ```
  Use `/reload-plugins` mid-session to pick up file changes without restarting. Marketplace install and `--plugin-dir` can coexist on the same machine.

## Adding a new plugin to this marketplace

1. **Create the plugin source.** Add a new directory under `packages/`, e.g. `packages/claude-foo-plugin/`, with a `.claude-plugin/plugin.json` per [Claude Code's plugin schema](https://code.claude.com/docs/en/plugins). `author` must be an object: `{ "name": "...", "email": "..." }`.
2. **Symlink it under `plugins/`.** From this directory:
   ```bash
   ln -s ../../claude-foo-plugin plugins/foo
   ```
3. **Register it in `marketplace.json`.** Add an entry to the `plugins` array:
   ```json
   { "name": "foo", "description": "...", "category": "...", "source": "./plugins/foo" }
   ```
4. **Refresh and install.** Re-run `/plugin marketplace add ~/workspace/dotfiles/packages/claude-marketplace` to re-read the manifest, then `/plugin install foo@dotfiles-local`.

## Going public later

Renaming the marketplace from `dotfiles-local` to a published-friendly name (e.g. `jspofford-plugins`) is cheap while it's only used locally. After it's shared, downstream consumers would need to migrate their `<plugin>@<old-name>` install references — keep that in mind before publishing.
