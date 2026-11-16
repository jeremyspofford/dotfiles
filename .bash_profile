# Login Bash sessions use the same managed startup as interactive non-login Bash.
if [[ -r "$HOME/.bashrc" ]]; then
	. "$HOME/.bashrc"
fi
