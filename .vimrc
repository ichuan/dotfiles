" 不兼容
set nocompatible

" 显示行号
set number

" 不发出错误滴滴声
set noerrorbells

" 高亮显示匹配的括号
set showmatch

" 统一缩进为 2 个空格（可以在 editorconfig 更细控制）
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" 高亮搜索结果
set hlsearch

" 高亮第81列
set colorcolumn=81

" UTF8 编码
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

" 不自动备份
set nobackup

" 高亮
syntax enable

" 主题
set t_Co=256
let g:rehash256=1
color molokai
set background=dark

" 插件
let g:miniBufExplMapWindowNavVim=1
let g:miniBufExplMapWindowNavArrows=1
let g:miniBufExplMapCTabSwitchBufs=1
let g:miniBufExplModSelTarget=1

" no mouse
set mouse=

" paste mode toggle is F9
set pastetoggle=<f9>

" prepend python header
function HeaderPython()
	call setline(1, "#!/usr/bin/env python")
	call append(1, "# coding: utf-8")
	call append(2, "# yc@" . strftime('%Y/%m/%d', localtime()))
	normal G
	normal o
	normal o
endf
autocmd bufnewfile *.py call HeaderPython()

" 折叠
set foldmethod=marker

" 自动缩进
set autoindent

" 无拼写检查
set spl=en spell
set nospell

set wildmenu
set wildmode=list:longest,full
set backspace=2
set showcmd
filetype plugin indent on
