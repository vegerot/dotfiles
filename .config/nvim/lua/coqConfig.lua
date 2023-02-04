vim.g.coq_settings = {
  ["clients.tabnine"] = {
    enabled = true,
    weight_adjust = -0.4,
  },
  auto_start = 'shut-up',
  -- conflicts with Tmux
  ["keymap.jump_to_mark"] = ''
}

require("coq_3p") {
	{src = "copilot", short_name="✈", accept_key="<c-f>"}

}
