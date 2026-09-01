#!/usr/bin/env bash

set -u
set -o pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-smoke.XXXXXX") || {
	printf 'Unable to create smoke-test directory.\n' >&2
	exit 1
}
FAILURES=0

cleanup() {
	case "$TEST_ROOT" in
		"${TMPDIR:-/tmp}"/dotfiles-smoke.*) rm -rf -- "$TEST_ROOT" ;;
	esac
}
trap cleanup EXIT HUP INT TERM

pass() {
	printf 'ok - %s\n' "$1"
}

fail() {
	printf 'not ok - %s\n' "$1" >&2
	FAILURES=$((FAILURES + 1))
}

run_test() {
	local description=$1
	shift
	if "$@"; then
		pass "$description"
	else
		fail "$description"
	fi
}

mode_of() {
	stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

test_bootstrap_dry_run() {
	local test_home="$TEST_ROOT/dry-run-home"
	local output
	mkdir -p "$test_home/.ssh"
	printf '%s\n' 'ssh-ed25519 existing-key dry-run@test' > "$test_home/.ssh/authorized_keys"
	chmod 644 "$test_home/.ssh/authorized_keys"

	output=$(HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --dry-run --force 2>&1) || {
		printf '%s\n' "$output" >&2
		return 1
	}

	[ ! -e "$test_home/.bashrc" ] || return 1
	[ ! -d "$test_home/.dotfiles-backups" ] || return 1
	[ "$(mode_of "$test_home/.ssh/authorized_keys")" = 644 ] || return 1
	[ "$(cat "$test_home/.ssh/authorized_keys")" = 'ssh-ed25519 existing-key dry-run@test' ] || return 1
	case "$output" in
		*'.bashrc'*) ;;
		*) return 1 ;;
	esac
	case "$output" in
		*'.ssh/authorized_keys'*merge*) ;;
		*) return 1 ;;
	esac
}

test_bootstrap_cancel() {
	local test_home="$TEST_ROOT/cancel-home"
	mkdir -p "$test_home/.ssh"
	printf '%s\n' 'ssh-ed25519 existing-key cancel@test' > "$test_home/.ssh/authorized_keys"
	chmod 644 "$test_home/.ssh/authorized_keys"

	printf 'n\n' | HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" >/dev/null || return 1

	[ ! -e "$test_home/.bashrc" ] || return 1
	[ ! -d "$test_home/.dotfiles-backups" ] || return 1
	[ "$(mode_of "$test_home/.ssh/authorized_keys")" = 644 ] || return 1
	[ "$(cat "$test_home/.ssh/authorized_keys")" = 'ssh-ed25519 existing-key cancel@test' ]
}

test_bootstrap_rejects_unsafe_home_alias() {
	if HOME=/tmp/.. bash "$REPO_ROOT/bootstrap.sh" --dry-run --force >/dev/null 2>&1; then
		return 1
	fi
}

test_bootstrap_rejects_authorized_keys_symlink() {
	local test_home="$TEST_ROOT/symlink-home"
	local linked_keys="$TEST_ROOT/linked-authorized-keys"
	mkdir -p "$test_home/.ssh"
	printf '%s\n' 'ssh-ed25519 linked-key symlink@test' > "$linked_keys"
	ln -s "$linked_keys" "$test_home/.ssh/authorized_keys"

	if HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --force >/dev/null 2>&1; then
		return 1
	fi

	[ -L "$test_home/.ssh/authorized_keys" ] || return 1
	[ "$(cat "$linked_keys")" = 'ssh-ed25519 linked-key symlink@test' ] || return 1
	[ ! -e "$test_home/.bashrc" ] || return 1
	[ ! -d "$test_home/.dotfiles-backups" ]
}

