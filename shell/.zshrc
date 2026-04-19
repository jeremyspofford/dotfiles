# ~/.zshrc — Zsh-specific configuration

# ─── Options ──────────────────────────────────────────────────────────
setopt histignorealldups sharehistory
setopt interactive_comments
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# ─── Keybindings ──────────────────────────────────────────────────────
bindkey -v
KEYTIMEOUT=1                                    # 10ms — snappy <Esc> mode switch
bindkey '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward
bindkey '^?' backward-delete-char               # backspace works after <Esc>
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

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

# ─── Plugins ──────────────────────────────────────────────────────────
# Fish-style autosuggestions (installed via apt or brew by install.sh).
# Try known paths in order; silently skip if not found (e.g. pre-bootstrap).
for _p in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [ -r "$_p" ] && source "$_p" && break
done
unset _p

# ─── Common config ───────────────────────────────────────────────────
[ -f ~/.commonrc ] && . ~/.commonrc

# ─── Machine-specific overrides ──────────────────────────────────────
[ -f ~/.zshrc.local ] && . ~/.zshrc.local

# ─── Secrets ─────────────────────────────────────────────────────────
[ -f ~/.secrets ] && . ~/.secrets

# ─── Aliases ─────────────────────────────────────────────────────────
[ -f ~/.aliases ] && . ~/.aliases

# Ollama runs on Windows for performance increase 
# and ease of allowing internal traffic to it.
# ollama from WSL will transparently call the Windows daemon. 
export OLLAMA_HOST=http://host.docker.internal:11434

