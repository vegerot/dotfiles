"" VANILLA start
set clipboard=unnamed,unnamedplus

set number
set relativenumber

set ignorecase
set smartcase
set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case
nmap <leader>n :nohl<CR>

command -nargs=* GrepNoTests grep --glob="!test/" --glob="!__tests__/" --glob "!e2e/" --glob="!*.test.*" --glob "!*.spec.*" <args>

set smartindent
set tabstop=2

set showmatch
set virtualedit=block

" when going to a quickfix item, switch to an existing window that already has
" the buffer in it and if not, open it in a vsplit
set switchbuf=usetab,uselast

set exrc

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid, when inside an event handler
" (happens when dropping a file on gvim), for a commit or rebase message
" (likely a different one than last time), and when using xxd(1) to filter
" and edit binary files (it transforms input files back and forth, causing
" them to have dual nature, so to speak)
augroup RestoreCursor
	autocmd!
	autocmd BufReadPre * autocmd FileType <buffer> ++once
				\ let s:line = line("'\"")
				\ | if s:line >= 1 && s:line <= line("$") && &filetype !~# 'commit'
				\      && index(['xxd', 'gitrebase'], &filetype) == -1
				\      && !&diff
				\ |   execute "normal! g`\""
				\ | endif
augroup END

" Undo and backup
set backupdir=~/.local/state/nvim/backup//
set undofile
set shada+='42069

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
set sidescroll=6
set sidescrolloff=3
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
command Edir :e %:h
command VEdir :Ve %:h
command Cd :cd %:h

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
  let mycolors = split(globpath(&rtp,"colors/*.vim"),"\n")
  let randomcolorpath = mycolors[localtime() % len(mycolors)]
  let randomcolor = fnamemodify(randomcolorpath, ":t:r")
  echo ':colorscheme ' . randomcolor
  exe 'colorscheme ' . randomcolor
  unlet mycolors randomcolor
endfunction

:command RandomColor call RandomColorScheme()

autocmd FileType typescript,javascript,typescriptreact,javascriptreact nmap gD :GrepNoTests --case-sensitive "(const\\|function) <cword>\b" <CR>

autocmd FileType man set nospell

autocmd FileType c let g:c_syntax_for_h=v:true
autocmd FileType cpp let g:c_syntax_for_h=v:false

autocmd FileType *sh set makeprg=shellcheck\ -f\ gcc\ -x\ %
autocmd BufNewFile,BufRead *.mdx   setfiletype markdown
autocmd BufNewFile,BufRead *.commit.sl.txt   setfiletype hgcommit

" don't continue comments on new lines
set formatoptions-=ro
" many plugins overwrite this, so overoverwrite it
autocmd BufWinEnter,BufNewFile,BufRead * setlocal formatoptions-=ro


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
	if &loadplugins
		silent! packadd open-remote
		silent! packadd CamelCaseMotion
		silent! packadd commentary
		silent! packadd unimpaired
		silent! packadd vim-surround
		packadd matchit
	endif
	set nospell
	set noloadplugins
	finish
endif

"" LSP+autocomplete start
set completefuzzycollect=keyword,files,whole_line
set completeopt+=fuzzy,menuone,noinsert


lua << LUAEND

-- new versions of nvim have built-in completions
-- only use coq on older versions of nvim
local shouldUseCoq = false

-- autocomplete with COQ
-- note: MUST be before `require("coq")`!
if shouldUseCoq then
	vim.g.coq_settings = {
		["clients.tabnine"] = {
			enabled = true,
			weight_adjust = -0.4,
		},
		auto_start = "shut-up",
		-- conflicts with Tmux
		["keymap.jump_to_mark"] = "",
	}
end

function handleGotoDefinition(options)
	local title = options.title
	local all_items = options.items
	local method = options.context.method
	local bufnr = options.context.bufnr

	if #all_items == 1 then
		local result = all_items[1]
		local result_bufnr = result.bufnr or vim.fn.bufadd(result.filename)

		local maybeW = vim.fn.win_findbuf(result_bufnr)[1]
		-- Save position in jumplist
		vim.cmd("normal! m'")
		-- Push a new item into tagstack
		local tagstack = { { tagname = tagname, from = from } }
		vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')
		if maybeW then
			local w = maybeW
			vim.api.nvim_win_set_buf(w, result_bufnr)
			vim.api.nvim_win_set_cursor(w, { result.lnum, result.col - 1 })
			-- This will also switch the tab
			vim.api.nvim_set_current_win(w)
		else
			vim.cmd('tabnew');
			vim.bo[result_bufnr].buflisted = true;
			local w = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(w, result_bufnr);
			vim.api.nvim_win_set_cursor(w, { result.lnum, result.col - 1 })
		end
	else
		vim.fn.setqflist({}, ' ', { title = title, items = all_items })
		vim.cmd('botright copen')
	end
