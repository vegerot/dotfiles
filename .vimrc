if exists('firstTime')+1 | call plug#begin('~/.vim/plugged')
  "The legend"
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-sleuth'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-vinegar'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-obsession'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-abolish'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-unimpaired'

  Plug 'shumphrey/fugitive-gitlab.vim' 
  Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

  Plug 'mbbill/undotree' 

  Plug 'benmills/vimux'

  Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

  Plug 'bkad/CamelCaseMotion'
  "Plug 'easymotion/vim-easymotion'

  Plug 'kana/vim-textobj-user'
  Plug 'fvictorio/vim-textobj-backticks'

  "Plug 'Raimondi/delimitMate'

  Plug 'joshdick/onedark.vim'
  Plug 'morhetz/gruvbox'

  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  autocmd! User airline.vim call Lineair() 

  Plug 'edkolev/tmuxline.vim'
  Plug 'tmux-plugins/vim-tmux'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'tmux-plugins/vim-tmux-focus-events'

  Plug 'vim-test/vim-test'

  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/vim-emoji'

  Plug 'preservim/nerdtree'
  "Plug 'ryanoasis/vim-devicons'
  "Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
  Plug 'Xuyuanp/nerdtree-git-plugin'

  "Plug 'airblade/vim-gitgutter'

  "Plug 'luochen1990/rainbow'

  " Vim HardTime
  "Plug 'phux/vim-hardtime'
      autocmd! User vim-hardtime.vim HT()

  "Plug 'ycm-core/YouCompleteMe'
  autocmd! User youcompleteme.vim YCM()
  Plug 'neoclide/coc.nvim',  {'tag': '*', 'branch': 'release'}
  autocmd! User coc.nvim CocStart()
  Plug 'liuchengxu/vista.vim'

  Plug 'derekwyatt/vim-scala', {'for': ['scala','sbt', 'java']}
  Plug 'mpollmeier/vim-scalaConceal', {'for': ['scala','sbt', 'java']}


  "Plug 'keith/swift.vim'
  "Plug 'darfink/vim-plist'

  "Plug 'arnoudbuzing/wolfram-vim'

  "Plug 'justinmk/vim-syntax-extra'
  Plug 'sheerun/vim-polyglot'

  Plug 'hotoo/jsgf.vim'
  "Plug 'Quramy/vim-js-pretty-template'
  "Plug 'leafoftree/vim-vue-plugin'
  Plug 'posva/vim-vue'
  Plug 'neoclide/jsonc.vim'
  "Plug 'maxmellon/vim-jsx-pretty'
  Plug 'HerringtonDarkholme/yats.vim'
  "Plug 'jonsmithers/vim-html-template-literals'
  "Plug 'pangloss/vim-javascript'


  "Plug 'nvie/vim-flake8'
  "Plug 'Vimjas/vim-python-pep8-indent'
  "Plug 'jupyter-vim/jupyter-vim', {'for': ['python'] }
  "Plug 'vim-python/python-syntax'
  "Plug 'ehamberg/vim-cute-python', {'for': ['python']}

  Plug 'google/vim-maktaba'
  Plug 'google/vim-codefmt'
  Plug 'google/vim-glaive'

  " All of your Plugs must be added before the following line
  call plug#end()
  call glaive#Install()
  Glaive codefmt plugin[mappings]
  let firstTime = -1
endif

set background=dark
"NeoVim api stuff
let g:python_host_prog="/usr/local/bin/python3"
let g:python3_host_prog="/usr/local/bin/python3"

"Netrw stuff
let g:netrw_liststyle=3
let g:netrw_banner = 0
let g:netrw_altv = 1
let g:netrw_winsize = 25
set mouse=a
" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'


"Search stuff
set incsearch
set hlsearch
set ignorecase 
set smartcase 
nnoremap n nzz
nnoremap N Nzz
vnoremap p pgvy

set backupdir=~/.cache/backup// 
set directory=~/.cache/swap// 
set undodir=~/.cache/undo// 

"Tab stuff
set tabstop=2
set shiftwidth=2
set expandtab
set smartindent
set colorcolumn=100
"set textwidth=80

let g:camelcasemotion_key='<leader>'

"Number stuff
set nu
set relativenumber