test_bootstrap_install() {
	local test_home="$TEST_ROOT/install-home"
	local backup_file
	local line
	mkdir -p "$test_home/.ssh"
	printf '%s\n' 'ssh-ed25519 existing-key install@test' > "$test_home/.ssh/authorized_keys"
	printf '%s\n' 'Host example' > "$test_home/.ssh/config"
	chmod 640 "$test_home/.ssh/config"
	printf '%s\n' 'local aliases' > "$test_home/.aliases"
	printf '%s\n' 'keep me' > "$test_home/unrelated.txt"

	HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --force >/dev/null || return 1

	[ -f "$test_home/.bashrc" ] || return 1
	[ -f "$test_home/.config/alacritty/alacritty.toml" ] || return 1
	[ -f "$test_home/.config/git/ignore" ] || return 1
	[ -f "$test_home/unrelated.txt" ] || return 1
	[ ! -e "$test_home/.gitignore" ] || return 1
	[ ! -e "$test_home/.gitattributes" ] || return 1
	[ ! -e "$test_home/.gitmodules" ] || return 1
	[ ! -e "$test_home/.github" ] || return 1
	[ ! -e "$test_home/tests" ] || return 1
	[ ! -e "$test_home/README.md" ] || return 1
	[ ! -e "$test_home/Tomorrow_Night_Bright.terminal" ] || return 1
	if [ "$(uname -s)" = Darwin ]; then
		[ -f "$test_home/Library/Application Support/iTerm2/DynamicProfiles/Tomorrow Night Bright.json" ] || return 1
	else
		[ ! -e "$test_home/Library" ] || return 1
	fi
	[ ! -e "$test_home/.ssh/authorized_keys.bak" ] || return 1
	[ "$(mode_of "$test_home/.ssh")" = 700 ] || return 1
	[ "$(mode_of "$test_home/.ssh/authorized_keys")" = 600 ] || return 1
	[ "$(mode_of "$test_home/.ssh/config")" = 640 ] || return 1
	grep -Fqx 'ssh-ed25519 existing-key install@test' "$test_home/.ssh/authorized_keys" || return 1
	while IFS= read -r line; do
		[ -z "$line" ] || grep -Fqx -- "$line" "$test_home/.ssh/authorized_keys" || return 1
	done < "$REPO_ROOT/.ssh/authorized_keys"
	[ -z "$(sort "$test_home/.ssh/authorized_keys" | uniq -d)" ] || return 1

	[ "$(mode_of "$test_home/.dotfiles-backups")" = 700 ] || return 1
	backup_file=$(find "$test_home/.dotfiles-backups" -type f -name .aliases -print -quit)
	[ -n "$backup_file" ] || return 1
	grep -Fqx 'local aliases' "$backup_file" || return 1
	backup_file=$(find "$test_home/.dotfiles-backups" -type f -path '*/.ssh/authorized_keys' -print -quit)
	[ -n "$backup_file" ] || return 1
	grep -Fqx 'ssh-ed25519 existing-key install@test' "$backup_file" || return 1
}

test_bootstrap_preserves_unrelated_ssh_files() {
	local source_root="$TEST_ROOT/ssh-source"
	local test_home="$TEST_ROOT/ssh-home"
	mkdir -p "$source_root/.ssh" "$test_home/.ssh"
	cp "$REPO_ROOT/bootstrap.sh" "$source_root/bootstrap.sh"
	printf '%s\n' 'ssh-ed25519 source-key source@test' > "$source_root/.ssh/authorized_keys"
	printf '%s\n' 'source-owned' > "$source_root/.ssh/config"
	printf '%s\n' 'destination-original' > "$test_home/.ssh/config"
	chmod 640 "$test_home/.ssh/config"

	HOME="$test_home" bash "$source_root/bootstrap.sh" --force >/dev/null || return 1

	[ "$(cat "$test_home/.ssh/config")" = 'destination-original' ] || return 1
	[ "$(mode_of "$test_home/.ssh/config")" = 640 ] || return 1
}

