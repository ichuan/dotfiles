## Intro

This is yc's dotfiles(keywords: bash, vim), originally forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)


## Install

```shell
# full install
git clone --recursive https://github.com/ichuan/dotfiles.git
bash dotfiles/bootstrap.sh

# minimal install
git clone -b minimal --single-branch --recursive https://github.com/ichuan/dotfiles.git
bash dotfiles/bootstrap.sh -f
```


## Extra

Install the linters for vim [scrooloose/syntastic](https://github.com/scrooloose/syntastic) plugin:

```shell
sudo pip install flake8
sudo npm install -g eslint csslint jsonlint coffeelint
```
