"" VANILLA start
set scrolloff=5
set clipboard=unnamed

set number
set relativenumber

set ignorecase
set smartcase
set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case

set smartindent
set expandtab
set tabstop=2
set shiftwidth=2

set exrc

nmap <leader>n :nohl<CR>

command! -nargs=* FindFile tabnew | execute "0read !fd <args> | sort" | set nomodified | 0
nmap <C-p> :FindFile<SPACE>

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid, when inside an event handler
" (happens when dropping a file on gvim), for a commit or rebase message
" (likely a different one than last time), and when using xxd(1) to filter
" and edit binary files (it transforms input files back and forth, causing
" them to have dual nature, so to speak)
autocmd BufReadPost *
\ let line = line("'\"")
\ | if line >= 1 && line <= line("$") && &filetype !~# 'commit'
\      && index(['xxd', 'gitrebase'], &filetype) == -1
\ |   execute "normal! g`\""
\ | endif

" Undo and backup
set backupdir=~/.local/state/nvim/backup//
set undofile

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
set shiftwidth=4
set splitright " splitting a window will put the new window right of the current one
"" Appearance end

"NetRW (should netrw config go in vanilla or plugin section?? 🤔)

let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 25
let g:netrw_altv = 1 " set automatically by `splitright`
let g:netrw_altfile=1 "make CTRL-^ return to last edited file instead of netrw browsing buffer

nmap <unique> <c-S-R> <Plug>NetrwRefresh

"" VANILLA end

"" quick-lint
autocmd FileType javascript,javascriptreact,typescript,typescriptreact lua vim.lsp.start({cmd={"quick-lint-js", "--lsp", "--snarky"}})


lua << LUAEND
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
 	vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
          vim.lsp.diagnostic.on_publish_diagnostics, {
            update_in_insert = true
          }
        )
        vim.keymap.set('n', 'K', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      end,
    })
LUAEND
