" VIM Configuration - Geoffrey FROGEYE
"

set nocompatible
filetype off

""" PLUGINS MANAGEMENT  """
" Voir :h vundle

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'

Plugin 'L9'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'altercation/vim-colors-solarized'
Bundle 'Shougo/neosnippet'
Bundle 'Shougo/neosnippet-snippets'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'scrooloose/syntastic'
"Plugin 'terryma/vim-multiple-cursors'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
Plugin 'kien/ctrlp.vim'
Plugin 'mbbill/undotree'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-easytags'
Plugin 'majutsushi/tagbar'
"Plugin 'gilligan/vim-lldb'
Plugin 'wellle/targets.vim'
Plugin 'Chiel92/vim-autoformat'
Plugin 'Valloric/YouCompleteMe'

call vundle#end()            " required
filetype plugin indent on    " required

""" CTRLP """

let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v([\/]\.(git|hg|svn)|node_modules|bower_components|__pycache__|vendor)$',
    \ 'file': '\v\.(exe|so|dll)$',
    \ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
    \ }

""" SYNTASTIC """

set statusline+=%#warningmsg#
set statusline+=%{syntasticstatuslineflag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

""" VIM-MULTIPLE-CURSORS """

let g:multi_cursor_use_default_mapping=0
" Default mapping
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'

let g:multi_cursor_quit_key='<Esc>'
" Map start key separately from next key
let g:multi_cursor_start_key='<F6>'
let g:multi_cursor_start_key='<C-n>'
let g:multi_cursor_start_word_key='g<C-n>'

""" VIM-AIRLINE """

set noshowmode
set laststatus=2
let g:airline_powerline_fonts = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tabline#enabled = 1

let g:airline_section_a = airline#section#create(['mode'])
let g:airline_section_b = airline#section#create(['branch', 'hunks'])
let g:airline_section_z = airline#section#create(['%B', '@', '%l', ':', '%c'])

""" NERDTREE-GIT-PLUGIN """

let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }


""" VIM SETTINGS """

set encoding=utf-8
set title

set number
set ruler
set wrap

set scrolloff=5

set ignorecase
set smartcase

set incsearch

set hlsearch

set tabstop=4
set shiftwidth=4
set expandtab

set visualbell
set noerrorbells

set backspace=indent,eol,start

set hidden
set updatetime=250

syntax enable

set background=dark
set t_Co=256
colorscheme solarized

" From http://stackoverflow.com/a/5004785/2766106
set list
set listchars=tab:╾╌,trail:·,extends:↦,precedes:↤,nbsp:_
set showbreak=↪

filetype on
filetype plugin on
filetype indent on

" Put plugins and dictionaries in this dir (also on Windows)
let vimDir = '$HOME/.vim'
let &runtimepath.=','.vimDir

" Keep undo history across sessions by storing it in a file
if has('persistent_undo')
    let myUndoDir = expand(vimDir . '/undodir')
    " Create dirs
    call system('mkdir ' . vimDir)
    call system('mkdir ' . myUndoDir)
    let &undodir = myUndoDir
    set undofile
endif

map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>
map ;; <Esc>
imap ;; <Esc>
map <Enter> o<Esc>

