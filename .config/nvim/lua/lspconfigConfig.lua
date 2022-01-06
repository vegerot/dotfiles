local nvim_lsp = require('lspconfig')
local coq = require('coq')

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
  buf_set_keymap('n', '[d', ':lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', ':lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>l', ':lua vim.lsp.diagnostic.set_loclist({open=true})<CR>', opts)
  buf_set_keymap('n', '<leader>f', ':lua vim.lsp.buf.formatting()<CR>', opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'tsserver' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup (coq.lsp_ensure_capabilities {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  })
end
