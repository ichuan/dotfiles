# OSX: after `brew install coreutils`
export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/sbin:/usr/local/bin:${HOME}/bin:/usr/local/opt/python/libexec/bin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=~/Library/Android/sdk
export PATH="$PATH:${ANDROID_HOME}/tools"
export PATH="$PATH:${ANDROID_HOME}/platform-tools"
export PATH="$PATH:${HOME}/go/bin"
export PATH="$PATH:${HOME}/.cargo/bin"
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/opt/curl/bin:$PATH"

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && source "$file"
done
unset file

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null
done

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# If possible, add tab completion for many more commands
[ -f /etc/bash_completion ] && source /etc/bash_completion

# OSX: after `brew install bash_completion`
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# dircolors from https://github.com/seebi/dircolors-solarized
eval `dircolors ~/.dircolors.ansi-dark`

# https://pipenv.kennethreitz.org/en/latest/install/#virtualenv-mapping-caveat
export PIPENV_VENV_IN_PROJECT=1

_lazy_nvm() {
  unalias nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
  [ -s "$HOME/.nvm/bash_completion" ] && . "$HOME/.nvm/bash_completion"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
  nvm "$*"
}
alias nvm=_lazy_nvm

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv > /dev/null && {
  eval "$(pyenv init --path)"
  alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
  if [ -n "$PS1" -a -n "$BASH_VERSION" ]; then
    eval "$(pyenv init -)"
  fi
}
