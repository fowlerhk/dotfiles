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

" Vundle plugin manager.
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'kien/ctrlp.vim'
" Plugin 'xolox/vim-misc'
" Plugin 'xolox/vim-easytags'
Plugin 'scrooloose/nerdtree.git'
Plugin 'bling/vim-airline'
Plugin 'majutsushi/tagbar'
Plugin 'airblade/vim-gitgutter'
Plugin 'wincent/command-t'
Plugin 'tpope/vim-fugitive'

" Color schemes
Plugin 'altercation/vim-colors-solarized'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" End Vundle setup

" Make VIMs update time shorter as recommended for vim-gitgutter
set updatetime=250

set tags=./tags,tags;

" CtrlP settings
" nnoremap <leader>. :CtrlPTag<cr>
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPTag'

" vim-airline settings"set laststatus=2
" Enable the list of buffers
"let g:airline#extensions#tabline#enabled = 1
" Show just the filename
"let g:airline#extensions#tabline#fnamemod = ':t'

" CommandT key mappings
"nmap <silent> <Leader>t <Plug>(CommandT)
"nmap <silent> <Leader>b <Plug>(CommandTBuffer)
"nmap <silent> <Leader>j <Plug>(CommandTJump)

" nerdtree settings
" automatically open NERDTree when vim starts if no files were specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Map CTRL-n to toggle NERDTree
map <F12> :NERDTreeToggle<CR>

" Tagbar
nmap <F11> :TagbarToggle<CR>

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Show line numbers
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
" :silent! colorscheme solarized
colorscheme solarized

" Zoom / Restore window.
function! s:ZoomToggle() abort
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <silent> <C-w>w :ZoomToggle<CR>


let coverity_vimrc = "/build/toolchain/lin64/cov-analysis-8.7.1/doc/examples/desktop-scripts/coverity.vimrc"
if filereadable(coverity_vimrc)
    execute "source" . fnameescape(coverity_vimrc)
endif
