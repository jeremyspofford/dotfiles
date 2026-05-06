#!/usr/bin/env bash
# Claude Code status line — styled after zsh adam1 theme (user@host: dir)
# Augmented with model name and context window usage.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Build the adam1-style prefix: user@host: dir
prefix="$(whoami)@$(hostname -s): ${short_cwd}"

# Build context indicator if available
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    ctx_str="ctx:${used_int}%"
else
    ctx_str=""
fi

# Assemble output with ANSI colors (dimmed-friendly)
# Green for user@host, default for path, dim for model/ctx
if [ -n "$model" ] && [ -n "$ctx_str" ]; then
    printf "\033[32m%s\033[0m  \033[2m%s  %s\033[0m" "$prefix" "$model" "$ctx_str"
elif [ -n "$model" ]; then
    printf "\033[32m%s\033[0m  \033[2m%s\033[0m" "$prefix" "$model"
else
    printf "\033[32m%s\033[0m" "$prefix"
fi