test_bootstrap_excludes_nested_git_metadata() {
	local source_root="$TEST_ROOT/git-metadata-source"
	local test_home="$TEST_ROOT/git-metadata-home"
	mkdir -p "$source_root/.ssh" "$source_root/.vim/bundle/file-marker" \
		"$source_root/.vim/bundle/directory-marker/.git" "$test_home"
	cp "$REPO_ROOT/bootstrap.sh" "$source_root/bootstrap.sh"
	cp "$REPO_ROOT/.ssh/authorized_keys" "$source_root/.ssh/authorized_keys"
	printf '%s\n' 'gitdir: ../../../.git/modules/example' > "$source_root/.vim/bundle/file-marker/.git"
	printf '%s\n' 'plugin content' > "$source_root/.vim/bundle/file-marker/plugin.txt"
	printf '%s\n' '[core]' > "$source_root/.vim/bundle/directory-marker/.git/config"
	printf '%s\n' 'plugin content' > "$source_root/.vim/bundle/directory-marker/plugin.txt"

	HOME="$test_home" bash "$source_root/bootstrap.sh" --force >/dev/null || return 1

	[ -f "$test_home/.vim/bundle/file-marker/plugin.txt" ] || return 1
	[ -f "$test_home/.vim/bundle/directory-marker/plugin.txt" ] || return 1
	[ ! -e "$test_home/.vim/bundle/file-marker/.git" ] || return 1
	[ ! -e "$test_home/.vim/bundle/directory-marker/.git" ]
}

test_prompt_safety_and_status() {
	local repo="$TEST_ROOT/prompt-repo"
	local expanded
	mkdir -p "$repo"
	git -C "$repo" init -q || return 1
	git -C "$repo" config user.name test
	git -C "$repo" config user.email test@example.com
	printf 'tracked\n' > "$repo/index-delete"
	printf 'tracked\n' > "$repo/worktree-delete"
	git -C "$repo" add index-delete worktree-delete
	git -C "$repo" commit -qm initial || return 1
	# shellcheck disable=SC2016 # This must remain a literal hostile ref name.
	git -C "$repo" checkout -qb '$(touch${IFS}PWNED)' || return 1
	git -C "$repo" rm -q index-delete || return 1
	rm "$repo/worktree-delete"
	printf 'new\n' > "$repo/untracked"

	(
		cd "$repo" || exit 1
		export TERM=dotfiles-unknown USER=test
		unset SSH_TTY
		PROMPT_COMMAND='printf "";'
		# shellcheck source=/dev/null
		. "$REPO_ROOT/.bash_prompt"
		first_prompt_command=$PROMPT_COMMAND
		# shellcheck source=/dev/null
		. "$REPO_ROOT/.bash_prompt"
		[ "$PROMPT_COMMAND" = "$first_prompt_command" ] || exit 1
		[ "$TERM" = dotfiles-unknown ] || exit 1
		case "$PROMPT_COMMAND" in *'printf ""'*) ;; *) exit 1 ;; esac
		case "$PROMPT_COMMAND" in *'__build_prompt'*) ;; *) exit 1 ;; esac
		eval "$PROMPT_COMMAND"
		if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
			expanded=$(eval 'printf "%s" "${PS1@P}"')
		else
			expanded=$PS1
		fi
		[ ! -e PWNED ] || exit 1
		case "$expanded" in
			*'[!+?]'*) ;;
			*) exit 1 ;;
		esac
	)
}

