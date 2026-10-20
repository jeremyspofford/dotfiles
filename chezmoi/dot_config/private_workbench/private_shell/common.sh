# Workbench interactive defaults. This file never loads legacy shell config.
# shellcheck source=/dev/null
. "$HOME/.config/workbench/shell/env.sh"
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS=FRX

# Explicit convenience commands; standard ls/cat keep their normal behavior.
if command -v eza >/dev/null 2>&1; then
  alias ll='eza --long --all --group-directories-first --git'
  alias lt="eza --tree --level=2 --group-directories-first --ignore-glob='node_modules|__pycache__|venv|dist|build|target'"
fi
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border=rounded --info=inline'
if command -v fd >/dev/null 2>&1; then
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}' --preview-window=right:50%"
fi
