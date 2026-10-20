# Workbench shortcuts

Open a new terminal to load the current configuration. Existing shell processes
keep their previous settings. These defaults are managed in `chezmoi/`.

## Shell

| Action | Shortcut or command |
| --- | --- |
| Complete commands, options and paths | Tab; Tab again opens the selection menu |
| Move backward through completion candidates | Shift-Tab |
| Search history matching what you have typed | Up / Down |
| Accept a gray history suggestion (zsh) | Right arrow at the end of the line |
| Fuzzy history search | Ctrl-R |
| Find a file and insert its path, with a preview | Ctrl-T |
| Find and enter a directory | Alt-C (or Esc, then C) |
| Fuzzy path completion | Type a path followed by `**`, then Tab |
| Detailed colored directory listing | `ll` |
| Two-level directory tree | `lt` |

Zsh highlights valid commands and invalid command names as you type. Its prompt
shows the Git branch, and a green/red prompt character reflects the last command's
exit status. Branch display does not scan for dirty files. Bash has a colored
prompt, case-insensitive completion, prefix history search, and fzf bindings;
history autosuggestions and live syntax highlighting are zsh features.

File searches respect Git ignore rules, include hidden files, and exclude `.git`.
In macOS terminal settings, Option may need to be configured to send Meta/Esc for
Alt shortcuts; the two-key Esc alternative works without that change.

The zsh plugins are installed through Homebrew, never fetched at shell startup.
See the upstream [fzf shortcut guide](https://junegunn.github.io/fzf/shell-integration/)
and [autosuggestions guide](https://github.com/zsh-users/zsh-autosuggestions).

## tmux

Press Ctrl-A, release, then the listed key. New sessions load the configuration;
in an existing session, Ctrl-A then `r` reloads it (use the current prefix if that
server was started with older settings).

| Key | Action |
| --- | --- |
| `\|` | Split into left/right panes in the current directory |
| `-` | Split into top/bottom panes in the current directory |
| `c` | New window in the current directory |
| `[` | Enter copy mode; `v` starts selection, `y` copies to tmux's buffer |
| `]` | Paste tmux's buffer |
| `r` | Reload tmux configuration |

Mouse support is enabled. Window numbers close gaps when windows are removed.

## Neovim

The leader key is Space. These mappings apply in normal mode unless noted.

| Shortcut | Action |
| --- | --- |
| Space, `w` | Save |
| Space, `e` | Browse files with built-in netrw |
| Ctrl-H / J / K / L | Move between editor splits |
| Space, `y` + motion, or Space, `y` in visual mode | Copy to system clipboard |
| Space, `p` | Paste from system clipboard |
| Esc | Clear search highlighting |
| Ctrl-N / Ctrl-P in insert mode | Native word completion |
| Tab on the command line | Complete commands and paths |

The cursor line is highlighted and scrolling keeps context around the cursor.
Substitution commands show a live preview. Completion is Neovim's built-in word
completion; language-server completion is a later addition.

## Reviewing configuration changes

In zsh, Tab completes Workbench commands, options, component names, and rollback
checkpoint IDs. For example, type `workbench plan --components ` then press Tab,
or type `workbench rollback ` then press Tab. Checkpoint completion also respects
`workbench --state-dir <directory> rollback `. Tab only offers candidates; it
does not execute a transaction. Paste the reviewed hash explicitly for `--plan`.

```sh
workbench --color always plan --existing replace | less -R
workbench plan --existing replace --format html > /tmp/workbench-review.html
```

Apply through Workbench to retain checkpoints. See [the guide](../README.md)
and [recovery guide](recovery.md).
