"" VANILLA start
set clipboard=unnamed,unnamedplus

set number
set relativenumber

set ignorecase
set smartcase
set grepprg=rg\ --vimgrep\ --hidden\ --smart-case

command -nargs=* GrepNoTests grep --glob="!test/" --glob="!__tests__/" --glob "!e2e/" --glob="!*.test.*" --glob "!*.spec.*" <args>

set smartindent

set showmatch
set virtualedit=block

" when going to a quickfix item, switch to an existing window that already has
" the buffer in it and if not, open it in a vsplit
set switchbuf=usetab,uselast
set jumpoptions+=view
set wildoptions+=fuzzy
set smoothscroll
set winborder=rounded
set pumborder=rounded

" In newer Nvim, 'exrc' also searches parent directories. Keep this enabled,
" but rely on :trust to allow project-local config deliberately.
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
set undofile
set shada+='42069

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

set nofoldenable

set termguicolors
colorscheme retrobox

" random colorscheme
" inspiration https://gist.github.com/ryanflorence/1381526
function RandomColorScheme()
  let mycolors = globpath(&rtp, "colors/*.{vim,lua}", v:false, v:true)
  let randomcolorpath = mycolors[localtime() % len(mycolors)]
  echo randomcolorpath
  let randomcolor = fnamemodify(randomcolorpath, ":t:r")
  echo ':colorscheme ' . randomcolor
  exe 'colorscheme ' . randomcolor
  unlet mycolors randomcolor
endfunction

:command RandomColor call RandomColorScheme()

"" Appearance end
command Edir :e %:h
command VEdir :Ve %:h
command Cd :cd %:h

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

"" PLUGINS start
lua << LUAEND
local function GitHub(repo)
	return "https://github.com/" .. repo .. ".git"
end

local postinstall_hooks = {
	["telescope-fzy-native.nvim"] = function(path)
		vim.system({ "make" }, { cwd = path }):wait()
	end,
}

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
			return
		end

		local hook = postinstall_hooks[ev.data.spec.name]
		if hook then
			hook(ev.data.path)
		end
	end,
})

if vim.g.vscode then
	vim.pack.add({
		GitHub("vegerot/open-remote"),
		GitHub("bkad/CamelCaseMotion"),
		GitHub("tpope/vim-unimpaired"),
		GitHub("tpope/vim-surround"),
		GitHub("justinmk/vim-sneak"),
	}, {load=true})
elseif vim.o.loadplugins then
	vim.pack.add({
		-- simple plugins
		GitHub("vegerot/open-remote"),
		GitHub("bkad/CamelCaseMotion"),
		GitHub("wsdjeg/vim-fetch"),
		GitHub("justinmk/vim-sneak"),
		GitHub("nanotee/zoxide.vim"),
		GitHub("nvim-lua/plenary.nvim"),

		-- tpope's plugins
		GitHub("tpope/vim-repeat"),
		GitHub("tpope/vim-sleuth"),
		GitHub("tpope/vim-unimpaired"),
		GitHub("tpope/vim-surround"),

		-- folke's plugins
		GitHub("folke/snacks.nvim"),
		GitHub("folke/sidekick.nvim"),

		-- treesitter
		GitHub("nvim-treesitter/nvim-treesitter"),
		GitHub("nvim-treesitter/nvim-treesitter-context"),
		GitHub("nvim-treesitter/nvim-treesitter-textobjects"),
		GitHub("davidmh/mdx.nvim"),

		-- fzf
		GitHub("junegunn/fzf"),
		GitHub("junegunn/fzf.vim"),

		-- telescope
		GitHub("nvim-telescope/telescope.nvim"),
		GitHub("nvim-telescope/telescope-fzy-native.nvim"),

		-- LSP+autocomplete
		GitHub("zbirenbaum/copilot.lua"),
		GitHub("neovim/nvim-lspconfig"),
		GitHub("ray-x/go.nvim"),
		GitHub("ray-x/guihua.lua"),
		{ src = "https://codeberg.org/ziglang/zig.vim.git" },

		-- complicated plugins
		GitHub("christoomey/vim-tmux-navigator"),
		GitHub("nvim-tree/nvim-web-devicons"),
		GitHub("m4xshen/hardtime.nvim"),
		GitHub("lewis6991/gitsigns.nvim"),
		GitHub("stevearc/oil.nvim"),
		GitHub("catgoose/nvim-colorizer.lua"),
	}, {load=true})
