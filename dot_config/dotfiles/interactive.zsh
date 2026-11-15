# Salvaged Workbench editor and fuzzy-finder settings, with portable fallbacks.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vi
fi
export VISUAL="$EDITOR"
export PAGER=less
export LESS=FRX
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border=rounded --info=inline'
if command -v fd >/dev/null 2>&1; then
  export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}' --preview-window=right:50%"
fi
