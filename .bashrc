# Purpose: Set interactive Bash behavior.
# Usage: Bash reads this file when an interactive shell starts.
# Bash-specific startup salvaged from the preserved WSL configuration.
case $- in
*i*) ;;
*) return ;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize

. "$HOME/.commonrc"

if command -v dircolors >/dev/null 2>&1; then
	if [[ -r "$HOME/.dircolors" ]]; then
		eval "$(dircolors -b "$HOME/.dircolors")"
	else
		eval "$(dircolors -b)"
	fi
fi
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
if command -v starship >/dev/null 2>&1; then
	eval "$(starship init bash)"
fi

if ! shopt -oq posix; then
	if [[ -r /usr/share/bash-completion/bash_completion ]]; then
		. /usr/share/bash-completion/bash_completion
	elif [[ -r /etc/bash_completion ]]; then
		. /etc/bash_completion
	fi
fi
if command -v aws_completer >/dev/null 2>&1; then
	complete -C "$(command -v aws_completer)" aws
fi
if [[ -r "$HOME/.bashrc.local" ]]; then
	. "$HOME/.bashrc.local"
fi