end
LUAEND

if exists('g:vscode')
	set scrolloff=0
	nnoremap <c-u> <c-u>zzjk
	nnoremap <c-d> <c-d>zzjk
	set nospell
	set noloadplugins
	finish
endif

if &loadplugins
    "sneak
    map s <Plug>Sneak_s
    map S <Plug>Sneak_S

    " Open remote
    nmap <leader>op :OpenFile<CR>
    vmap <leader>op :OpenFile<CR>
    nmap <leader>cp :CopyFile<CR>
    vmap <leader>cp :CopyFile<CR>

    let g:camelcasemotion_key = '<leader>'
endif

"" LSP+autocomplete start
set completeopt+=fuzzy,menuone,noinsert,popup,nearest

lua << REQUIRE_WRAPPER_END
-- Require wrapper that returns nil when --noplugin or module not found
function RequireChecked(name)
  if not vim.o.loadplugins then
    return nil
  end
  local ok, mod = pcall(require, name)
  if not ok then
    return nil
  end
  return mod
end
REQUIRE_WRAPPER_END

lua << LUAEND

local LspMethods = vim.lsp.protocol.Methods

function handleGotoDefinition(options)
	local title = options.title
	local all_items = options.items
	local method = options.context.method
	local bufnr = options.context.bufnr
	local shouldReuseWin = true

	if #all_items == 1 then
		local item = all_items[1]
		local item_bufnr = item.bufnr or vim.fn.bufadd(item.filename)

		-- Save position in jumplist
		vim.cmd("normal! m'")
		-- Push a new item into tagstack
		local from = vim.fn.getpos('.')
		from[1] = bufnr
		local tagname = vim.fn.expand('<cword>')
		local tagstack = { { tagname = tagname, from = from } }
		local currentWindow = vim.api.nvim_get_current_win()
		vim.fn.settagstack(vim.fn.win_getid(currentWindow), { items = tagstack }, 't')

		vim.bo[item_bufnr].buflisted = true
		local resultWindow = currentWindow
		if shouldReuseWin then
			local maybeAlreadyOpenedWindow = vim.fn.win_findbuf(item_bufnr)[1]
			if maybeAlreadyOpenedWindow then
				resultWindow = maybeAlreadyOpenedWindow
			else
				vim.cmd('tabnew');
				resultWindow = vim.api.nvim_get_current_win()
				vim.bo[item_bufnr].buflisted = true;
			end
			if resultWindow ~= currentWindow then
				vim.api.nvim_set_current_win(resultWindow)
			end
		end
		vim.api.nvim_win_set_buf(resultWindow, item_bufnr)
		vim.api.nvim_win_set_cursor(resultWindow, { item.lnum, item.col - 1 })
		-- Open folds under the cursor
		vim.api.nvim_win_call(resultWindow, function() vim.cmd('normal! zv') end)
	else
		vim.fn.setqflist({}, ' ', { title = title, items = all_items })
		vim.cmd('botright copen')
	end

end

