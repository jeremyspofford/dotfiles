# Recovery

## Configuration checkpoints

Workbench saves private checkpoints in `~/.local/state/workbench/checkpoints/`.
They record previous file contents, permissions, symlinks, and absence.

```sh
workbench checkpoints
workbench rollback <id>
workbench rollback <id> --plan <hash-from-preview>
```

Rollback refuses later edits. To intentionally restore over them, include
`--replace-edits` in both preview and execution; Workbench saves those edits in an
additional recovery checkpoint first. Use `./bin/workbench` from the checkout if
restoring removes the PATH launcher. Package installation is separate and is not
undone by configuration rollback. ACLs and all extended attributes are not saved.

Each file replacement is atomic; the whole set is not one filesystem transaction.
An apply failure attempts restoration; interruption leaves a prepared checkpoint
for recovery. Only files recorded by the checkpoint are restored. Workbench never
recursively removes directories, and it refuses changed original symlink targets.

## Legacy archive on this Mac

The clean-slate archive location is recorded in:

```text
~/.local/state/workbench/clean-slate-archive-path
```

That private directory contains a full pre-cleanup source copy, a Git bundle,
working/index patches, Git configuration, link records, and the retired files.
It includes the pre-existing timecard, Neovim lockfile, and zsh environment edits.
Inspection/activation history and the deferred bootstrap are also archived there.

The local SSH configuration was detached from Stow into a regular 0600 file with
identical contents. Remaining legacy links point into the archive, so removing
the old packages from Git does not break their targets. The new baseline does
not load those legacy shell or Neovim files. Keep the archive while these links
or old rollback records are needed.

Older activation checkpoints contain links into the removed `packages/` tree.
Restoring those requires first recovering the matching original source paths
from the archive. Do not run an old rollback blindly or overwrite the new checkout
wholesale. Compare and recover only the paths needed. Current file-to-file
checkpoints remain usable without the legacy source tree.

Git history remains intact; the clean slate replaces the current tree without
rewriting previous commits. Client repositories and workspace paths are outside
this cleanup.
