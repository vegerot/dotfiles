"" VANILLA start
set clipboard=unnamed,unnamedplus

set number
set relativenumber

set ignorecase
set smartcase
set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case

command -nargs=* GrepNoTests grep --glob="!test/" --glob="!__tests__/" --glob "!e2e/" --glob="!*.test.*" --glob "!*.spec.*" <args>

set smartindent
set tabstop=2

set showmatch
set virtualedit=block

" when going to a quickfix item, switch to an existing window that already has
" the buffer in it and if not, open it in a vsplit
set switchbuf=usetab,uselast

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
set shiftround
set splitright " splitting a window will put the new window right of the current one

set spell
set spelllang=en,en_us,softwareterms,shell,vim,golang,html,lua,makefile,npm,python,sql,typescript,x86
set spelloptions+=camel,noplainbuffer


"" Appearance end

"NetRW (should netrw config go in vanilla or plugin section?? 🤔)

let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 25
let g:netrw_altv = 1 " set automatically by `splitright`
let g:netrw_altfile=1 "make CTRL-^ return to last edited file instead of netrw browsing buffer

nmap <c-S-R> <Plug>NetrwRefresh

colorscheme retrobox

" random colorscheme
" inspiration https://gist.github.com/ryanflorence/1381526
function RandomColorScheme()
  let mycolors = split(globpath(&rtp,"**/colors/*.vim"),"\n")
  let randomcolor = mycolors[localtime() % len(mycolors)]
  echo randomcolor
  exe 'so ' . randomcolor
  unlet mycolors randomcolor
endfunction

:command RandomColor call RandomColorScheme()

autocmd FileType typescript,javascript,typescriptreact,javascriptreact nmap gD :GrepNoTests --case-sensitive "(const\\|function) <cword>\b" <CR>

autocmd FileType man set nospell

autocmd FileType c let g:c_syntax_for_h=v:true
autocmd FileType cpp let g:c_syntax_for_h=v:false

autocmd FileType *sh set makeprg=shellcheck\ -f\ gcc\ -x\ %

"" VANILLA end


" Open remote
nmap <leader>op :OpenFile<CR>
vmap <leader>op :OpenFile<CR>
nmap <leader>cp :CopyFile<CR>
vmap <leader>cp :CopyFile<CR>


let g:camelcasemotion_key = '<leader>'

if exists('g:vscode')
	set scrolloff=0
	nnoremap <c-u> <c-u>zzjk
	nnoremap <c-d> <c-d>zzjk
	packadd open-remote
	packadd CamelCaseMotion
	packadd splitjoin.vim
	packadd commentary
	packadd unimpaired
	packadd vim-surround
	set nospell
	set noloadplugins
	finish
endif

" autocomplete with COQ
" note: MUST be before `require("coq")`!
lua <<LUAEND
vim.g.coq_settings = {
    ["clients.tabnine"] = {
        enabled = true,
        weight_adjust = -0.4
    },
    auto_start = "shut-up",
    -- conflicts with Tmux
    ["keymap.jump_to_mark"] = ""
}
local status, coq_3p = pcall(require, "coq_3p")
if not status then
    --print("didn't load coq_3p.  Skipping loading coq")
    return false
end

coq_3p {
    {src = "copilot", short_name = "✈", accept_key = "<c-f>"}
}
LUAEND

"" LSP start
lua << LUAEND
local status, lspconfig_plugin = pcall(require, "lspconfig")
if not status then
    --print("lspconfig" .. " plugin not loaded.  Not loading lsp stuff")
    return false
end

local status, coq = pcall(require, "coq")
if not status then
    --print("coq" .. " plugin not loaded.  Not loading coq")
    return false
