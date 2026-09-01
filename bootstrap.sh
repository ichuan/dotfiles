#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
DRY_RUN=0
FORCE=0
AUTHORIZED_KEYS_TMP=

cleanup() {
	if [ -n "$AUTHORIZED_KEYS_TMP" ] && [ -e "$AUTHORIZED_KEYS_TMP" ]; then
		rm -f "$AUTHORIZED_KEYS_TMP"
	fi
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

usage() {
	printf 'Usage: %s [-f|--force] [--dry-run]\n' "${0##*/}"
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-f | --force)
			FORCE=1
			;;
		--dry-run)
			DRY_RUN=1
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown option: %s\n' "$1" >&2
			usage >&2
			exit 2
			;;
	esac
	shift
done

case "${HOME:-}" in
	'')
		printf 'Refusing to install with an unsafe HOME: %s\n' "${HOME:-<unset>}" >&2
		exit 1
		;;
	/*) ;;
	*)
		printf 'HOME must be an absolute path: %s\n' "$HOME" >&2
		exit 1
		;;
esac

if [ ! -d "$HOME" ]; then
	printf 'HOME is not an existing directory: %s\n' "$HOME" >&2
	exit 1
fi
resolved_home=$(cd "$HOME" && pwd -P)
if [ -z "$resolved_home" ] || [ "$resolved_home" = / ]; then
	printf 'Refusing to install with an unsafe HOME: %s\n' "$HOME" >&2
	exit 1
fi
case "$resolved_home/" in
	"$REPO_ROOT/"*)
		printf 'Refusing to install into the repository itself: %s\n' "$resolved_home" >&2
		exit 1
		;;
esac
HOME=$resolved_home
export HOME
unset resolved_home

if ! command -v rsync >/dev/null 2>&1; then
	printf 'bootstrap.sh requires rsync.\n' >&2
	exit 1
fi

source_keys="$REPO_ROOT/.ssh/authorized_keys"
target_keys="$HOME/.ssh/authorized_keys"
if [ ! -f "$source_keys" ]; then
	printf 'Missing repository SSH key file: %s\n' "$source_keys" >&2
	exit 1
fi
if { [ -e "$HOME/.ssh" ] || [ -L "$HOME/.ssh" ]; } && [ ! -d "$HOME/.ssh" ]; then
	printf 'Refusing to replace non-directory SSH path: %s\n' "$HOME/.ssh" >&2
	exit 1
fi
if [ -L "$target_keys" ] || { [ -e "$target_keys" ] && [ ! -f "$target_keys" ]; }; then
	printf 'Refusing to replace non-regular SSH key file: %s\n' "$target_keys" >&2
	exit 1
fi

if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
	read -r -p 'This may overwrite existing files in your home directory. Are you sure? (y/n) ' -n 1 reply
	printf '\n'
	case "$reply" in
		[Yy]) ;;
		*) exit 0 ;;
	esac
fi

rsync_args=(
	-a
	--no-perms
	--itemize-changes
	--exclude=.git
	--exclude=/.gitmodules
	--exclude=/.gitignore
	--exclude=/.gitattributes
	--exclude=/.github/
	--exclude=/tests/
	--exclude=/docs/
	--exclude=/bootstrap.sh
	--exclude=/README.md
	--exclude=/LICENSE-MIT.txt
	--exclude=/Tomorrow_Night_Bright.terminal
	--exclude=/.ssh/
	--exclude=.DS_Store
)

if [ "$(uname -s)" != Darwin ]; then
	rsync_args+=(
		--exclude=/Library/
	)
fi

if [ "$DRY_RUN" -eq 1 ]; then
	rsync "${rsync_args[@]}" --dry-run "$REPO_ROOT/" "$HOME/"
	printf '.f........ .ssh/authorized_keys (merge with existing keys)\n'
	exit 0
fi

backup_root="$HOME/.dotfiles-backups"
backup_dir="$backup_root/$(date '+%Y%m%d-%H%M%S')-$$"
mkdir -p "$backup_root" "$backup_dir"
chmod 700 "$backup_root" "$backup_dir"

rsync "${rsync_args[@]}" --backup --backup-dir="$backup_dir" "$REPO_ROOT/" "$HOME/"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
AUTHORIZED_KEYS_TMP=$(mktemp "$HOME/.ssh/.authorized_keys.XXXXXX")

if [ -f "$target_keys" ]; then
	awk 'NF && !seen[$0]++' "$target_keys" "$source_keys" > "$AUTHORIZED_KEYS_TMP"
else
	awk 'NF && !seen[$0]++' "$source_keys" > "$AUTHORIZED_KEYS_TMP"
fi
chmod 600 "$AUTHORIZED_KEYS_TMP"

if [ -f "$target_keys" ] && cmp -s "$target_keys" "$AUTHORIZED_KEYS_TMP"; then
	rm -f "$AUTHORIZED_KEYS_TMP"
	AUTHORIZED_KEYS_TMP=
else
	if [ -e "$target_keys" ] || [ -L "$target_keys" ]; then
		mkdir -p "$backup_dir/.ssh"
		cp -p "$target_keys" "$backup_dir/.ssh/authorized_keys"
	fi
	mv -f "$AUTHORIZED_KEYS_TMP" "$target_keys"
	AUTHORIZED_KEYS_TMP=
fi

chmod 600 "$target_keys"
