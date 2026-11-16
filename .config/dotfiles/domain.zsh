# Purpose: Load domain shell settings.
# Usage: Source this file through the managed shell configuration.
# One local value selects the domain; shared settings always apply.
DOTFILES_DOMAIN=core
if [[ -r "$HOME/.config/dotfiles/domain" ]]; then
	IFS= read -r DOTFILES_DOMAIN <"$HOME/.config/dotfiles/domain" || true
fi
case $DOTFILES_DOMAIN in
core | personal | work | client) ;;
*) DOTFILES_DOMAIN=core ;;
esac
export DOTFILES_DOMAIN
