--- PLUGIN
local function get_repo_url_from_sl_path (path)
	local function trim_to(str, pattern)
		local start = string.find(str, pattern)
		if start then
			return string.sub(str, start + string.len(pattern))
		end
		return str
	end

	local repo_url = path
	repo_url = trim_to(repo_url, "://")
	repo_url = trim_to(repo_url, "git@")

	-- calculating the length of this pattern ("%.git") is non-trivial
	-- and it's only used once so do it the long way
	local repo_url_end = string.find(repo_url, "%.git")
	if repo_url_end then
		repo_url = string.sub(repo_url, 0, repo_url_end - 1)
	end
	return repo_url
end

local function get_remote_path_from_config()
	-- TODO: prompt if multiple paths (or just use `default`?)
	-- TODO: support git
	local command = "sl paths default"
	local handle = assert(io.popen(command))
	local path = handle:read("*a")
	handle:close()
	-- remove trailing newline
	local path_stripped_trailing_newline = string.sub(path, 0, string.len(path) - 1)
	return path_stripped_trailing_newline
end

-- Open the repo homepage.  This was made to start open-remote but shouldn't be used
function Open_Repo()
	local repo_path = get_remote_path_from_config()
	local url = "https://" .. get_repo_url_from_sl_path(repo_path)
	-- TODO: xdg-open
	vim.cmd("!open " .. url)
end
vim.api.nvim_create_user_command("OpenRepo", Open_Repo, {nargs=0})

function Open_File_Cmd(params)
	local absolute_filepath = params.absolute_filepath
	local repo_root = params.repo_root
	local line_number = params.line_number
	local os = params.os
	local remote_path = params.remote_path
	local ref = params.ref

	local open_cmd = "open"
	if os == "Linux" then
		open_cmd = "xdg-open"
	end

	local relative_filepath = string.sub(absolute_filepath, string.len(repo_root) + 2)
	local url = vim.fn.fnameescape("https://" .. get_repo_url_from_sl_path(remote_path) .. "/blob/" .. ref .. "/" .. relative_filepath .. "#L" .. line_number)
	return open_cmd .. " '" .. url .. "'"
end

local function strip_trailing_newline(str)
	assert(string.sub(str, string.len(str)) == "\n")
	return string.sub(str, 0, string.len(str) - 1)
end

local function get_params()
	local absolute_filepath = vim.fn.expand("%:p")
	local repo_root = strip_trailing_newline(vim.fn.system('sl root'))
	local line_number = vim.fn.line(".")
	local os = strip_trailing_newline(vim.fn.system("uname"))
	local remote_path = get_remote_path_from_config()
	local sapling_remotebookmark_template = 'sub("remote/", "", remotebookmarks)'
	-- use the remote branch name if it exists, otherwise use the commit hash
	local sapling_ref_template = '{ifeq(' .. sapling_remotebookmark_template .. ', "", "{node}",' .. sapling_remotebookmark_template .. ' )}'
	-- TODO: check if commit is pushed, and if not fall back to `main` branch
	local ref = (vim.fn.system('sl log -r . -T \'' .. sapling_ref_template .. "'"))

	return { ref = ref, repo_root = repo_root, line_number = line_number, os = os, remote_path = remote_path,
		absolute_filepath = absolute_filepath }
end

local function get_params_and_open_file_helper()
	local params = get_params()
	return Open_File_Cmd(params)
end

local function open_file()
	local cmd = get_params_and_open_file_helper()
	print(cmd)
	vim.cmd("!" .. cmd)
end
vim.api.nvim_create_user_command("OpenFile", open_file, {nargs=0})

--- TESTS
local function test_get_repo_url_from_remote_path()
	Assert_equals(get_repo_url_from_sl_path("ssh://git@gecgithub01.walmart.com/ce-orchestration/ce-smartlists.git"), "gecgithub01.walmart.com/ce-orchestration/ce-smartlists")
	Assert_equals(get_repo_url_from_sl_path("https://github.com/facebook/sapling.git"), "github.com/facebook/sapling")
end

local function test_get_remote_paths_from_config()
	Assert_equals(get_remote_path_from_config(), "ssh://git@github.com/vegerot/dotfiles.git")
end

local function test_open_file_helper()
	local cmd = Open_File_Cmd({ absolute_filepath = "~/dotfiles/.config/nvim/lua/open-remote.lua",
		repo_root = "~/dotfiles", line_number = 69, os = "Darwin", remote_path = "git@github.com/vegerot/dotfiles",
		ref = "main" })
	Assert_equals(cmd, "open 'https://github.com/vegerot/dotfiles/blob/main/.config/nvim/lua/open-remote.lua\\#L69'")

	local cmd2 = Open_File_Cmd({ absolute_filepath = "~/workspace/gitlab.com/gitlab-org/gitlab/.gitlab/CODEOWNERS",
		line_number = 42, repo_root = "~/workspace/gitlab.com/gitlab-org/gitlab", os = "Linux",
		remote_path = "https://gitlab.com/gitlab-org/gitlab.git", ref = "79da4d8f" })
	Assert_equals(cmd2, "xdg-open 'https://gitlab.com/gitlab-org/gitlab/blob/79da4d8f/.gitlab/CODEOWNERS\\#L42'")
end


local function run_e2e_test()
	local this_file = vim.fn.expand("%:p")
	vim.fn.system("nvim +'source "..this_file.."' +OpenRemoteTestE2e")
end


-- run with `open-remote-test` script
local function e2e_test()
	local cmd = get_params_and_open_file_helper()
	Assert_equals(cmd,  "xdg-open 'https://github.com/testuser/testrepo/blob/debugupstream/foo.txt\\#L2'")
	-- for some reason neovim (libuv in particular) crashes when using `vim.cmd("quit")`
	os.exit()
end
vim.api.nvim_create_user_command("OpenRemoteTestE2e", e2e_test, {nargs=0})

-- run with `open-remote-test` script
local function e2e_test_2()
	local cmd = get_params_and_open_file_helper()
	local want = "xdg--open 'https://github.com/testuser/testrepo/blob/(%x+)/foo.txt\\#L2'"
	local start, stop, maybe_match = string.find(cmd, want)
	assert(maybe_match ~= nil)
	Assert_equals(string.len(maybe_match), 40)

	os.exit()
end
vim.api.nvim_create_user_command("OpenRemoteTestE2e2", e2e_test_2, {nargs=0})


-- run tests automatically: `nmap <leader>t :w \| source % \| OpenRemoteTest <CR>`
local function test()
	test_get_repo_url_from_remote_path()
	test_get_remote_paths_from_config()
	test_open_file_helper()
	print("✅")
end
-- jank: run tests with `:w | source % | OpenRemoteTest`
vim.api.nvim_create_user_command("OpenRemoteTest", test, {nargs=0})
function Open_Remote_Test()
	test()
	os.exit()
end

function Assert_equals(got, want)
	if got ~= want then
		print("Expected: " .. want .. " Actual: " .. got)
		assert(false)
	end
end
