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
  buf_set_keymap('n', '[d', ':lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', ':lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>l', ':lua vim.lsp.diagnostic.set_loclist({open=true})<CR>', opts)
  buf_set_keymap('n', '<leader>f', ':lua vim.lsp.buf.format()<CR>', opts)

end

local defaultConfig = {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  }
}

local lua_config = {'lua_ls', {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
}}

local use_deno_instead_of_tsserver = false
local deno_config = {'denols', {
        on_attach = on_attach,
        --root_dir = nvim_lsp.util.root_pattern("deno.jsonc"),
        init_options = {
                lint = true
        },
        }
}
local tsserver_config = {'tsserver'}
local typescript_server;
if use_deno_instead_of_tsserver then
        typescript_server = deno_config
else
        typescript_server = tsserver_config
end

nvim_lsp['quick_lint_js'].setup {
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

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { lua_config, {'gopls'}, {'clangd'}, {'rust_analyzer'} }
for _, lsp in ipairs(servers) do
  local name, settings = unpack(lsp)
  if settings == nil then settings = defaultConfig end
  nvim_lsp[name].setup (coq.lsp_ensure_capabilities(settings) )
end

