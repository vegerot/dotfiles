call plug#begin(stdpath('data') . '/plugged')
  " The legend
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-sleuth'
  Plug 'tpope/vim-vinegar'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-unimpaired'

  " Copy link to Git{Lab,Hub{,Enterprise}}
  Plug 'ruanyl/vim-gh-line'

  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'editorconfig/editorconfig-vim'

  Plug 'bkad/CamelCaseMotion'

  Plug 'kana/vim-textobj-user'
  Plug 'fvictorio/vim-textobj-backticks'

  Plug 'lervag/file-line'

  Plug 'christoomey/vim-tmux-navigator'

  "LSP and TreeSitter stuff"
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'neovim/nvim-lspconfig'

  Plug 'ms-jpq/coq_nvim', {'branch': 'coq'} "main
  Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'} " required extras
  Plug 'ms-jpq/coq.thirdparty', {'branch': '3p'} " - shell repl nvim lua api scientific calculator comment banner etc


call plug#end()


""" PLUGINS start

"" FZF start
" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'

command -bang -nargs=* Ag
  \  :Files
nmap <C-p> :Files<Cr>

"" FZF end

"" grep start
" use ripgrep instead of grep
set grepprg=rg\ --vimgrep\ --no-heading

command -nargs=+ Gr :grep <args>
"" grep end

let g:camelcasemotion_key = '<leader>'

nmap <leader>u :UndotreeShow<CR>


" TreeSitter
lua require('treesitterConfig')

"" Autocomplete
lua require('coqConfig')

" LSP
lua require('lspconfigConfig')
set omnifunc=v:lua.vim.lsp.omnifunc


""" PLUGINS end


"" VANILLA start
" Sync nvim clipboard with system pastboard
set clipboard=unnamed,unnamedplus

set mouse=a

set ignorecase
set smartcase

" line numbers
set nu
set relativenumber

" Undo and backup
set backupdir=~/.cache/backup//
set directory=~/.cache/swap//
set undodir=~/.cache/undo//
set undofile

" neovim jump to the last position when reopening a file
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
  \| exe "normal! g'\"" | endif

" Don't warn about existing swap files being open, since neovim will update a
" file when a write is detected
set shortmess+=A

" replace currently selected text with default register
" without yanking it
vnoremap p "_dP

" center search results
nnoremap n nzz
nnoremap N Nzz
nmap <leader>n :nohl<CR>

" emacs-like movement in insert mode
cmap <C-k> <C-p>
cmap <C-j> <C-n>
imap <C-k> <C-p>
imap <C-j> <C-n>

"" Appearance
" make popup menu not a gross pink color
highlight Pmenu ctermfg=111 ctermbg=239

" always have at least 3 lines on top-bottom
set scrolloff=15

" show special characters in bad spots
set showbreak=↪
set listchars=nbsp:␣,trail:•,extends:⟩,precedes:⟨

"" Appearance end

"NetRW (should netrw config go in vanilla or plugin section?? 🤔)

let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 25
let g:netrw_altv = 1

nmap <unique> <c-S-R> <Plug>NetrwRefresh

"" VANILLA end
