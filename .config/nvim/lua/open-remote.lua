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

local function open_repo()
	local repo_path = get_remote_path_from_config()
	local url = "https://" .. get_repo_url_from_sl_path(repo_path)
	-- TODO: xdg-open
	vim.cmd("!open " .. url)
end
vim.api.nvim_create_user_command("OpenRepo", open_repo, {nargs=0})

--- TESTS

local function test_get_repo_url_from_remote_path()
	Assert_equals(get_repo_url_from_sl_path("ssh://git@gecgithub01.walmart.com/ce-orchestration/ce-smartlists.git"), "gecgithub01.walmart.com/ce-orchestration/ce-smartlists")
	Assert_equals(get_repo_url_from_sl_path("https://github.com/facebook/sapling.git"), "github.com/facebook/sapling")
end

local function test_get_remote_paths_from_config()
	Assert_equals(get_remote_path_from_config(), "ssh://git@github.com/vegerot/dotfiles.git")
end

local function test_open_repo()
	-- ???
	-- explanation: `:OpenRepo` should take me to the homepage of the repo I'm currently working in
	-- how do I test this?  https://discord.com/channels/640652660839677962/825271547870707762/1076248620162093156
end

local function test()
	test_get_repo_url_from_remote_path()
	test_get_remote_paths_from_config()
	test_open_repo()
end
-- jank: run tests with `:w | source % | OpenRemoteTest`
vim.api.nvim_create_user_command("OpenRemoteTest", test, {nargs=0})

function Assert_equals(got, want)
	if got ~= want then
		print("Expected: " .. want .. " Actual: " .. got)
		assert(false)
	end
end
