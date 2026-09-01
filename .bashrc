# shellcheck shell=bash

case $- in
	*i*) ;;
	*) return ;;
esac

if [ -z "${_DOTFILES_BASH_PROFILE_ACTIVE:-}" ] && [ -r "$HOME/.bash_profile" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.bash_profile"
	return
fi

# Interactive shell behavior.
shopt -s nocaseglob histappend cdspell
for option in autocd globstar; do
	shopt -s "$option" 2>/dev/null || true
done
unset option

# Complete simple SSH aliases without passing shell metacharacters to compgen.
if [ -r "$HOME/.ssh/config" ]; then
	ssh_hosts=$(awk '$1 == "Host" { for (i = 2; i <= NF; i++) if ($i ~ /^[[:alnum:]_.-]+$/) print $i }' "$HOME/.ssh/config")
	if [ -n "$ssh_hosts" ]; then
		complete -o default -o nospace -W "$ssh_hosts" scp sftp ssh
	fi
	unset ssh_hosts
fi

# Load the first system completion script found.
for completion_file in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
	if [ -r "$completion_file" ]; then
		# shellcheck source=/dev/null
		. "$completion_file"
		break
	fi
done
unset completion_file

if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
	# shellcheck source=/dev/null
	. "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

if command -v dircolors >/dev/null 2>&1 && [ -r "$HOME/.dircolors.ansi-dark" ]; then
	eval "$(dircolors "$HOME/.dircolors.ansi-dark")"
fi

# Keep project environments inside their projects.
export PIPENV_VENV_IN_PROJECT=1
export POETRY_VIRTUALENVS_IN_PROJECT=true
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
	# shellcheck source=/dev/null
	. "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
	# shellcheck source=/dev/null
	. "$NVM_DIR/bash_completion"
fi

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [ -d "$PYENV_ROOT/bin" ]; then
	case ":$PATH:" in
		*":$PYENV_ROOT/bin:"*) ;;
		*) export PATH="$PYENV_ROOT/bin:$PATH" ;;
	esac
fi
if command -v pyenv >/dev/null 2>&1; then
	eval "$(pyenv init -)"
	alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
fi
