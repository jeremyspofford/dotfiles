# ~/.bashrc - Bash configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Prompt - simple and clean
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Load aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Load secrets (if present, never commit this file!)
[[ -f ~/.secrets ]] && source ~/.secrets

# Load machine-specific configuration
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# Completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Common path additions (add more in ~/.bashrc.local)
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Default editor
export EDITOR=nvim
export VISUAL=nvim

# Enable nvm if installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Enable mise if installed (modern asdf alternative)
command -v mise &> /dev/null && eval "$(mise activate bash)"
