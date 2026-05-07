# ~/.zshenv — sourced for ALL zsh invocations.
#
# Unlike .zshrc (interactive-only), .zshenv runs for non-interactive shells too,
# including subshells spawned by tools like Claude Code's Bash tool. Anything
# that needs to be in env for scripts and `zsh -c '...'` invocations belongs
# here — keep it minimal and fast (no prompt setup, no aliases, no slow forks).

# Make API tokens / secrets available to all subshells.
# .commonrc also sources this for interactive shells; loading here additionally
# covers non-interactive contexts. Re-sourcing is idempotent for plain exports.
[ -f ~/.secrets ] && source ~/.secrets
