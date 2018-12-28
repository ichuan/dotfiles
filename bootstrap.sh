#!/usr/bin/env bash

cd `dirname $(readlink -e $0)`

function doIt() {
  test -f ~/.ssh/authorized_keys && mv ~/.ssh/authorized_keys{,.bak}
  rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" \
    --exclude "README.md" --exclude "LICENSE-MIT.txt" -av --no-perms . ~
  source ~/.bash_profile
  test -f ~/.ssh/authorized_keys.bak && mv ~/.ssh/authorized_keys{.bak,}
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
  doIt
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    doIt
  fi
fi
unset doIt

# perms
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
