#!/bin/bash
# resolve-project-path.sh
# Sourced by other hook scripts and referenced by Claude for /wiki capture.
# Resolves a filesystem path to a domain/project wiki path.
# Strips $HOME/workspace/ prefix to produce the relative domain/project slug.
# Handles git worktrees by resolving to the main worktree root first.

source $HOME/.claude/hooks/ignore-patterns.sh

# Resolve a potentially worktree path to the main git repo root
resolve_git_root() {
    local cwd="$1"

    # If .git is a file (not a dir), we're in a worktree
    if [[ -f "$cwd/.git" ]]; then
        local gitdir_content
        gitdir_content=$(cat "$cwd/.git")
        if echo "$gitdir_content" | grep -q "worktrees"; then
            # Extract main repo path: "gitdir: /path/.git/worktrees/name" -> "/path"
            echo "$gitdir_content" | sed 's/gitdir: //' | sed 's|/\.git/worktrees/.*||'
            return
        fi
    fi

    # Walk up to find git root
    git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd"
}

# Convert an absolute repo path to a domain/project slug
# ~/workspace/alertventure/ft-quoting -> alertventure/ft-quoting
# ~/workspace/portfolio              -> portfolio
# Non-workspace paths (home dir, vault, etc.) -> personal/general (per CLAUDE.md)
path_to_wiki_slug() {
    local abs_path="$1"
    local workspace="$HOME/workspace"

    if [[ "$abs_path" == "$workspace/"* ]]; then
        echo "${abs_path#$workspace/}"
    else
        # CLAUDE.md: non-workspace paths default to personal/general
        echo "personal/general"
    fi
}

# Main: given a CWD, return the wiki slug (domain/project) or empty string if ignored
get_wiki_slug() {
    local cwd="$1"

    # Check for .nowiki opt-out
    if [[ -f "$cwd/.nowiki" ]]; then
        echo ""
        return
    fi

    # Resolve worktree to main root
    local git_root
    git_root=$(resolve_git_root "$cwd")

    # Check ignore patterns on resolved path
    if should_ignore_path "$git_root"; then
        echo ""
        return
    fi

    path_to_wiki_slug "$git_root"
}
