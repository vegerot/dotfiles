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

"" quick-lint start

lua << LUAEND
  local lspconfig_plugin = require('lspconfig')
  -- Use an on_attach function to only map the following keys
  -- after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=false }

    -- <cmd> `map-cmd`s are never echoed, making `silent` unneeded,
    -- but I personally like seeing what each mapping does, so I use `:` instead,
    -- besides for insert-mode mappings, since <cmd> can improve performance

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', ':lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', ':lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', ':lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', ':lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<leader>k', ':lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<leader>da', ':lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>dr', ':lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>dl', ':lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<leader>D', ':lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<leader>rn', ':lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<leader>ca', ':lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('i', '<C-<Space>>', '<cmd>lua vim.lsp.buf.completion()<CR>', opts)
    buf_set_keymap('n', 'gr', ':lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<leader>e', ':lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', ':lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', ':lua vim.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<leader>l', ':lua vim.lsp.diagnostic.set_loclist({open=true})<CR>', opts)
    buf_set_keymap('n', '<leader>f', ':lua vim.lsp.buf.format()<CR>', opts)

  end

  lspconfig_plugin['quick_lint_js'].setup {
    on_attach = on_attach,
    handlers = {
      ['textDocument/publishDiagnostics'] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          update_in_insert = true
        }
      )
    },
    filetypes = {
        "javascript", "javascriptreact",
        "typescript", "typescriptreact",
    },
    cmd = {"quick-lint-js", "--lsp-server", "--snarky"},
    -- settings= {
        --   ["quick-lint-js"] = {
            --     ["tracing-directory"] = "/tmp/quick-lint-js-logs",
            --   }
            -- }
  }
  return

LUAEND
"" quick-lint end

"" PLUGINS start

" Open remote
nmap <leader>op :OpenFile<CR>
vmap <leader>op :OpenFile<CR>
nmap <leader>cp :CopyFile<CR>
vmap <leader>cp :CopyFile<CR>


let g:camelcasemotion_key = '<leader>'

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

" TREESITTER start
lua << LUAEND

local configs_plugin_name='nvim-treesitter.configs'
local status, configs_plugin = pcall(require, configs_plugin_name)
if not status then
    print(configs_plugin_name .. " plugin not loaded.  Not loading treesitter")
    return false
end

local install_plugin_name = 'nvim-treesitter.install'
local status, install_plugin = pcall(require, install_plugin_name)
if not status then
    print(install_plugin .. " plugin not loaded.  Not loading treesitter")
    return false
end

configs_plugin.setup {
  ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
  indent = {
    enable = true,
    disable = { "go"},
  },

}
install_plugin.prefer_git = true
LUAEND

" autocomplete with COQ
lua <<LUAEND
vim.g.coq_settings = {
        ["clients.tabnine"] = {
                enabled = true,
                weight_adjust = -0.4,
        },
        auto_start = 'shut-up',
        -- conflicts with Tmux
        ["keymap.jump_to_mark"] = ''
}
local status, coq_3p = pcall(require, "coq_3p")
if not status then
    print("didn't load coq_3p.  Skipping loading coq")
    return false;
end

coq_3p {
        { src = "copilot", short_name = "✈", accept_key = "<c-f>" }
}
LUAEND

" Copilot
let g:copilot_no_tab_map = v:true
let g:copilot_assume_mapped = v:true
let g:copilot_tab_fallback = ""
imap <script><expr> <C-e> copilot#Accept("\<CR>")
" copilot is disabled in markdown (and other languages) by default
" copilot appends g:copilot_filetypes to s:filetype_defaults (in copilot.vim)
" so we can override the defaults by putting them all to true
let g:copilot_filetypes = {
			\ '*': v:true,
			\ 'c': v:false,
			\ 'cpp': v:false,
			\}
" Copilot end