end
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings.
    local opts = {noremap = true, silent = false}

    -- <cmd> `map-cmd`s are never echoed, making `silent` unneeded,
    -- but I personally like seeing what each mapping does, so I use `:` instead,
    -- besides for insert-mode mappings, since <cmd> can improve performance

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local methodsAndKeymaps = {
        ["textDocument/declaration"] = {{"n", "gD", ":lua vim.lsp.buf.declaration()<CR>"}},
        ["textDocument/definition"] = {{"n", "gd", ":lua vim.lsp.buf.definition()<CR>"}},
        ["textDocument/hover"] = {{"n", "K", ":lua vim.lsp.buf.hover()<CR>"}},
        ["textDocument/signatureHelp"] = {{"n", "<leader>k", ":lua vim.lsp.buf.signature_help()<CR>"}},
        ["textDocument/workspaceFolders"] = {
            {"n", "<leader>da", ":lua vim.lsp.buf.add_workspace_folder()<CR>"},
            {"n", "<leader>dr", ":lua vim.lsp.buf.remove_workspace_folder()<CR>"},
            {"n", "<leader>dl", ":lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>"}
        },
        ["textDocument/rename"] = {{"n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>"}},
        ["textDocument/codeAction"] = {
            {"n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>"},
            -- same as previous, but if there's only one possible action, just apply it
            {"n", "<leader>qf", ":lua vim.lsp.buf.code_action({apply=1})<CR>"}
        },
        ["textDocument/completion"] = {{"i", "<C-<Space>>", "<cmd>lua vim.lsp.buf.completion()<CR>"}},
        ["textDocument/references"] = {{"n", "gr", ":lua vim.lsp.buf.references()<CR>"}},
        ["textDocument/publishDiagnostics"] = {
            {"n", "<leader>e", ":lua vim.lsp.diagnostic.show_line_diagnostics()<CR>"},
			-- TODO: uncomment when vim.diagnostic.jump is widely available
            --{"n", "[d", ":lua vim.diagnostic.jump({count=-1, float=true})<CR>"},
            --{"n", "]d", ":lua vim.diagnostic.jump({count=1, float=true})<CR>"},
            {"n", "[d", ":lua vim.diagnostic.goto_prev({float=true})<CR>"},
            {"n", "]d", ":lua vim.diagnostic.goto_next({float=true})<CR>"},
            {"n", "<leader>q", ":lua vim.diagnostic.setqflist({open=true})<CR>"},
            {"n", "<leader>l", ":lua vim.diagnostic.setloclist({open=true})<CR>"}
        },
        ["textDocument/formatting"] = {{"n", "<leader>f", ":lua vim.lsp.buf.format()<CR>"}}
    }
	local telescope_installed, telescope_builtin = pcall(require, "telescope.builtin")
	if telescope_installed then
		methodsAndKeymaps["textDocument/definition"] = {
			{"n", "gd", ":lua require('telescope.builtin').lsp_definitions()<CR>"}
		}
		methodsAndKeymaps["textDocument/references"] = {
			{"n", "gr", ":lua require('telescope.builtin').lsp_references()<CR>"}
		}
	end
    for method, keymaps in pairs(methodsAndKeymaps) do
        if client.supports_method(method) then
            for _, keymap in ipairs(keymaps) do
                local mode, map, cmd = unpack(keymap)
                buf_set_keymap(mode, map, cmd, opts)
            end
        end
    end
    -- * thingies
    buf_set_keymap("n", "<leader>D", ":lua vim.lsp.buf.type_definition()<CR>", opts)
    buf_set_keymap("n", "gi", ":lua vim.lsp.buf.implementation()<CR>", opts)
	if client.supports_method("textDocument/inlayHint") then
		-- unstable API.  Might break soon
		vim.lsp.inlay_hint.enable(true)
	end
end

local quick_lint_js = {
    "quick_lint_js",
    {
        on_attach = on_attach,
        handlers = {
            ["textDocument/publishDiagnostics"] = vim.lsp.with(
                vim.lsp.diagnostic.on_publish_diagnostics,
                {
                    update_in_insert = true
                }
            )
        },
        filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact"
        },
        cmd = {"quick-lint-js", "--lsp-server", "--snarky"},
		flags = { debounce_text_changes = 9 }
        -- settings= {
        --   ["quick-lint-js"] = {
        --     ["tracing-directory"] = "/tmp/quick-lint-js-logs",
        --   }
        -- }
    }
}

local clangd_config = {
    "clangd",
    {
        on_attach = on_attach,
        flags = {
            debounce_text_changes = 150
        },
        cmd = {"clangd", "--offset-encoding=utf-16"}
    }
}
local configure_clangd_for_chromium = function()
    -- TODO: just check if "chrom" is _anywhere_ in the path
    local chromium_src = "/home/max/workspace/chromium.org/chromium/chromium/src"
    local chromium_src_len = string.len(chromium_src)
    local path = vim.fn.expand("%:p:h")
    local in_chromium = string.sub(path, 1, chromium_src_len) == chromium_src
    if in_chromium then
        clangd_config[2].cmd = {
            "clangd",
            "--offset-encoding=utf-16",
            "--project-root=" .. chromium_src,
            "--remote-index-address=linux.clangd-index.chromium.org:5900"
        }
    end
end
configure_clangd_for_chromium()

