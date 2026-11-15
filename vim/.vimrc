" Small, plugin-free Vim configuration.
set nocompatible
set encoding=utf-8
filetype plugin indent on
syntax enable

" Editing and display.
set number norelativenumber
set cursorline
set showcmd ruler laststatus=2
set hidden
set backspace=indent,eol,start
set mouse=a
set scrolloff=5 sidescrolloff=5
set splitbelow splitright
set display=truncate
set nrformats-=octal

" Filetype plugins can override these defaults (for example, Makefile tabs).
set autoindent
set expandtab tabstop=4 shiftwidth=4 softtabstop=4

" Search and command-line completion.
set incsearch hlsearch ignorecase smartcase
set wildmenu wildmode=longest:full,full
set timeout timeoutlen=500 ttimeout ttimeoutlen=100

" Keep recovery data outside both the working tree and the Stow package.
let s:state_home = empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME
let s:state_dir = s:state_home . '/vim'
for s:subdir in ['undo', 'swap', 'backup']
  call mkdir(s:state_dir . '/' . s:subdir, 'p', 0700)
endfor
let &directory = escape(s:state_dir . '/swap//', ',')
let &backupdir = escape(s:state_dir . '/backup//', ',')
if has('persistent_undo')
  let &undodir = escape(s:state_dir . '/undo', ',')
  set undofile
endif
set swapfile writebackup

" Space is the leader key; ordinary Vim keys remain available.
let mapleader = ' '
nnoremap <leader>w :update<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
xnoremap < <gv
xnoremap > >gv

" Restore the last position, except in transient Git commit/rebase buffers.
augroup dotfiles_vim
  autocmd!
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line('$')
        \ && &filetype !~# 'commit\|gitrebase' && !&diff |
        \ execute "normal! g`\"" |
        \ endif
augroup END

" Machine-specific preferences stay outside version control.
if filereadable(expand('~/.vimrc.local'))
  execute 'source ' . fnameescape(expand('~/.vimrc.local'))
endif