end

-- initially copied from https://github.com/juniorsundar/nvim/blob/534554a50cc468df0901dc3861e7325a54c01457/lua/config/lsp/breadcrumbs.lua
-- now with my own patches
local configure_breadcrumbs = function(client)
	local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
	local folder_icon = "%#Conditional#" .. "󰉋" .. "%#Normal#"
	local file_icon = "󰈙"

	local kind_icons = {
	    "%#File#" .. "󰈙" .. "%#Normal#", -- file
	    "%#Module#" .. "󰠱" .. "%#Normal#", -- module
	    "%#Structure#" .. "" .. "%#Normal#", -- namespace
	    "%#Keyword#" .. "󰌋" .. "%#Normal#", -- key
	    "%#Class#" .. "" .. "%#Normal#", -- class
	    "%#Method#" .. "󰆧" .. "%#Normal#", -- method
	    "%#Property#" .. "" .. "%#Normal#", -- property
	    "%#Field#" .. "" .. "%#Normal#", -- field
	    "%#Function#" .. "" .. "%#Normal#", -- constructor
	    "%#Enum#" .. "" .. "%#Normal#", -- enum
	    "%#Type#" .. "" .. "%#Normal#", -- interface
	    "%#Function#" .. "󰊕" .. "%#Normal#", -- function
	    "%#None#" .. "󰂡" .. "%#Normal#", -- variable
	    "%#Constant#" .. "󰏿" .. "%#Normal#", -- constant
	    "%#String#" .. "" .. "%#Normal#", -- string
	    "%#Number#" .. "" .. "%#Normal#", -- number
	    "%#Boolean#" .. "" .. "%#Normal#", -- boolean
	    "%#Array#" .. "" .. "%#Normal#", -- array
	    "%#Class#" .. "" .. "%#Normal#", -- object
	    "", -- package
	    "󰟢", -- null
	    "", -- enum-member
	    "%#Struct#" .. "" .. "%#Normal#", -- struct
	    "", -- event
	    "", -- operator
	    "󰅲", -- type-parameter
	}

	local function range_contains_pos(range, line, char)
	    local start = range.start
	    local stop = range['end']

	    if line < start.line or line > stop.line then
	        return false
	    end

	    if line == start.line and char < start.character then
	        return false
	    end

	    if line == stop.line and char > stop.character then
	        return false
	    end

	    return true
	end

	local function find_symbol_path(symbol_list, line, char, path)
	    if not symbol_list or #symbol_list == 0 then
	        return false
	    end

	    for _, symbol in ipairs(symbol_list) do
	        if range_contains_pos(symbol.range, line, char) then
	            local icon = kind_icons[symbol.kind] or ""
	            table.insert(path, icon .. " " .. symbol.name)
	            find_symbol_path(symbol.children, line, char, path)
	            return true
	        end
	    end
	    return false
	end

	local function breadcrumbs_set(err, symbols, ctx, config)
	    if err or not symbols or not next(symbols) then
		if err then
		    vim.print("[lsp] breadcrumbs_set: " .. err)
		else
		    vim.print("[lsp] breadcrumbs_set: no symbols")
		end
	        vim.o.winbar = ""
	        return
	    end

	    local winnr = vim.api.nvim_get_current_win()
	    local pos = vim.api.nvim_win_get_cursor(0)
	    local cursor_line = pos[1] - 1
	    local cursor_char = pos[2]

	    local file_path = vim.fn.bufname(ctx.bufnr)
	    if not file_path or file_path == "" then
	        vim.o.winbar = "[No Name]"
	        return
	    end

	    local relative_path

	    if client.root_dir then
	        local root_dir = client.root_dir
	        if root_dir == nil then
	            relative_path = file_path
	        else
	            relative_path = vim.fs.relpath(root_dir, file_path)
	        end
	    else
	        local root_dir = vim.fn.getcwd(0)
	        relative_path = vim.fs.relpath(root_dir, file_path)
	    end

	    local breadcrumbs = {}

	    local path_components = vim.split(relative_path, "[/\\]", { trimempty = true })
	    local num_components = #path_components

	    for i, component in ipairs(path_components) do
	        if i == num_components then
	            local icon
	            local icon_hl

	            if devicons_ok then
	                icon, icon_hl = devicons.get_icon(component)
	            end
	            table.insert(breadcrumbs, "%#" .. icon_hl .. "#" .. (icon or file_icon) .. "%#Normal#" .. " " .. component)
	        else
	            table.insert(breadcrumbs, folder_icon .. " " .. component)
	        end
	    end
	    find_symbol_path(symbols, cursor_line, cursor_char, breadcrumbs)

	    local breadcrumb_string = table.concat(breadcrumbs, " > ")

	    if breadcrumb_string ~= "" then
	        vim.api.nvim_set_option_value('winbar', breadcrumb_string, { win = winnr })
	    else
	        vim.api.nvim_set_option_value('winbar', " ", { win = winnr })
	    end
	end

	local function breadcrumbs_trigger_set()
	    local bufnr = vim.api.nvim_get_current_buf()
	    local textDocumentParams = vim.lsp.util.make_text_document_params(bufnr)

	    local params = {
	        textDocument = textDocumentParams
	    }

	    local result = client:request("textDocument/documentSymbol", params, breadcrumbs_set)
	    --local otherClient = vim.lsp.get_active_clients()[1]
	    --print("client1: " .. vim.inspect(client) .. " client2: " .. vim.inspect(otherClient))
	    if not result then
		    print("Error: Could not get document symbols. Is the LSP server running?")
	        return
	    end
	end

	local breadcrumbs_augroup = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })

	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
	    group = breadcrumbs_augroup,
	    callback = breadcrumbs_trigger_set,
	    desc = "Set breadcrumbs.",
	})

	vim.api.nvim_create_autocmd({ "WinLeave" }, {
	    group = breadcrumbs_augroup,
	    callback = function()
	        vim.o.winbar = ""
	    end,
	    desc = "Clear breadcrumbs when leaving window.",
	})
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
	local opts = { noremap = true, silent = false }

	-- <cmd> `map-cmd`s are never echoed, making `silent` unneeded,
	-- but I personally like seeing what each mapping does, so I use `:` instead,
	-- besides for insert-mode mappings, since <cmd> can improve performance

	-- See `:help vim.lsp.*` for documentation on any of the below functions

	-- TODO: try using the new built-in keymaps instead
	local methodsAndKeymaps = {
		["textDocument/declaration"] = { { "n", "gD", ":lua vim.lsp.buf.declaration()<CR>" } },
		["textDocument/definition"] = { { "n", "gd", ":lua vim.lsp.buf.definition({on_list = handleGotoDefinition})<CR>" } },
		["textDocument/hover"] = { { "n", "K", ":lua vim.lsp.buf.hover()<CR>" } },
		["textDocument/signatureHelp"] = { { "n", "<leader>k", ":lua vim.lsp.buf.signature_help()<CR>" } },
		["textDocument/workspaceFolders"] = {
			{ "n", "<leader>da", ":lua vim.lsp.buf.add_workspace_folder()<CR>" },
			{ "n", "<leader>dr", ":lua vim.lsp.buf.remove_workspace_folder()<CR>" },
			{ "n", "<leader>dl", ":lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>" },
		},
		["textDocument/rename"] = { { "n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>" } },
		["textDocument/codeAction"] = {
			{ "n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>" },
			-- same as previous, but if there's only one possible action, just apply it
			{ "n", "<leader>qf", ":lua vim.lsp.buf.code_action({apply=1})<CR>" },
		},
		["textDocument/completion"] = { { "i", "<c-space>", "<cmd>lua vim.lsp.buf.completion()<CR>" } },
		["textDocument/references"] = { { "n", "gr", ":lua vim.lsp.buf.references()<CR>" } },
		["textDocument/publishDiagnostics"] = {
			{ "n", "<leader>d", ":lua vim.lsp.diagnostic.show_line_diagnostics()<CR>" },
			{ "n", "[d", ":lua vim.diagnostic.jump({count=-1, float=true})<CR>"},
			{ "n", "]d", ":lua vim.diagnostic.jump({count=1, float=true})<CR>"},
			-- uncomment this if using vim <0.11 (0.11+ has `vim.diagnostic.jump`)
			--{ "n", "[d", ":lua vim.diagnostic.goto_prev({float=true})<CR>" },
			--{ "n", "]d", ":lua vim.diagnostic.goto_next({float=true})<CR>" },
			{ "n", "<leader>q", ":lua vim.diagnostic.setqflist({open=true})<CR>" },
			{ "n", "<leader>l", ":lua vim.diagnostic.setloclist({open=true})<CR>" },
		},
		["textDocument/formatting"] = { { "n", "<leader>f", ":lua vim.lsp.buf.format()<CR>" } },
	}
	local telescope_installed, telescope_builtin = pcall(require, "telescope.builtin")
	if telescope_installed then
		methodsAndKeymaps["textDocument/definition"] = {
			{ "n", "gd", ":lua require('telescope.builtin').lsp_definitions()<CR>" },
		}
		methodsAndKeymaps["textDocument/references"] = {
			{ "n", "gr", ":lua require('telescope.builtin').lsp_references()<CR>" },
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
	if client.supports_method("textDocument/completion") then
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
	end
	if client.supports_method("textDocument/documentSymbol") then
		configure_breadcrumbs(client)
	end
	vim.diagnostic.config({
		virtual_lines = {current_line = true}
	})
end

local godotnvim = function()
	local status, go = pcall(require, "go")
	if not status then
		return false
	end
	if vim.fn.executable("gopls") == 0 then
		-- Only print this message if we're in a go file
		-- we cannot check the filetype with `vim.bo.filetype` because the
		-- filetype is not detected until after the plugins are loaded
		if vim.fn.expand("%:e") == "go" or vim.bo.filetype=="go" then
			print("go.nvim installed but gopls not found.  Not loading go.nvim")
		end
		return false
	end
	-- go.nvim will handle calling lspconfig_plugin["gopls"].setup
	go.setup({
		lsp_on_attach = function(client, bufnr)
			on_attach(client, bufnr)
			-- Run gofmt + goimports on save
			local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		lsp_inlay_hints = {
			enable = false,
		},
		lsp_cfg = {
			flags = {
				debounce_text_changes = 60,
			},
			cmd = { "gopls" },
			settings = {
				gopls = {
					analyses = {
						ST1003 = false,
					},
					gofumpt = true,
				},
			},
		},
	})
end
if vim.fn.expand("%:e") == "go" or vim.bo.filetype=="go" then
	-- FIXME: If the first file you open isn't a go file, go.nvim will never load
	godotnvim()
end

local quick_lint_js = {
	"quick_lint_js",
	{
		on_attach = on_attach,
		handlers = {
			["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
				update_in_insert = true,
			}),
		},
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
		},
		cmd = { "quick-lint-js", "--lsp-server" },
		flags = { debounce_text_changes = 9 },
		-- settings= {
		--   ["quick-lint-js"] = {
		--     ["tracing-directory"] = "/tmp/quick-lint-js-logs",
		--   }
		-- }
	},
}