local godotnvim = function()
	-- go.nvim will handle calling lspconfig_plugin["gopls"].setup
	require("go").setup({
		lsp_cfg = {
			flags = {
				debounce_text_changes = 60
			},
			cmd = {"gopls"},
			settings = {
				gopls = {
					gofumpt = true,
				}
				}
			}

	})
	-- Run gofmt + goimports on save
	local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*.go",
		callback = function()
		require('go.format').goimports()
		end,
		group = format_sync_grp,
	})
end

if vim.fn.executable("gopls") then
	godotnvim()
end

local tsserver_config = {
	"tsserver",
	{
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 300
		},
		cmd = {"typescript-language-server", "--stdio"}
	}
	}

local rust_config = {
	"rust_analyzer",
	{
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 300
		},
		cmd = {"rust-analyzer"},
		settings = {
			["rust-analyzer"] = {
				linkedProjects = {
					"/Users/m0c0j7y/workspace/github.com/facebook/sapling.git/eden/scm/exec/hgmain/Cargo.toml"
				},
			}
		}
	}
	}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = {quick_lint_js, clangd_config, tsserver_config, rust_config}
for _, lsp in ipairs(servers) do
    local name, settings = unpack(lsp)
    if settings == nil then
        settings = defaultConfig
    end
    lspconfig_plugin[name].setup(coq.lsp_ensure_capabilities(settings))
end

LUAEND


" Copilot
let g:copilot_no_tab_map = v:true
let g:copilot_assume_mapped = v:true
let g:copilot_tab_fallback = ""
if filereadable("/opt/homebrew/bin/node")
  let g:copilot_node_command = "/opt/homebrew/bin/node"
endif
imap <script><expr> <C-e> copilot#AcceptLine("\<CR>")
imap <C-f> <Plug>(copilot-accept-word)

" copilot is disabled in markdown (and other languages) by default
" copilot appends g:copilot_filetypes to s:filetype_defaults (in copilot.vim)
" so we can override the defaults by putting them all to true
let g:copilot_filetypes = {
			\ '*': v:true,
			\ 'c': v:false,
			\ 'cpp': v:true,
			\}
" Copilot end


"" PLUGINS start

command! -nargs=* FindFile tabnew | execute "0read !fd <args> | sort" | set nomodified | 0

"" FZF start
" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'

command! -bang -nargs=* Ag
  \  :Files

silent! packadd fzf.vim
if exists(":Files")
       nmap <C-p> :Files<Cr>
else
       nmap <C-p> :FindFile<SPACE>
endif

"" FZF end

"" TELESCOPE start
packadd telescope.nvim
if exists(":Telescope")
	nmap <leader>fr <cmd>Telescope resume<Cr>
	nmap <leader>ff :lua require('telescope.builtin').find_files({hidden=true})<Cr>
	nmap <leader>fg <cmd>Telescope live_grep<Cr>
	nmap <leader>fb <cmd>Telescope buffers<Cr>
	nmap <leader>fo <cmd>Telescope oldfiles<Cr>
	nmap <leader>fh <cmd>Telescope help_tags<Cr>
	nmap <leader>fm <cmd>Telescope man_pages<Cr>
	nmap <leader>fd <cmd>Telescope diagnostics<Cr>
	nmap <leader>fq <cmd>Telescope quickfix<Cr>
endif

lua <<LUAEND
local status, telescope = pcall(require, "telescope")
if not status then
	return false
end
local status, fzy_native = pcall(require, "telescope._extensions.fzy_native")
if not status then
	return false
end
telescope.load_extension("fzy_native")
LUAEND
"" TELESCOPE end

" TREESITTER start
lua << LUAEND

local configs_plugin_name = "nvim-treesitter.configs"
local status, configs_plugin = pcall(require, configs_plugin_name)
if not status then
    print(configs_plugin_name .. " plugin not loaded.  Not loading treesitter")
    return false
end

local install_plugin_name = "nvim-treesitter.install"
local status, install_plugin = pcall(require, install_plugin_name)
if not status then
    print(install_plugin .. " plugin not loaded.  Not loading treesitter")
    return false
end

configs_plugin.setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = {
        enable = true, -- false will disable the whole extension
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm"
        }
    },
	textobjects = {enable = true},
    indent = {
        enable = true,
        disable = {"go"}
    }
}
install_plugin.prefer_git = true
vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end)
LUAEND

lua << LUAEND

local status, devicons_plugin = pcall(require, "nvim-web-devicons")
if status then
	devicons_plugin.setup {
		default=true
	}
end

LUAEND