"""Autoclosing stuff
""inoremap " ""<left>
""inoremap ' ''<left>
""inoremap ( ()<left>
""inoremap [ []<left>
""inoremap { {}<left>
""inoremap {<CR> {<CR>}<ESC>O

""inoremap <expr> ) strpart(getline('.'), col('.')-1, 1) == ")" ? "\<Right>" : ")"noremap {;<CR> {<CR>};<ESC>O
"nnoremap o o<SPACE><SPACE><SPACE><BS><Esc>:let @6=@*<CR><DEL>:let @*=@6<CR>
"nnoremap O O<SPACE><SPACE><SPACE><BS><Esc>:let @6=@*<CR><DEL>:let @*=@6<CR>


nnoremap gF :wincmd f <CR>

nmap <c-s-K> :execute &keywordprg expand("<cword>")<cr>

" these "Ctrl mappings" work well when Caps Lock is mapped to Ctrl
nmap t<C-n> :TestNearest<CR>
nmap t<C-f> :TestFile<CR>
nmap t<C-s> :TestSuite<CR>
nmap t<C-l> :TestLast<CR>
nmap t<C-g> :TestVisit<CR>
let test#strategy = "vimux"

cmap <C-k> <C-p>
cmap <C-j> <C-n>
imap <C-k> <C-p>
imap <C-j> <C-n>

nmap <leader>u :UndotreeShow<CR>
set undofile

nmap <SPACE> elf<SPACE>

set scrolloff=15
set showbreak=↪
"set listchars=tab:→\ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨
set listchars=nbsp:␣,trail:•,extends:⟩,precedes:⟨
set list 
set cpoptions-=_

set foldmethod=indent
set foldlevelstart=18
"Cursor Mode stuff

let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[4 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)

"Cursor settings:

"  1 -> blinking block
"  2 -> solid block
"  3 -> blinking underscore
"  4 -> solid underscore
"  5 -> blinking vertical bar
"  6 -> solid vertical bar

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %


set updatetime=1000
"Color config
"let g:gruvbox_contrast_dark = 'hard'
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
"let g:onedark_hide_endofbuffer=1
let g:onedark_terminal_italics=1
"let g:onedark_termcolors=256
let g:gruvbox_italic=1
let g:gruvbox_contrast_dark="soft"
let g:gruvbox_italicize_strings=1
let g:gruvbox_improved_strings=1
colorscheme gruvbox
highlight NonText guifg=grey
highlight Comment gui=italic guifg=grey
"highlight Normal ctermfg=7 ctermbg=0 guibg=black guifg=white

"WINDOW CONFIG
set laststatus=2
set showcmd
set wildmenu
"set wildmode=list:longest

"   Fast window movement
let i = 1
while i <= 9
  execute 'nnoremap <Leader>' . i . ' :' . i . 'wincmd w<CR>'
  let i = i + 1
endwhile

"   Airline window numbers
function! WindowNumber(...)
  let builder = a:1
  let context = a:2
  call builder.add_section('airline_b', '%{tabpagewinnr(tabpagenr())}')
  return 0
endfunction

let g:vista_default_executive="coc"
nmap <C-s> :Vista!!<CR>
nmap <leader>l :Vista finder<CR>
let g:vista_fzf_preview = ['right:50%'] 
let g:vista#renderer#enable_icon = 1 
function! NearestMethodOrFunction(...)
  let builder = a:1
  let context = a:2
  call builder.add_section('airline_b', '%{get(b:, "vista_nearest_method_or_function", "")}')
  return 0 
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
function! Lineair()
  call airline#add_statusline_func('WindowNumber')
  call airline#add_inactive_statusline_func('WindowNumber')
  call airline#add_statusline_func('NearestMethodOrFunction') 
  call airline#add_inactive_statusline_func('NearestMethodOrFunction') 
  let g:airline#extensions#branch#format = 2
  let g:airline_powerline_fonts = 1
  let g:airline_theme= get(g:, 'airline_theme', "random")
  silent! call airline#extensions#whitespace#disable()
  "let g:tmuxline_preset = {'z'    : '#track'}
  let g:airline#extensions#tmuxline#enabled = 1
  let g:airline#extensions#tabline#enabled = 1
  let g:airline_stl_path_style = 'short'
  let g:airline_extensions = []
  return 0
endfunction
"Window end

"YouCompleteMe
function! YCM()
  "let g:ycm_always_populate_location_list = 1
  let g:airline#extensions#ycm#enabled = 1
  let g:ycm_clangd_binary_path = '/usr/local/opt/llvm/bin/clangd'
  let g:ycm_clangd_args = ['-log=verbose', '-pretty']
  let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
  nmap <c-]> :YcmCompleter GoTo<CR>
endfunction
"coc
function! CocStart()
  so ~/.cocrc.vim
endfunction
if has_key(plugs, 'YouCompleteMe')
  call YCM()
endif
if has_key(plugs, "coc.nvim")
  call CocStart()
endif

"Open to last position when reopening file
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal! g'\"" | endif

function! HT()
  "make things difficult
  let g:hardtime_default_on = 1
  let g:list_of_disabled_keys = ["<UP>", "<DOWN>", "<LEFT>", "<RIGHT>"]
  let g:list_of_normal_keys = ["h", "l", "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>"]

  let g:hardtime_showmsg = 1
  let g:hardtime_allow_different_key = 1
  let g:hardtime_maxcount = 2
  let g:hardtime_ignore_buffer_patterns = [  "NERD.*" ]
  let g:list_of_resetting_keys  = ['2', '3', '4', '5', '6', '7', '8', '9', '0']
endfunction

if has_key(plugs, "vim-hardtime")
  call HT()
endif

"Formatter stuff
augroup autoformat_settings
  autocmd FileType c,cpp,proto AutoFormatBuffer clang-format
  "autocmd FileType css,sass,scss,less,json,javascript AutoFormatBuffer js-beautify
  "autocmd FileType html AutoFormatBuffer prettier
  autocmd FileType java AutoFormatBuffer google-java-format
  "autocmd FileType python AutoFormatBuffer autopep8
augroup END

set autoread
au FocusGained,BufEnter,CursorHold * if !bufexists("[Command Line]") && mode()!= 'c' | checktime | endif
autocmd FocusLost Filetype html,css,sass,scss,less,json,javascript,typescript,vue :wa
autocmd Filetype html,css,sass,scss,less,json,javascript,typescript,vue set autowrite
autocmd Filetype html,css,sass,scss,less,json,javascript,typescript,vue set autowriteall
set autowrite
set autowriteall
 
au BufEnter git*.c*_*.txt set filetype=markdown

"#call jspretmpl#register_tag('javascript', 'javascriptreact')
"#autocmd FileType javascript,js JsPreTmpl
"#autocmd FileType javascript.jsx JsPreTmpl
"let g:vim_jsx_pretty_template_tags=['html', 'jsx', 'js', 'javascript']
let g:vim_jsx_pretty_template_tags=['jsx','tsx', 'javascriptreact', 'typescriptreact']
let g:vim_jsx_pretty_colorful_config = 1 " default 0
let g:javascript_plugin_flow = 1
let g:jsx_ext_required = 0
"let g:gitgutter_sign_added = emoji#for('small_blue_diamond')
"let g:gitgutter_sign_modified = emoji#for('small_orange_diamond')
"let g:gitgutter_sign_removed = emoji#for('small_red_triangle')
"let g:gitgutter_sign_modified_removed = emoji#for('collision')
set completefunc=emoji#complete

let g:rainbow_active = 1

autocmd FileType text set spell
autocmd FileType json syntax match Comment +\/\/.\++


"   PEP 8 indentation standards
au BufNewFile,BufRead *.py
      \ set softtabstop=4 |
      \ set textwidth=79 |
      \ set autoindent |
      \ set fileformat=unix

"   Pylint
let python_highlight_all=1
let g:python_highlight_all = 1
"syntax on
au BufRead,BufNewFile *rc.json set filetype=jsonc
au BufRead,BufNewFile bash-fc-* set filetype=sh
au BufRead,BufNewFile zsh* set filetype=zsh
au BufRead,BufNewFile *.heapprofile set filetype=json
au BufRead,BufNewFile README,INSTALL,CREDITS set filetype=markdown
au BufRead,BufRead * if &syntax == '' | set syntax=sh | endif
au BufRead,BufNewFile *.json set syntax=jsonc 

"Formatting end

"Nerdy things
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
au FocusGained,BufEnter * if !bufexists("[Command Line]") && mode()!= 'c' | checktime | endif
let g:NERDTreeWinSize=38
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeHighlightCursorline = 0
function! MyNerdToggle()
  if &filetype == 'nerdtree'
    :NERDTreeToggle
  else
    :NERDTreeFind
  endif
endfunction
map <C-n> :call MyNerdToggle()<CR>

"Fugitive 
let g:fugitive_gitlab_domains = ['https://git.aoc-pathfinder.cloud'] 
nmap <leader>gs :Git<CR>
nmap gh :diffget //2 \| diffupdate<CR>
nmap gl :diffget //3 \| diffupdate<CR>
"note: you can do `dp` on one of the sides to pick that side 

let g:firenvim_config = { 
    \ 'globalSettings': {
        \ 'alt': 'all',
    \  },
    \ 'localSettings': {
        \ '.*': {
            \ 'cmdline': 'neovim',
            \ 'priority': 0,
            \ 'selector': 'textarea',
            \ 'takeover': 'never',
        \ },
    \ }
\ }
let firenvim_config['.*'] = { 'takeover': 'never' }

source ~/.vimFunctions.vim
set mouse=a 

let g:airline_stl_path_style = 'short'
let g:airline_extensions = []


set title
set clipboard=unnamed,unnamedplus
set timeoutlen=1000 ttimeoutlen=1
if exists('neovim_dot_app')
  :source ~/.gvimrc
endif 
