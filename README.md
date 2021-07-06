## Intro

This is yc's dotfiles(keywords: bash, vim), originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)


## Install

Using git clone:

```bash
git clone --depth 1 --shallow-submodules --recursive https://github.com/ichuan/dotfiles.git
bash dotfiles/bootstrap.sh -f
```

Using release file:

```bash
wget https://github.com/ichuan/dotfiles/releases/latest/download/dotfiles.tar.gz -O - | tar xzf -
bash dotfiles/bootstrap.sh -f
```

## Making release
```bash
# using https://github.com/Kentzo/git-archive-all
python /path/to/git_archive_all.py --prefix=dotfiles dotfiles.tar.gz
```