test_non_login_interactive_bash_startup() {
	local test_home="$TEST_ROOT/non-login-home"
	mkdir -p "$test_home/bin"
	HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --force >/dev/null || return 1
	printf '%s\n' 'export EDITOR=local-editor' "alias ll='printf local-ll'" > "$test_home/.extra"

	HOME="$test_home" PATH=/usr/bin:/bin bash --noprofile --norc -ic '
		unset EDITOR HISTSIZE
		. "$HOME/.bashrc"
		[ "$EDITOR" = local-editor ] || exit 1
		case "$(alias ll)" in *local-ll*) ;; *) exit 1 ;; esac
		[ "$HISTSIZE" = 100000 ] || exit 1
		case ":$PATH:" in *":$HOME/bin:"*) ;; *) exit 1 ;; esac
		if [ -d /usr/local/bin ]; then
			case ":$PATH:" in *":/usr/local/bin:"*) ;; *) exit 1 ;; esac
		fi
	' >/dev/null 2>&1
}

test_ssh_completion_safety() {
	local test_home="$TEST_ROOT/ssh-completion-home"
	mkdir -p "$test_home/.ssh"
	HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --force >/dev/null || return 1
	# shellcheck disable=SC2016 # This must remain a literal hostile Host token.
	printf '%s\n' 'Host safe-host $(touch${IFS}PWNED) *.wild' > "$test_home/.ssh/config"

	HOME="$test_home" bash --noprofile --norc -ic '
		. "$HOME/.bashrc"
		completion_spec=$(complete -p ssh) || exit 1
		case "$completion_spec" in *safe-host*) ;; *) exit 1 ;; esac
		case "$completion_spec" in *touch*|*PWNED*|*wild*) exit 1 ;; esac
	' >/dev/null 2>&1 || return 1
	[ ! -e "$test_home/PWNED" ]
}

test_shell_startup_and_helpers() {
	local test_home="$TEST_ROOT/shell-home"
	local work="$TEST_ROOT/short path"
	local escaped
	mkdir -p "$test_home/.ssh" "$test_home/bin" "$work/child" "$TEST_ROOT/tmp"
	HOME="$test_home" bash "$REPO_ROOT/bootstrap.sh" --force >/dev/null || return 1

	HOME="$test_home" PATH=/usr/bin:/bin bash --noprofile --norc -c '
		. "$HOME/.bash_profile"
		first_path=$PATH
		. "$HOME/.bash_profile"
		[ "$PATH" = "$first_path" ]
		case ":$PATH:" in *":$HOME/bin:"*) ;; *) exit 1 ;; esac
		case ":$PATH:" in *":$HOME/.local/bin:"*) exit 1 ;; esac
	' || return 1

	HOME="$test_home" bash --noprofile --norc -c '
		unset GPG_TTY
		. "$HOME/.exports"
		[ -z "${GPG_TTY+x}" ]
	' || return 1

	HOME="$test_home" bash --noprofile --norc -c '
		dircolors() { : > "$HOME/dircolors-called"; }
		export -f dircolors
		. "$HOME/.bashrc"
	' || return 1
	[ ! -e "$test_home/dircolors-called" ] || return 1

	# shellcheck source=/dev/null
	. "$REPO_ROOT/.functions"
	escaped=$(escape '%s') || return 1
	[ "$escaped" = '\x25\x73' ] || return 1
	escaped=$(escape '中') || return 1
	[ "$escaped" = '\xE4\xB8\xAD' ] || return 1
	killport not-a-port >/dev/null 2>&1 && return 1
	(
		local_log="$TEST_ROOT/openssl.log"
		# shellcheck disable=SC2317 # getcertnames resolves this test double dynamically.
		openssl() {
			printf '%s\n' "$*" >> "$local_log"
			if [ "$1" = s_client ]; then
				printf '%s\n' '-----BEGIN CERTIFICATE-----' 'test' '-----END CERTIFICATE-----'
			else
				printf '%s\n' 'Subject: CN=example.com' 'X509v3 Subject Alternative Name:' ' DNS:example.com'
			fi
		}
		getcertnames example.com >/dev/null || exit 1
		grep -Fq 's_client -connect example.com:443 -servername example.com' "$local_log" || exit 1
	) || return 1
	(
		kill_log="$TEST_ROOT/kill.log"
		# shellcheck disable=SC2317 # killport resolves these test doubles dynamically.
		lsof() { printf '%s\n' 101 202; }
		# shellcheck disable=SC2317
		kill() { printf '%s\n' "$*" >> "$kill_log"; }
		killport 8080 >/dev/null || exit 1
		[ "$(cat "$kill_log")" = $'101\n202' ] || exit 1
	) || return 1
	(
		claude_log="$TEST_ROOT/claude.log"
		# shellcheck disable=SC2317 # cmt resolves this test double dynamically.
		claude() { printf '%s\n' "$*" > "$claude_log"; }
		cmt || exit 1
		[ "$(cat "$claude_log")" = '--dangerously-skip-permissions commit' ] || exit 1
	) || return 1
	(
		export TMPDIR="$TEST_ROOT/tmp"
		cd "$work" || exit 1
		short || exit 1
		cd child || exit 1
		long || exit 1
		[ "$PWD" = "$work/child" ] || exit 1
		[ -z "${DOTFILES_SHORT_DIR:-}" ] || exit 1
	)
}

