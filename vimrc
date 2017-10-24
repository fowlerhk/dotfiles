set nocompatible              " be iMproved, required
filetype off                  " required

" Indentation without hard tabs
" For indentation without tabs, the principle is to set 'expandtab', and set
" 'shiftwidth' and 'softtabstop' to the same value, while leaving 'tabstop' at
" its default value:
set expandtab
set tabstop=3
set shiftwidth=3
set softtabstop=3

" Indentation purely with hard tabs
" For indentation purely with hard tabs, the principle is to set 'tabstop' and
" 'shiftwidth' to the same value, and to leave 'expandtab' at its default
" value ('noexpandtab'), and leave 'softtabstop' unset:
"set shiftwidth=3
"set tabstop=3
"set noexpandtab

" Indentation with mixed tabs and spaces
" For indentation with mixed tabs and spaces, the principle is to set
" 'shiftwidth' and 'softtabstop' to the same value, leave 'expandtab' at its
" default ('noexpandtab'). Usually, 'tabstop' is left at its default value:
"set tabstop=3
"set shiftwidth=3
"set softtabstop=3

" Provide a button to toggle paste mode, with visual feedback
nnoremap <F9> :set invpaste paste?<CR>
set pastetoggle=<F9>
set showmode

" This will show dots to indicate your indentation level as you type. The dots 
" magically disappear as you leave the line.
set list listchars=tab:»-,trail:·,extends:»,precedes:«

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
Plugin 'kien/ctrlp.vim'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-easytags'
Plugin 'scrooloose/nerdtree.git'
Plugin 'altercation/vim-colors-solarized'
Plugin 'bling/vim-airline'
Plugin 'vim-scripts/taglist.vim'
Plugin 'majutsushi/tagbar'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" vim-airline settings
"set laststatus=2
" Enable the list of buffers
"let g:airline#extensions#tabline#enabled = 1
" Show just the filename
"let g:airline#extensions#tabline#fnamemod = ':t'

" vim-easytags options
let g:easytags_on_cursorhold = 0

" nerdtree settings
" automatically open NERDTree when vim starts
"autocmd vimenter * NERDTree
" automatically open NERDTree when vim starts if no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Close vim if the only window left open is a NERDTree
"autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" Map CTRL-n to toggle NERDTree
map <F12> :NERDTreeToggle<CR>
" Tagbar
nmap <F11> :TagbarToggle<CR>

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Line numbers
set number

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Solarized colour scheme
set t_Co=256
syntax enable
set background=dark
:silent! colorscheme solarized

" taglist
let Tlist_Ctags_Cmd = "/usr/bin/ctags"
let Tlist_WinWidth = 50
map <F4> :TlistToggle<cr>
map <F8> :!/usr/bin/ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

