# Purpose: Set the base shell environment.
# Usage: Zsh reads this file on every start.
# Keep this file quiet: zsh reads it even for noninteractive commands.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
typeset -U path PATH
path=("$HOME/.local/bin" $path)
