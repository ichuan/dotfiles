" 不兼容
set nocompatible

" 插件
execute pathogen#infect()

" 显示行号
set number

set ignorecase

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

" 高亮第88列
set colorcolumn=88

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
set background=dark
let g:rehash256=1
color Tomorrow-Night-Bright
highlight Normal ctermbg=NONE
highlight nonText ctermbg=NONE

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
set foldnestmax=2
autocmd BufRead,BufNewFile *.py set foldmethod=indent foldlevel=99
" press space to fold/unfold code
nnoremap <space> za
vnoremap <space> zf

" ini highlight for conf file
autocmd BufRead,BufNewFile *.conf setf dosini

" 自动缩进
set autoindent

" 无拼写检查
set spl=en spell
set nospell

" Cursor shapes
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[0 q"

set wildmenu
set wildmode=list:longest,full
set backspace=2
set showcmd
filetype plugin indent on

if exists('+termguicolors')
  let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

let g:netrw_dirhistmax = 0

" display buftabline only if there are at least two buffers
let g:buftabline_show = 1
" show buffer number
let g:buftabline_numbers = 1
" show modified state
let g:buftabline_indicators = 1

" ALE
let g:ale_set_highlights = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_open_list = 1
let g:ale_list_window_size = 5
let js_fixers = ['prettier', 'eslint']
let g:ale_linters= {
\   'python': ['ruff'],
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines'],
\   'python': ['ruff_format'],
\   'javascript': js_fixers,
\   'javascriptreact': js_fixers,
\   'typescript': js_fixers,
\   'typescriptreact': js_fixers,
\   'css': ['prettier'],
\   'json': ['prettier'],
\   'solidity': ['prettier'],
\}
let g:ale_javascript_prettier_options = '--single-quote'
let g:ale_fix_on_save = 1
