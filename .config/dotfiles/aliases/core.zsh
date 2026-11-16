# Portable shortcuts salvaged from Workbench and the preserved WSL aliases.
# Keep standard commands (ls, cat, cp, mv, grep, df, du, vim, pip) unchanged.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias '~'='cd ~'

if command -v eza >/dev/null 2>&1; then
	alias ll='eza --long --all --group-directories-first --git'
	alias la='eza --all'
	alias l='eza --classify'
	alias lt="eza --tree --level=2 --group-directories-first --ignore-glob='node_modules|__pycache__|venv|dist|build|target'"
	alias lsl='eza --long | grep "^l"'
else
	alias ll='ls -alF'
	alias la='ls -A'
	alias l='ls -CF'
	alias lsl='ls -l | grep "^l"'
fi

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate -20'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias psg='ps aux | grep -v grep | grep -i'
case ${DOTFILES_PLATFORM:-} in
darwin)
	alias duh='du -h -d 1 | sort -hr'
	alias topcpu='ps aux -r | head -20'
	alias topmem='ps aux -m | head -20'
	alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
	alias start='open'
	;;
linux | wsl)
	alias duh='du -h --max-depth=1 | sort -hr'
	alias topcpu='ps aux --sort=-%cpu | head -20'
	alias topmem='ps aux --sort=-%mem | head -20'
	alias ports='ss -tulanp'
	if [[ ${DOTFILES_PLATFORM:-} == wsl ]] && command -v explorer.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
		_open_path() { explorer.exe "$(wslpath -w "${1:-.}")" 2>/dev/null; }
		alias start='_open_path'
	elif command -v xdg-open >/dev/null 2>&1; then
		alias start='xdg-open'
	fi
	;;
esac
# dotfleet:group docker begin
if command -v docker >/dev/null 2>&1; then
	alias d='docker'
	alias dc='docker compose'
	alias dps='docker ps'
	alias dpa='docker ps -a'
	alias di='docker images'
	alias dex='docker exec -it'
	alias dlog='docker logs -f'
fi
# dotfleet:group docker end
# dotfleet:group kubectl begin
if command -v kubectl >/dev/null 2>&1; then
	alias k='kubectl'
	alias kgp='kubectl get pods'
	alias kgs='kubectl get svc'
	alias kgd='kubectl get deployments'
	alias kga='kubectl get all'
	alias kd='kubectl describe'
	alias kl='kubectl logs -f'
	alias kex='kubectl exec -it'
fi
# dotfleet:group kubectl end
# dotfleet:group terraform begin
if command -v terraform >/dev/null 2>&1; then
	alias tf='terraform'
	alias tfi='terraform init'
	alias tfp='terraform plan'
	alias tfa='terraform apply'
fi
# dotfleet:group terraform end
# dotfleet:group python begin
if command -v python3 >/dev/null 2>&1; then
	alias py='python3'
	alias venv='python3 -m venv'
	alias activate='source venv/bin/activate'
	alias serve='python3 -m http.server 8000'
fi
# dotfleet:group python end
# dotfleet:group npm begin
if command -v npm >/dev/null 2>&1; then
	alias ni='npm install'
	alias nr='npm run'
	alias ns='npm start'
	alias nt='npm test'
fi
# dotfleet:group npm end
if command -v nvim >/dev/null 2>&1; then
	alias v='nvim'
fi
if command -v uuidgen >/dev/null 2>&1; then
	alias uuid='uuidgen | tr "[:upper:]" "[:lower:]"'
fi

# Keep exports in the current shell; no personal/default profile or credential log.
# AWS CLI's env format supplies its own export statements.
if command -v aws >/dev/null 2>&1; then
	sso() {
		local profile="${1:-${AWS_PROFILE:-}}"
		local credentials
		if [[ -z $profile ]]; then
			printf 'Usage: sso PROFILE (or set AWS_PROFILE)\n' >&2
			return 2
		fi
		aws sso login --profile "$profile" || return
		credentials=$(aws configure export-credentials --profile "$profile" --format env) || return
		eval "$credentials" || return
		export AWS_PROFILE="$profile"
		aws sts get-caller-identity --query 'Arn' --output text
	}
fi

# dotfleet:group helpers begin
if command -v dotfleet >/dev/null 2>&1; then
	alias fleet='dotfleet'
fi
# dotfleet:group helpers end
