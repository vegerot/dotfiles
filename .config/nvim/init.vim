call plug#begin(stdpath('data') . '/plugged')
  " My plugins
  Plug 'vegerot/open-remote'

  " The legend
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-sleuth'
  Plug 'tpope/vim-vinegar'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-unimpaired'

  "" Simple plugins
  " Copy link to Git{Lab,Hub{,Enterprise}}
  Plug 'ruanyl/vim-gh-line'

  Plug 'bkad/CamelCaseMotion'

  Plug 'kana/vim-textobj-user'
  Plug 'fvictorio/vim-textobj-backticks'

  Plug 'lervag/file-line'

  "" Complex plugins
  Plug 'christoomey/vim-tmux-navigator'

  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'nvim-lua/plenary.nvim'
  Plug 'ThePrimeagen/harpoon'

  "Plug 'kamykn/spelunker.vim'

  "LSP and TreeSitter stuff"
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-treesitter/nvim-treesitter-context'
  Plug 'nvim-treesitter/playground'

  Plug 'neovim/nvim-lspconfig'

  Plug 'ms-jpq/coq_nvim', {'branch': 'coq'} "main
  Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'} " required extras
  Plug 'ms-jpq/coq.thirdparty', {'branch': '3p'} " - shell repl nvim lua api scientific calculator comment banner etc

  Plug 'ray-x/go.nvim'

  Plug 'github/copilot.vim'
call plug#end()


""" PLUGINS start

" Open remote
nmap <leader>op :OpenFile<CR>
vmap <leader>op :OpenFile<CR>
nmap <leader>cp :CopyFile<CR>
vmap <leader>cp :CopyFile<CR>

let g:spelunker_check_type = 2
"nmap <C-[> :lprevious<Cr>
nmap <C-]> :lnext<Cr>

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
"
""" Autocomplete
lua require('coqConfig')
"
"" LSP
lua require('lspconfigConfig')
set omnifunc=v:lua.vim.lsp.omnifunc

" go
"" go lsp
autocmd FileType go lua require('go').setup()
"" setup :make
autocmd FileType go set makeprg=go\ test\ ./...
autocmd BufWritePre *.go lua require('go.format').goimport()

" TypeScript
"" :make
autocmd FileType typescript set makeprg=yarn\ tsc\ --pretty\ false
autocmd FileType typescript set errorformat+=%f(%l\\,%c):\ %m

"sql
lua require('nvim-sql')

" Copilot
let g:copilot_no_tab_map = v:true
let g:copilot_assume_mapped = v:true
let g:copilot_tab_fallback = ""
let g:copilot_node_command = "~/.nvm/versions/node/v16.18.0/bin/node"
imap <script><expr> <C-e> copilot#Accept("\<CR>")
" copilot is disabled in markdown (and other languages) by default
" copilot appends g:copilot_filetypes to s:filetype_defaults (in copilot.vim)
" so we can override the defaults by putting them all to true
let g:copilot_filetypes = {
			\ '*': v:true,
			\ 'c': v:false,
			\ 'cpp': v:false,
			\}


if exists('g:vscode')
  runtime vscode.vim
endif
""" PLUGINS end


"" VANILLA start
" Sync nvim clipboard with system pastboard
set clipboard=unnamed,unnamedplus

" for "pair programming", don't @me
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


" Undo break points (cred: Prime)
" TODO: function that takes list of chars and does this remap for them
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u
inoremap <Space> <Space><c-g>u

" emacs-like movement in insert mode
cmap <C-k> <C-p>
cmap <C-j> <C-n>
imap <C-k> <C-p>
imap <C-j> <C-n>

" Make myself use `:x` instead of `:wq`
command -nargs=0 UseXInsteadOfWq echo "use :x"
cnoreabbrev wq UseXInsteadOfWq


"" Appearance
" make popup menu not a gross pink color
highlight Pmenu ctermfg=111 ctermbg=239

" always have at least 3 lines on top-bottom
set scrolloff=15

" show special characters in bad spots
set showbreak=↪
set list
set listchars=tab:→\ ,nbsp:␣,trail:•,extends:⟩,precedes:⟨

set tabstop=4

"" Appearance end

"NetRW (should netrw config go in vanilla or plugin section?? 🤔)

let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 25
let g:netrw_altv = 1

nmap <unique> <c-S-R> <Plug>NetrwRefresh

"" VANILLA end