function tagBackInAppropriateTab(direction)
    local currentWindow = vim.fn.win_getid()

    local tagstack = vim.fn.gettagstack(currentWindow)
    local items = tagstack.items
    local current_position = tagstack.curidx

     --vim.print("Tagstack: " .. vim.inspect(tagstack))
    if current_position > #items + 1 then
	print("No more items in tagstack")
	return
    end

    local next_position = current_position + direction
    local target = items[next_position]
    --vim.print("next_position: " .. next_position .. " target: " .. vim.inspect(target))
    if target then
	local maybeAlreadyOpenedWindow = vim.fn.win_findbuf(target.from[1])[1]
	local resultWindow = maybeAlreadyOpenedWindow or currentWindow
	--vim.print("maybeAlreadyOpenedWindow: " .. vim.inspect(maybeAlreadyOpenedWindow) .. " resultWindow: " .. vim.inspect(resultWindow))
	vim.api.nvim_set_current_win(resultWindow)
	vim.fn.settagstack(resultWindow, { items = items, curidx = next_position}, 't')
	vim.api.nvim_win_set_buf(resultWindow, target.from[1])
	vim.fn.cursor(target.from[2], target.from[3])
	if direction == 1 then
	    vim.cmd('stag') -- update the tagstack curidx
	else
	    vim.cmd('pop') -- update the tagstack curidx
	end
    end
end

-- initially copied from https://github.com/juniorsundar/nvim/blob/534554a50cc468df0901dc3861e7325a54c01457/lua/config/lsp/breadcrumbs.lua
-- now with my own patches
local configure_breadcrumbs = function(client)

	local devicons = RequireChecked("nvim-web-devicons")
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

	    if not relative_path then
	        relative_path = file_path
	    end

	    local breadcrumbs = {}

	    local path_components = vim.split(relative_path, "[/\\]", { trimempty = true })
	    local num_components = #path_components

	    for i, component in ipairs(path_components) do
	        if i == num_components then
	            local icon
	            local icon_hl

	            if devicons ~= nil then
	                icon, icon_hl = devicons.get_icon(component)
	            end
	            table.insert(breadcrumbs, "%#" .. (icon_hl or "Normal") .. "#" .. (icon or file_icon) .. "%#Normal#" .. " " .. component)
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
	    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = LspMethods.textDocument_documentSymbol })
	    if #clients == 0 then
		return
	    end
	    local textDocumentParams = vim.lsp.util.make_text_document_params(bufnr)

	    local params = {
	        textDocument = textDocumentParams
	    }

	    --local result = client:request("textDocument/documentSymbol", params, breadcrumbs_set)
	    --local otherClient = vim.lsp.get_active_clients()[1]
	    --print("client1: " .. vim.inspect(client) .. " client2: " .. vim.inspect(otherClient))

	    -- I don't know why I can't use `client:request` here, but if I do
	    -- it doesn't work with multiple tabs
	    local result = vim.lsp.buf_request(bufnr, LspMethods.textDocument_documentSymbol, params, breadcrumbs_set)
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

