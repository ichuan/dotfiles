# dotfiles

Personal Bash, Vim, Git, tmux, and terminal configuration, originally based on
[mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles).

## Supported environments

- macOS on Intel or Apple silicon
- Linux
- Windows Subsystem for Linux (WSL)
- Bash 3.2 or newer

The shell configuration is portable across these environments. Alacritty works
wherever it is installed; the iTerm2 and Terminal.app profiles are macOS-only.

## Requirements

- Bash
- Git
- rsync

Vim, tmux, Alacritty, and the macOS terminal applications are optional; their
configuration remains available even when the corresponding program is absent.
Running the full local smoke test also requires Python 3.11 or newer for its
standard-library TOML parser.

## Install

Clone with submodules, preview the changes, then install:

```bash
git clone --recurse-submodules https://github.com/ichuan/dotfiles.git
cd dotfiles
./bootstrap.sh --dry-run
./bootstrap.sh --force
```

Omit `--force` to get an interactive confirmation prompt.

For an existing clone, initialize or refresh the Vim plugin submodules first:

```bash
git pull --recurse-submodules
git submodule update --init --recursive
./bootstrap.sh --dry-run
./bootstrap.sh --force
```

GitHub source archives are not supported because they do not include the Vim
submodule contents.

## Installer behavior

- `--dry-run` uses rsync's itemized preview and does not write to the home
  directory.
- A real install saves overwritten files under a timestamped directory in
  `~/.dotfiles-backups/`.
- The installer never deletes unrelated files from the home directory.
- The tracked SSH authorized keys are merged with the existing
  `~/.ssh/authorized_keys`; duplicate lines are removed and SSH permissions are
  corrected.
- For safety, `HOME` must resolve to a real non-root directory, and an existing
  `authorized_keys` must be a regular file rather than a symbolic link.
- Repository metadata, documentation, tests, and Terminal.app profile assets
  are not copied into the home directory.
- The iTerm2 Dynamic Profile is copied only on macOS.

## Local overrides

Git requires an explicit identity. Keep it in `~/.gitconfig.local`, which is
loaded by the tracked Git configuration:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

Use `~/.path` for machine-specific path changes and `~/.extra` for local or
secret settings and final shell overrides. Neither file belongs in this
repository:

```bash
touch ~/.path ~/.extra
chmod 600 ~/.path ~/.extra
```

## Terminal profiles

- Alacritty reads the installed `~/.config/alacritty/alacritty.toml`.
- iTerm2 discovers the installed Dynamic Profile from
  `~/Library/Application Support/iTerm2/DynamicProfiles/` on macOS. Select the
  profile in iTerm2 after installation if it is not already the default. For
  tmux OSC52 clipboard sync, enable “Applications in terminal may access
  clipboard” in iTerm2's General > Selection settings.
- Terminal.app profiles are intentionally not installed automatically. Open
  `Tomorrow_Night_Bright.terminal` from this repository to import it manually.
- tmux advertises `tmux-256color` inside sessions. On remote hosts, verify that
  `infocmp tmux-256color` succeeds before using this configuration; install the
  matching ncurses terminfo entry if it is missing.

## Verify

Run the local smoke test after changing the installer or configuration:

```bash
bash tests/smoke.sh
```

GitHub Actions also checks Bash syntax, ShellCheck, structured configuration
files, and the smoke installation on Ubuntu 24.04.