local tsserver_config = {
	"ts_ls",
	{
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 300,
		},
		cmd = { "typescript-language-server", "--stdio" },
	},
}

local jsonls_config = {
	"jsonls",
}

local pythonruff_config = {
	"ruff",
}
local pythonty_config = {
	"ty",
}

local clangd_config = {
	"clangd",
	{
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 150,
		},
		cmd = { "clangd", "--offset-encoding=utf-16" },
	},
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
			"--remote-index-address=linux.clangd-index.chromium.org:5900",
		}
	end
end
configure_clangd_for_chromium()


local rust_config = {
	"rust_analyzer",
	{
		on_attach = on_attach,
		flags = {
			debounce_text_changes = 300,
		},
		cmd = { "rust-analyzer" },
	},
}
local configure_rust_for_sapling = function()
	local path = vim.fn.expand("%:p:h")
	local in_sapling = string.find(path, "sapling") ~= nil
	if in_sapling then
		rust_config[2].settings = {
			["rust-analyzer"] = {
				server = {
					extraEnv = {
						["PYTHON_SYS_EXECUTABLE"] = "/usr/bin/python3.11",
					}
				},
				linkedProjects = {
					"/home/max/workspace/github.com/facebook/sapling/eden/scm/exec/hgmain/Cargo.toml",
				},
			},
		}
	end