_G.SidekickStatusline = function()
  local status = RequireChecked("sidekick.status")
  if status == nil then
    return ""
  end

  local parts = {}

  local st = status.get()
  if st then
    if st.kind == "Error" then
      table.insert(parts, "%#DiagnosticError# err%#StatusLine#")
    elseif st.busy then
      table.insert(parts, "%#DiagnosticWarn# …%#StatusLine#")
    else
      -- "ok" color: reuse DiagnosticInfo unless you define something else
      table.insert(parts, " ok%#StatusLine#")
    end
  end

  local cli = status.cli()
  if type(cli) == "table" and #cli > 0 then
    table.insert(parts, "%#Special# " .. tostring(#cli) .. "%#StatusLine#")
  end

  return (#parts > 0) and (table.concat(parts, " ") .. " ") or ""
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	local map = function(mode, lhs, rhs, desc, extra)
		local opts = vim.tbl_extend("force", { buffer = bufnr, silent = false, desc = desc }, extra or {})
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	-- <cmd> `map-cmd`s are never echoed, making `silent` unneeded,
	-- but I personally like seeing what each mapping does, so I use `:` instead,
	-- besides for insert-mode mappings, since <cmd> can improve performance

	-- See `:help vim.lsp.*` for documentation on any of the below functions

	local methodsAndKeymaps = {
		[LspMethods.textDocument_declaration] = {
			{
				mode = "n",
				lhs = "gD",
				rhs = function() vim.lsp.buf.declaration() end,
				desc = "vim.lsp.buf.declaration()",
			},
		},
		[LspMethods.textDocument_definition] = {
			{
				mode = "n",
				lhs = "gd",
				rhs = function() vim.lsp.buf.definition({ on_list = handleGotoDefinition }) end,
				desc = "vim.lsp.buf.definition({ on_list = handleGotoDefinition })",
			},
			{
				mode = "n",
				lhs = "<C-t>",
				rhs = function() tagBackInAppropriateTab(-1) end,
				desc = "tagBackInAppropriateTab(-1)",
			},
			{
				mode = "n",
				lhs = "<C-i>",
				rhs = function() vim.cmd('stag') end,
				desc = ":stag",
			},
		},
		[LspMethods.textDocument_signatureHelp] = {
			{
				mode = "n",
				lhs = "<leader>k",
				rhs = function() vim.lsp.buf.signature_help() end,
				desc = "vim.lsp.buf.signature_help()",
			},
		},
		["textDocument/workspaceFolders"] = {
			{
				mode = "n",
				lhs = "<leader>da",
				rhs = function() vim.lsp.buf.add_workspace_folder() end,
				desc = "vim.lsp.buf.add_workspace_folder()",
			},
			{
				mode = "n",
				lhs = "<leader>dr",
				rhs = function() vim.lsp.buf.remove_workspace_folder() end,
				desc = "vim.lsp.buf.remove_workspace_folder()",
			},
			{
				mode = "n",
				lhs = "<leader>dl",
				rhs = function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
				desc = "print(vim.inspect(vim.lsp.buf.list_workspace_folders()))",
			},
		},
		[LspMethods.textDocument_codeAction] = {
			-- same as previous, but if there's only one possible action, just apply it
			{
				mode = "n",
				lhs = "<leader>qf",
				rhs = function() vim.lsp.buf.code_action({ apply = true }) end,
				desc = "Apply single code action",
			},
		},
		[LspMethods.textDocument_completion] = {
			{
				mode = "i",
				lhs = "<c-space>",
				rhs = function() vim.lsp.buf.completion() end,
				desc = "vim.lsp.buf.completion()",
			},
		},
		[LspMethods.textDocument_formatting] = {
			{
				mode = "n",
				lhs = "<leader>f",
				rhs = function() vim.lsp.buf.format() end,
				desc = "vim.lsp.buf.format()",
			},
		},
		[LspMethods.textDocument_inlineCompletion] = {
			{
				mode = "i",
				lhs = "<C-F>",
				rhs = function() vim.lsp.inline_completion.get() end,
				desc = "vim.lsp.inline_completion.get()",
			},
			{
				mode = "i",
				lhs = "<C-G>",
				rhs = function() vim.lsp.inline_completion.select() end,
				desc = "vim.lsp.inline_completion.select()",
			},
		},
	}
	local telescope_builtin = RequireChecked("telescope.builtin")
	if telescope_builtin ~= nil then
		methodsAndKeymaps[LspMethods.textDocument_definition] = {
			{
				mode = "n",
				lhs = "gd",
				rhs = function() require('telescope.builtin').lsp_definitions() end,
				desc = "telescope.builtin.lsp_definitions()",
			},
		}
	end
	for method, keymaps in pairs(methodsAndKeymaps) do
		if client:supports_method(method, bufnr) then
			for _, keymap in ipairs(keymaps) do
				map(keymap.mode, keymap.lhs, keymap.rhs, keymap.desc, keymap.opts)
			end
		end
	end
	-- vim.diagnostic keymaps are unconditional: `textDocument/publishDiagnostics` is a server→client
	-- notification, not a ServerCapability, so supports_method() always returns false for it
	map("n", "<leader>d", function() vim.diagnostic.open_float({ scope = 'line' }) end, "vim.diagnostic.open_float()")
	map("n", "<leader>q", function() vim.diagnostic.setqflist({ open = true }) end, "vim.diagnostic.setqflist()")
	map("n", "<leader>l", function() vim.diagnostic.setloclist({ open = true }) end, "vim.diagnostic.setloclist()")

	if client:supports_method(LspMethods.textDocument_inlayHint, bufnr) then
		-- unstable API.  Might break soon
		vim.lsp.inlay_hint.enable(true)
	end
	if client:supports_method(LspMethods.textDocument_completion, bufnr) then
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
	end
	if client:supports_method(LspMethods.textDocument_documentSymbol, bufnr) then
		configure_breadcrumbs(client)
	end
	if client:supports_method(LspMethods.textDocument_inlineCompletion, bufnr) then
	    vim.lsp.inline_completion.enable(true, {bufnr = bufnr})
	    local sidekick = RequireChecked("sidekick")
	    if sidekick == nil then
		print("sidekick not installed, not setting up inline completion keymaps")
	    else
		sidekick.setup{
		    cli = {
			tools = {
			    traecli = {
				cmd = { "traecli" },
				title = "Trae CLI",
			    }
			}
		    }
		}
		local keys = {
		    {
		        "<Tab>",
		        function()
			    -- if there is a next edit, jump to it, otherwise apply it if any
			    if require("sidekick").nes_jump_or_apply() then
				return -- jumped or applied
			    end

			    -- if you are using Neovim's native inline completions
			    if vim.lsp.inline_completion.get() then
				return
			    end

			    -- any other things (like snippets) you want to do on <tab> go here.

			    -- fall back to normal tab
			    return "<tab>"

		        end,
		        expr = true,
		        mode = { "i", "n" },
		        desc = "Goto/Apply Next Edit Suggestion",
		    },
		    {
			"<c-.>",
			function() require("sidekick.cli").toggle() end,
			desc = "Sidekick Toggle",
		    },
		    {
			"<leader>aa",
			function() require("sidekick.cli").toggle() end,
			desc = "Sidekick Toggle CLI",
		    },
		    {
			"<leader>as",
			function() require("sidekick.cli").select() end,
			-- Or to select only installed tools:
			-- require("sidekick.cli").select({ filter = { installed = true } })
			desc = "Select CLI",
		    },
		    {
			"<leader>ad",
			function() require("sidekick.cli").close() end,
			desc = "Detach a CLI Session",
		    },
		    {
			"<leader>at",
			function() require("sidekick.cli").send({ msg = "{this}" }) end,
			mode = { "x", "n" },
			desc = "Send This",
		    },
		    {
			"<leader>af",
			function() require("sidekick.cli").send({ msg = "{file}" }) end,
			mode = { "n" },
			desc = "Send File",
		    },
		    {
			"<leader>av",
			function() require("sidekick.cli").send({ msg = "{selection}" }) end,
			mode = { "x" },
			desc = "Send Visual Selection",
		    },
		    {
			"<leader>ap",
			function() require("sidekick.cli").prompt() end,
			mode = { "n", "x" },
			desc = "Sidekick Select Prompt",
		    },
		}

		for _, key in ipairs(keys) do
		    local lhs, func = unpack(key)
		    vim.keymap.set(key.mode or "", lhs, func, { silent = false, desc = key.desc, expr=key.expr })
		end

		if not vim.g.sidekick_statusline_added then
		    vim.g.sidekick_statusline_added = true
		    vim.o.statusline = vim.o.statusline .. " %{% v:lua.SidekickStatusline() %}"
		end
	    end
	end
	vim.diagnostic.config({
		virtual_lines = {current_line = true}
	})
end

local godotnvim = function()
	local go = RequireChecked("go")
	if go == nil then
		print("go.nvim not installed.  Not loading go.nvim")
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

	-- NOTE: Unfortunately, TikTok's go codebase imports tens of gigabytes of dependencies
	-- that I don't want on my machine, so I'm disabling it for now and instead adding a function
	-- to manually turn it on
	--godotnvim()
end
vim.api.nvim_create_user_command("Plsgo", godotnvim, {})

local quick_lint_js = {
	"quick_lint_js",
	{
		on_attach = function(client, bufnr)
			vim.diagnostic.config({ update_in_insert = true }, vim.lsp.diagnostic.get_namespace(client.id))
			on_attach(client, bufnr)
		end,
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

local defaultConfig = {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  }
}

local copilot = {
    "copilot",
}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { quick_lint_js, tsserver_config, pythonruff_config, pythonty_config, clangd_config, rust_config, zig_config, copilot }
for _, lsp in ipairs(servers) do
	local name, settings = unpack(lsp)
	if settings == nil then
		settings = defaultConfig
	end
	vim.lsp.config(name, settings)
	vim.lsp.enable(name)
end

LUAEND

" AI START

" MarsCode start

if &loadplugins
	" silent! packadd codeverse.vim
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
lua << LUAEND
    local copilot = RequireChecked("copilot")
    if copilot == nil then
	--print("copilot not installed")
    else
	-- TODO: because startup is slow I need to lazy load this
	--copilot.setup({

	--})
    end
LUAEND
" Copilot end
lua << LUAEND

local snacks = RequireChecked("snacks")
if snacks == nil then
	return
end
snacks.setup({
    picker = { enabled=true },
    debug = { enabled = true }
})

LUAEND
" AI END



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

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -u -- '.fzf#shellescape(<q-args>),
  \   fzf#vim#with_preview(), <bang>0)

"" FZF end

"" TELESCOPE start
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

if &loadplugins
	silent! packadd nvim.undotree
endif

lua <<LUAEND
local telescope = RequireChecked("telescope")
if telescope == nil then
	return false
end
local fzy_native = RequireChecked("telescope._extensions.fzy_native")
if fzy_native == nil then
	return false
end
telescope.load_extension("fzy_native")
LUAEND
"" TELESCOPE end

" TREESITTER start
lua << LUAEND

local treesitter_plugin = RequireChecked("nvim-treesitter")
if treesitter_plugin == nil then
	print("Treesitter plugin not loaded.  Not loading treesitter")
	return false
end

vim.api.nvim_create_autocmd('FileType', {
	pattern = '*',
	callback = function()
		vim.wo.foldmethod = 'expr'
		vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		local ok = pcall(vim.treesitter.start)
		if ok then
			return
		end

		local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
		if not lang then
			return
		end

		local parsers = require('nvim-treesitter.parsers')
		if not parsers[lang] then
			return
		end

		local installed = require('nvim-treesitter.config').get_installed('parsers')
		if vim.list_contains(installed, lang) then
			return
		end

		vim.schedule(function()
			vim.api.nvim_create_autocmd('User', {
				pattern = 'TSUpdate',
				once = true,
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
			require('nvim-treesitter').install({ lang })
		end)
	end,
})

local install_plugin_name = "treesitter-context"
local treesitterContext = RequireChecked(install_plugin_name)
if treesitterContext == nil then
	print(install_plugin_name .. " plugin not loaded.  Not loading treesitter-context")
	return false
end
treesitterContext.setup{}
vim.keymap.set("n", "[c", function() treesitterContext.go_to_context(vim.v.count1) end)
LUAEND

lua << LUAEND

local ok, ui2 = pcall(require, "vim._core.ui2")
if ok then
	ui2.enable({})
end

local devicons_plugin = RequireChecked("nvim-web-devicons")
if devicons_plugin ~= nil then
	devicons_plugin.setup({
		default = true,
	})
end

LUAEND

lua local hardtime = RequireChecked("hardtime"); if hardtime ~= nil then hardtime.setup{restriction_mode="hint", disable_mouse=false, disabled_keys={}, max_time=0} end
lua local oil = RequireChecked("oil"); if oil ~= nil then oil.setup(); vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" }) end
lua local colorizer = RequireChecked("colorizer"); if colorizer ~= nil then vim.o.termguicolors = true; colorizer.setup({options={parsers={css=true}, display={mode={"virtualtext", "foreground"}}}}) end
lua local gitsigns = RequireChecked("gitsigns"); if gitsigns ~= nil then vim.o.statusline = vim.o.statusline .. " %{get(b:,'gitsigns_status','')}" end
