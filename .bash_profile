# Purpose: Load interactive configuration in Bash login shells.
# Usage: Bash reads this file when a login shell starts.
# Login Bash sessions use the same managed startup as interactive non-login Bash.
if [[ -r "$HOME/.bashrc" ]]; then
	. "$HOME/.bashrc"
fi