end
configure_rust_for_sapling()

local configure_zig = function()
	-- don't show parse errors in a separate window
	vim.g.zig_fmt_parse_errors = 0
	-- disable format-on-save from `ziglang/zig.vim`
	vim.g.zig_fmt_autosave = 0
	-- enable  format-on-save from nvim-lspconfig + ZLS
	--
	-- Formatting with ZLS matches `zig fmt`.
	-- The Zig FAQ answers some questions about `zig fmt`:
	-- https://github.com/ziglang/zig/wiki/FAQ
	vim.api.nvim_create_autocmd('BufWritePre',{
		pattern = {"*.zig", "*.zon"},
		callback = function(ev)
			vim.lsp.buf.format()
		end
	})
	return {
		"zls",
		{
			on_attach = on_attach,
			settings = {
				zls = {
					enable_build_on_save = true,
				}
			}
		}
	}

end

local zig_config = configure_zig()

local is_coq_running, coq = pcall(require, "coq")
local defaultConfig = {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  }
}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { quick_lint_js, tsserver_config, jsonls_config, pythonruff_config, pythonty_config, clangd_config, rust_config, zig_config }
for _, lsp in ipairs(servers) do
	local name, settings = unpack(lsp)
	if settings == nil then
		settings = defaultConfig
	end
	if (is_coq_running and shouldUseCoq) then
		settings = coq.lsp_ensure_capabilities(settings)
	end
	vim.lsp.config(name, settings)
	vim.lsp.enable(name)
