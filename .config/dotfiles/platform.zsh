# Purpose: Load platform shell settings.
# Usage: Source this file through the managed shell configuration.
# Detect the running shell's system. WSL uses Linux tools and paths.
case $(uname -s) in
Darwin)
	if [[ -x /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi
	export DOTFILES_PLATFORM=darwin
	;;
Linux)
	if [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]] || { [[ -r /proc/version ]] && grep -qi microsoft /proc/version; }; then
		export DOTFILES_PLATFORM=wsl
	else
		export DOTFILES_PLATFORM=linux
	fi
	;;
MINGW* | MSYS* | CYGWIN*) export DOTFILES_PLATFORM=windows ;;
*) export DOTFILES_PLATFORM=unknown ;;
esac
