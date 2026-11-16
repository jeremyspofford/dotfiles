# Purpose: Set login-shell paths.
# Usage: Zsh reads this file when a login shell starts.
# Login shells inherit tools installed by bootstrap.
[[ -r "$HOME/.config/dotfiles/platform.zsh" ]] && source "$HOME/.config/dotfiles/platform.zsh"