end

LUAEND

" MarsCode start

if &loadplugins
	silent! packadd codeverse.vim
endif
if exists(":Marscode")
	let g:marscode_filetypes = {
				\ '*': v:true,
				\ '*.c': v:false,
				\}
	imap <C-e> <Plug>(marscode-accept-word)
endif
" MarsCode end

"" PLUGINS start

" Copilot
if !exists(":Marscode")
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
else
	let g:copilot_filetypes = {
				\ '*': v:false,
				\}
endif
" Copilot end


command! -nargs=* FindFile tabnew | execute "0read !fd --follow <args> | sort" | set nomodified | 0

"" FZF start
" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'

command! -bang -nargs=* Ag
  \  :Files

if &loadplugins
	silent! packadd fzf.vim
endif
if exists(":Files")
       nmap <C-p> :Files<Cr>
else
       nmap <C-p> :FindFile<SPACE>
endif

"" FZF end

"" TELESCOPE start
if &loadplugins
	silent! packadd telescope.nvim
endif
if exists(":Telescope")
	nmap <leader>tr <cmd>Telescope resume<Cr>
	nmap <leader>tf :lua require('telescope.builtin').find_files({hidden=true})<Cr>
	nmap <leader>tg <cmd>Telescope live_grep<Cr>
	nmap <leader>tb <cmd>Telescope buffers<Cr>
	nmap <leader>to <cmd>Telescope oldfiles<Cr>
	nmap <leader>th <cmd>Telescope help_tags<Cr>
	nmap <leader>tm <cmd>Telescope man_pages<Cr>
	nmap <leader>td <cmd>Telescope diagnostics<Cr>
	nmap <leader>tq <cmd>Telescope quickfix<Cr>
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

configs_plugin.setup({
	ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
	highlight = {
		enable = true, -- false will disable the whole extension
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
	textobjects = { enable = true },
	indent = {
		enable = true,
		disable = { "go" },
	},
})
install_plugin.prefer_git = true
local install_plugin_name = "treesitter-context"
local status, treesitterContext = pcall(require, install_plugin_name)
if not status then
	print(treesitterContext .. " plugin not loaded.  Not loading treesitter-context")
	return false
end
treesitterContext.setup{}
vim.keymap.set("n", "[c", function() treesitterContext.go_to_context(vim.v.count1) end)
LUAEND

lua << LUAEND

-- better builtin pager

local status, extui = pcall(require, "vim._extui")
if status then
	extui.enable({})
end

local status, devicons_plugin = pcall(require, "nvim-web-devicons")
if status then
	devicons_plugin.setup({
		default = true,
	})
end

LUAEND

