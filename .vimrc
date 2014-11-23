"显示行号
set number
"不发出错误滴滴声
set noerrorbells
"高亮显示匹配的括号
set showmatch

"统一缩进为2个空格
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

"高亮搜索结果
set hlsearch
"高亮第81列
set cc=81
"编码
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
"不自动备份
set nobackup
"高亮
filetype on
filetype plugin on
syntax enable
set grepprg=grep\ -nH\ $*
"主题
set t_Co=256
let g:rehash256 = 1
color molokai
set background=dark
"插件
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1
"Taglist
let Tlist_Use_Right_Window=0
let Tlist_File_Fold_Auto_Close=1
"插入日期
:map <F5> :r !date "+\%Y-\%m-\%e \%T"<CR><Esc>kJo
"python
:map <F6> <Esc>i# -*- coding: utf-8 -*-<Esc>o
"fu*k mouse
set mouse=
"paste mode toggle is F9
set pt=<f9>

"
function HeaderPython()
	call setline(1, "#!/usr/bin/env python")
	call append(1, "# coding: utf-8")
	call append(2, "# yc@" . strftime('%Y/%m/%d', localtime()))
	normal G
	normal o
	normal o
endf

" 新py文件自动追加头部
autocmd bufnewfile *.py call HeaderPython()

" 不兼容
set nocompatible

"
set showcmd

"折叠
set foldmethod=marker

"自动缩进
set autoindent

"无拼写检查
if version >= 700
   set spl=en spell
   set nospell
endif

"
set wildmenu
set wildmode=list:longest,full

"
set backspace=2
