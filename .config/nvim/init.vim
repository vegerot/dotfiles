call plug#begin(stdpath('data') . '/plugged')
   Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
   Plug 'junegunn/fzf.vim'

   Plug 'editorconfig/editorconfig-vim'

   Plug 'bkad/CamelCaseMotion'

   Plug 'christoomey/vim-tmux-navigator'
call plug#end()


""" PLUGINS start

"" FZF start
" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'

command! -bang -nargs=* Ag
  \  :Files
nmap <C-p> :Files<Cr>
"" FZF end

let g:camelcasemotion_key = '<leader>'

""" PLUGINS end


"" VANILLA start
" Sync nvim clipboard with system pastboard
set clipboard=unnamed,unnamedplus

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
"" VANILLA end
