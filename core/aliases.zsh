# Salvaged from Workbench: leave standard ls/cat unchanged.
# Explicit convenience commands; standard ls/cat keep their normal behavior.
if command -v eza >/dev/null 2>&1; then
  alias ll='eza --long --all --group-directories-first --git'
  alias lt="eza --tree --level=2 --group-directories-first --ignore-glob='node_modules|__pycache__|venv|dist|build|target'"
fi
