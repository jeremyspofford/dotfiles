#!/bin/bash
# ignore-patterns.sh
# Sourced by other hook scripts. Defines paths that should never
# trigger wiki capture. Add to this list as needed.

WIKI_IGNORE_PATTERNS=(
    '\.worktrees'    # git worktree subdirectories
    '\.git'          # git internals
    'node_modules'   # js dependencies
    '\.cache'        # cache directories
    'vendor'         # vendored dependencies
    'dist'           # build output
    'build'          # build output
    '\.venv'         # python virtual environments
    '\.cargo'        # rust cargo cache
    '\.rustup'       # rust toolchain
    '\.nvm'          # node version manager
    '\.npm'          # npm cache
)

# Returns 0 (true) if the given path should be ignored, 1 (false) if not
should_ignore_path() {
    local path="$1"
    for pattern in "${WIKI_IGNORE_PATTERNS[@]}"; do
        if echo "$path" | grep -qE "(^|/)${pattern}(/|$)"; then
            return 0
        fi
    done
    return 1
}