test_config_formats() {
	python3 - "$REPO_ROOT" <<'PY'
import json
import pathlib
import plistlib
import re
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
alacritty = tomllib.loads(
    (root / ".config/alacritty/alacritty.toml").read_text(encoding="utf-8")
)
assert alacritty["font"]["normal"]["family"] == "IBM Plex Mono"
assert alacritty["terminal"]["osc52"] == "OnlyCopy"
assert len(alacritty["keyboard"]["bindings"]) == 12

profile_path = root / "Library/Application Support/iTerm2/DynamicProfiles/Tomorrow Night Bright.json"
profile_doc = json.loads(profile_path.read_text(encoding="utf-8"))
assert list(profile_doc) == ["Profiles"]
assert len(profile_doc["Profiles"]) == 1
profile = profile_doc["Profiles"][0]
assert profile["Name"] == "Tomorrow Night Bright"
assert re.fullmatch(r"[0-9a-fA-F-]{36}", profile["Guid"])
assert "/Users/" not in profile_path.read_text(encoding="utf-8")

with (root / "Tomorrow_Night_Bright.terminal").open("rb") as terminal_file:
    plistlib.load(terminal_file)

assert not (root / ".alacritty.yml").exists()
assert not (root / "iTerm.profile.json").exists()
PY
}

test_git_config() {
	# shellcheck disable=SC2088 # Git stores and expands this literal path itself.
	[ "$(git config --file "$REPO_ROOT/.gitconfig" --get core.excludesfile)" = '~/.config/git/ignore' ] || return 1
	[ "$(git config --file "$REPO_ROOT/.gitconfig" --get user.useConfigOnly)" = true ] || return 1
	[ "$(git config --file "$REPO_ROOT/.gitconfig" --get fetch.prune)" = true ] || return 1
	[ "$(git config --file "$REPO_ROOT/.gitconfig" --get help.autocorrect)" = prompt ] || return 1
	[ -z "$(git config --file "$REPO_ROOT/.gitconfig" --get alias.ca)" ] || return 1
	# shellcheck disable=SC2088 # Git stores and expands this literal path itself.
	[ "$(git config --file "$REPO_ROOT/.gitconfig" --get include.path)" = '~/.gitconfig.local' ] || return 1
	[ "$(git -C "$REPO_ROOT" check-attr eol -- bootstrap.sh | awk '{print $3}')" = lf ] || return 1
}

