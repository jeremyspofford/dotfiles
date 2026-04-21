# ~/.bashrc — Bash-specific configuration

# Non-interactive? Bail.
case $- in
  *i*) ;;
    *) return ;;
esac

# ─── Bash options ─────────────────────────────────────────────────────
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# ─── Color support ────────────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ─── Prompt ───────────────────────────────────────────────────────────
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# ─── Completion ───────────────────────────────────────────────────────
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ─── Common config ────────────────────────────────────────────────────
[ -f ~/.commonrc ] && . ~/.commonrc

# ─── Machine-specific overrides ──────────────────────────────────────
[ -f ~/.bashrc.local ] && . ~/.bashrc.local
