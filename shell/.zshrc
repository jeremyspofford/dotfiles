# ~/.zshrc — Zsh-specific configuration

# ─── Options ──────────────────────────────────────────────────────────
setopt histignorealldups sharehistory
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# ─── Keybindings ──────────────────────────────────────────────────────
bindkey -e

# ─── Prompt ───────────────────────────────────────────────────────────
autoload -Uz promptinit
promptinit
prompt adam1

# ─── Completion ───────────────────────────────────────────────────────
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# dircolors for completion (Linux only, macOS uses different mechanism)
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
fi

# bun completions (if installed standalone outside mise)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ─── Common config ────────────────────────────────────────────────────
[ -f ~/.commonrc ] && . ~/.commonrc

# ─── Machine-specific overrides ──────────────────────────────────────
[ -f ~/.zshrc.local ] && . ~/.zshrc.local
