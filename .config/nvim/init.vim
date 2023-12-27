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

set undofile

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