test_vim_behavior() {
	command -v vim >/dev/null 2>&1 || return 0
	local latin1="$TEST_ROOT/latin1.txt"
	local folds="$TEST_ROOT/folds.txt"
	local type="$TEST_ROOT/filetype.txt"
	printf '\351\n' > "$latin1"
	printf 'print("ok")\n' > "$TEST_ROOT/example.py"
	printf 'plain\n' > "$TEST_ROOT/example.txt"
	printf 'key=value\n' > "$TEST_ROOT/example.conf"

	HOME="$REPO_ROOT" TERM=xterm-256color vim -Nu "$REPO_ROOT/.vimrc" -i NONE -n -es \
		-c 'write' -c 'quit' "$latin1" || return 1
	[ "$(od -An -tx1 "$latin1" | tr -d ' \n')" = e90a ] || return 1

	HOME="$REPO_ROOT" TERM=xterm-256color vim -Nu "$REPO_ROOT/.vimrc" -i NONE -n -es \
		-c "edit $TEST_ROOT/example.py" \
		-c "edit $TEST_ROOT/example.txt" \
		-c "call writefile([&l:foldmethod], '$folds')" \
		-c "edit $TEST_ROOT/example.conf" \
		-c "call writefile([&l:filetype], '$type')" \
		-c 'quitall!' || return 1
	[ "$(cat "$folds")" = marker ] || return 1
	[ "$(cat "$type")" != dosini ] || return 1
}

test_tmux_config() {
	command -v tmux >/dev/null 2>&1 || return 0
	local socket="dotfiles-smoke-$$"
	local result=0
	TMUX='' tmux -L "$socket" -f "$REPO_ROOT/.tmux.conf" new-session -d || return 1
	[ "$(tmux -L "$socket" show-options -gv default-terminal)" = tmux-256color ] || result=1
	[ "$(tmux -L "$socket" show-options -sv set-clipboard)" = external ] || result=1
	tmux -L "$socket" show-options -sv terminal-features | grep -Fq 'alacritty*:RGB:clipboard' || result=1
	tmux -L "$socket" list-keys -T copy-mode-vi | grep -Fq 'copy-selection-and-cancel' || result=1
	tmux -L "$socket" kill-server
	return "$result"
}

test_dircolors_terminal_support() {
	command -v dircolors >/dev/null 2>&1 || return 0
	local terminal output
	for terminal in alacritty tmux-256color; do
		output=$(TERM="$terminal" dircolors "$REPO_ROOT/.dircolors.ansi-dark") || return 1
		case "$output" in
			*"LS_COLORS='';"*) return 1 ;;
		esac
	done
}

run_test 'bootstrap dry-run is side-effect free' test_bootstrap_dry_run
run_test 'bootstrap cancellation is side-effect free' test_bootstrap_cancel
run_test 'bootstrap rejects HOME paths that resolve to root' test_bootstrap_rejects_unsafe_home_alias
run_test 'bootstrap rejects an authorized_keys symlink before installing' test_bootstrap_rejects_authorized_keys_symlink
run_test 'bootstrap installs safely with backups and merged SSH keys' test_bootstrap_install
run_test 'bootstrap preserves unrelated SSH files' test_bootstrap_preserves_unrelated_ssh_files
run_test 'bootstrap excludes nested Git metadata' test_bootstrap_excludes_nested_git_metadata
run_test 'prompt handles every porcelain state without evaluating branch names' test_prompt_safety_and_status
run_test 'non-login interactive Bash loads shared startup settings' test_non_login_interactive_bash_startup
run_test 'SSH completion ignores aliases with shell metacharacters' test_ssh_completion_safety
run_test 'shell startup and helper functions are portable and idempotent' test_shell_startup_and_helpers
run_test 'terminal configuration files use valid current formats' test_config_formats
run_test 'Git configuration separates repository and global ignores safely' test_git_config
run_test 'Vim preserves legacy encodings and buffer-local settings' test_vim_behavior
run_test 'tmux enables precise RGB and one-way OSC52 clipboard support' test_tmux_config
run_test 'dircolors supports the configured terminal types' test_dircolors_terminal_support

if [ "$FAILURES" -ne 0 ]; then
	printf '%s test(s) failed\n' "$FAILURES" >&2
	exit 1
fi

printf 'All smoke tests passed.\n'
