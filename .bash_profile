# shellcheck shell=bash

_DOTFILES_BASH_PROFILE_ACTIVE=1

_path_prepend() {
	[ -d "$1" ] || return 0
	case ":${PATH:-}:" in
		*":$1:"*) ;;
		*) PATH="$1${PATH:+:$PATH}" ;;
	esac
}

_path_append() {
	[ -d "$1" ] || return 0
	case ":${PATH:-}:" in
		*":$1:"*) ;;
		*) PATH="${PATH:+$PATH:}$1" ;;
	esac
}

_manpath_prepend() {
	[ -d "$1" ] || return 0
	case ":${MANPATH:-}:" in
		*":$1:"*) ;;
		*)
			if [ -n "${MANPATH:-}" ]; then
				MANPATH="$1:$MANPATH"
			else
				MANPATH="$1:"
			fi
			;;
	esac
}

# Initialize Homebrew at its standard Intel, Apple Silicon, or Linux prefix.
brew_command=
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
	if command -v brew >/dev/null 2>&1; then
		brew_command=$(command -v brew)
	else
		for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
			if [ -x "$candidate" ]; then
				brew_command=$candidate
				break
			fi
		done
	fi
	if [ -n "$brew_command" ]; then
		eval "$("$brew_command" shellenv)"
	fi
fi

_path_prepend "$HOME/bin"
_path_prepend /usr/local/sbin
_path_prepend /usr/local/bin
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
	_path_prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
	_manpath_prepend "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman"
	_path_prepend "$HOMEBREW_PREFIX/opt/openssl/bin"
	_path_prepend "$HOMEBREW_PREFIX/opt/curl/bin"
fi

if [ -d "$HOME/Library/Android/sdk" ]; then
	export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
	export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
fi
if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
	_path_append "$ANDROID_HOME/tools"
	_path_append "$ANDROID_HOME/platform-tools"
fi

_path_append /usr/local/go/bin
_path_append "$HOME/.local/bin"
_path_append "$HOME/.cargo/bin"
_path_append /opt/nvim-linux-x86_64/bin
export PATH
if [ -n "${MANPATH:-}" ]; then
	export MANPATH
fi

# Load shared settings, then interactive helpers, before local overrides.
for file in "$HOME/.path" "$HOME/.exports"; do
	if [ -r "$file" ]; then
		# shellcheck source=/dev/null
		. "$file"
	fi
done

case $- in
	*i*)
		for file in "$HOME/.bash_prompt" "$HOME/.aliases" "$HOME/.functions"; do
			if [ -r "$file" ]; then
				# shellcheck source=/dev/null
				. "$file"
			fi
		done
		;;
esac

if [ -r "$HOME/.extra" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.extra"
fi

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
_path_prepend "$PYENV_ROOT/bin"
export PATH
if command -v pyenv >/dev/null 2>&1; then
	eval "$(pyenv init --path)"
fi

unset brew_command candidate file
unset -f _path_prepend _path_append _manpath_prepend

# Finish interactive-only setup in .bashrc.
if [ -r "$HOME/.bashrc" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.bashrc"
fi
unset _DOTFILES_BASH_PROFILE_ACTIVE
