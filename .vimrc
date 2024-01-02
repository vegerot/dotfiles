call plug#begin('~/.vim/plugged')
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
   
  Plug 'benmills/vimux' 

    Plug 'tpope/vim-sensible'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-vinegar'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-obsession'

  "Plug 'Raimondi/delimitMate'

  "Plug 'joshdick/onedark.vim'
  Plug 'morhetz/gruvbox'

  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  
  Plug 'edkolev/tmuxline.vim'
  Plug 'tmux-plugins/vim-tmux'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'tmux-plugins/vim-tmux-focus-events'
   
  Plug 'janko/vim-test' 
  
  " Vim HardTime
  "Plug 'phux/vim-hardtime'
      autocmd! User vim-hardtime.vim HT()
  
  Plug '/usr/local/opt/fzf' 
  Plug 'junegunn/fzf.vim'

    Plug 'airblade/vim-gitgutter'
    
    "Plug 'ycm-core/YouCompleteMe' 
        autocmd! User youcompleteme.vim YCM()
    Plug 'neoclide/coc.nvim',  {'tag': '*', 'branch': 'release'}
        autocmd! User coc.nvim CocStart()

  Plug 'airblade/vim-gitgutter'
   
  Plug 'luochen1990/rainbow' 

  "Plug 'ycm-core/YouCompleteMe'
      autocmd! User youcompleteme.vim YCM()
  Plug 'neoclide/coc.nvim',  {'tag': '*', 'branch': 'release'}
      autocmd! User coc.nvim CocStart()
  Plug 'liuchengxu/vista.vim'

  Plug 'derekwyatt/vim-scala', {'for': ['scala','sbt', 'java']}
  Plug 'mpollmeier/vim-scalaConceal', {'for': ['scala','sbt', 'java']}


  Plug 'keith/swift.vim'
  Plug 'darfink/vim-plist'

  Plug 'arnoudbuzing/wolfram-vim'

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


  Plug 'nvie/vim-flake8'
  Plug 'Vimjas/vim-python-pep8-indent'
  "Plug 'jupyter-vim/jupyter-vim', {'for': ['python'] }
  Plug 'vim-python/python-syntax'
  Plug 'ehamberg/vim-cute-python'

  Plug 'google/vim-maktaba'
  Plug 'google/vim-codefmt'
  Plug 'google/vim-glaive'

" All of your Plugs must be added before the following line
call plug#end()
call glaive#Install()
Glaive codefmt plugin[mappings]

"NeoVim api stuff
let g:python_host_prog="/usr/local/bin/python3"
let g:python3_host_prog="/usr/local/bin/python3"

"Netrw stuff
let g:netrw_liststyle=3
let g:netrw_banner = 0
let g:netrw_altv = 1
let g:netrw_winsize = 25
set rtp+=/usr/local/opt/fzf


"Search stuff
set incsearch
set hlsearch
nnoremap n nzz
nnoremap N Nzz
vnoremap p pgvy 

"Tab stuff
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set colorcolumn=80
set textwidth=80 

let g:camelcasemotion_key = '<leader>'

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
nnoremap o o   <BS><Esc>:let @6=@*<CR><DEL>:let @*=@6<CR>
nnoremap O O   <BS><Esc>:let @6=@*<CR><DEL>:let @*=@6<CR>


nnoremap gF :wincmd f <CR>

nmap <c-k> :execute &keywordprg expand("<cword>")<cr>
  
 " these "Ctrl mappings" work well when Caps Lock is mapped to Ctrl
nmap <silent> t<C-n> :TestNearest<CR>
nmap <silent> t<C-f> :TestFile<CR>
nmap <silent> t<C-s> :TestSuite<CR>
nmap <silent> t<C-l> :TestLast<CR>
nmap <silent> t<C-g> :TestVisit<CR>
let test#strategy = "vimux" 
 

set scrolloff=15
set showbreak=↪
set listchars=tab:→\ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨
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


