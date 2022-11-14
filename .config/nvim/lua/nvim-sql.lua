vim.api.nvim_create_autocmd("BufWritePost", {
	group = vim.api.nvim_create_augroup("SqliteRunner", {clear = true}),
	pattern = "editor.sql",
	callback = function()
		local cmd = {"sqlite3", "/Users/m0c0j7y/workspace/sql/tutorial/tut.db", ".read " .. vim.api.nvim_buf_get_name(0)}
		vim.fn.jobstart(cmd, {
			stdout_buffered = true,
			on_stdout = function(_, data, _)
				--if data then print(table.concat(data, "\n")) end
				if data then vim.api.nvim_command("echo " .. '"' .. table.concat(data, "\\n") .. '"') end
			end,
			on_stderr = function(_, data, _)
				--if data then print(table.concat(data, "\n")) end
				if data then vim.api.nvim_command("echo " .. '"' .. table.concat(data, "\\n") .. '"') end
			end
		})
	end
})