set updatetime=100
"Color config
"let g:gruvbox_contrast_dark = 'hard'
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
"let g:onedark_hide_endofbuffer=1
"let g:onedark_terminal_italics=1
"let g:onedark_termcolors=256
syntax on
let g:gruvbox_italic=1
"let g:gruvbox_contrast_dark="soft"
let g:gruvbox_italicize_strings=1
"let g:gruvbox_improved_strings=1
colorscheme gruvbox
highlight NonText guifg=gray
"highlight Normal ctermfg=145 ctermbg=235 guifg=#ABB2BF guibg=#282838
"highlight Normal ctermfg=7 ctermbg=0  guibg=7 guifg=0
"guibg=black guifg=white
"

"WINDOW CONFIG
set laststatus=2
set showcmd
set wildmenu
set wildmode=list:longest

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

function! Lineair()
    call airline#add_statusline_func('WindowNumber')
    call airline#add_inactive_statusline_func('WindowNumber')
    let g:airline_powerline_fonts = 1
    let g:airline_theme='powerlineish'
    silent! call airline#extensions#whitespace#disable()
    "let g:tmuxline_preset = {'z'    : '#track'}
    let g:airline#extensions#tmuxline#enabled = 1
    return 0
endfunction
call Lineair()
"Window end

"YouCompleteMe
function YCM()
        "let g:ycm_always_populate_location_list = 1
        let g:airline#extensions#ycm#enabled = 1
        let g:ycm_clangd_binary_path = '/usr/local/opt/llvm/bin/clangd'
        let g:ycm_clangd_args = ['-log=verbose', '-pretty']
        let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
        nmap <c-]> :YcmCompleter GoTo<CR>
endfunction
"coc
function CocStart()
        so ~/.cocrc.vim
endfunction
if has_key(plugs, 'YouCompleteMe')
        call YCM()
endif
if has_key(plugs, "coc.nvim")
        call CocStart()
endif

"Open to last position when reopening file
 if has("autocmd")
   au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

"make things difficult
autocmd VimEnter,BufNewFile,BufReadPost * silent! call HardMode()
let g:HardMode_level = 'wannabe'
let g:HardMode_hardmodeMsg = 'Don''t use this!'
"Formatter stuff
augroup autoformat_settings
  autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
  ""autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
  "autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType python AutoFormatBuffer autopep8
augroup END

set autoread
au FocusGained,BufEnter,CursorHold * if !bufexists("[Command Line]") && mode()!= 'c' | checktime | endif
autocmd FocusLost Filetype html,css,sass,scss,less,json,javascript,typescript,vue :wa
autocmd Filetype html,css,sass,scss,less,json,javascript,typescript,vue set autowrite
autocmd Filetype html,css,sass,scss,less,json,javascript,typescript,vue set autowriteall
set autowrite
set autowriteall

"#call jspretmpl#register_tag('javascript', 'javascriptreact')
"#autocmd FileType javascript,js JsPreTmpl
"#autocmd FileType javascript.jsx JsPreTmpl
let g:vim_jsx_pretty_template_tags=['html', 'jsx', 'js', 'javascript']
let g:vim_jsx_pretty_colorful_config = 1 " default 0
let g:javascript_plugin_flow = 1
let g:jsx_ext_required = 0
 
let g:rainbow_active = 1

autocmd FileType text set spell
autocmd FileType json syntax match Comment +\/\/.\+$+


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
au BufRead,BufNewFile README,INSTALL,CREDITS set filetype=markdown
au BufRead,BufRead * if &syntax == '' | set syntax=sh | endif
au BufRead,BufNewFile *.json set syntax=jsonc 

"Formatting end

"Nerdy things
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-n> :NERDTreeToggle<CR>


source ~/.vimFunctions.vim
"let g:gruvbox_contrast_dark = 'hard'
"colorscheme gruvbox
colorscheme onedark
let g:onedark_hide_endofbuffer=1
let g:onedark_terminal_italics=1
let g:onedark_termcolors=16
"set background=dark
set background=dark
highlight Normal ctermfg=7 ctermbg=0 guibg=black guifg=white
set background=dark

set title
set clipboard=unnamed,unnamedplus
set timeoutlen=1000 ttimeoutlen=1
if exists('neovim_dot_app')
  :source ~/.gvimrc
endif 
