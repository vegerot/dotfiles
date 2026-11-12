#!/bin/bash
# Manual test for the "one file per tab" jumps in .config/nvim/init.lua
# (gd, <C-o>, <C-i>, <C-t>).
#
# It starts the real nvim with the real config in tmux, presses keys over RPC,
# and compares which tab shows which file.  It needs tmux, rg, and lua_ls.
# Takes about 90 seconds: every test starts a fresh nvim and waits for lua_ls.
#
# usage: tests/nvim_jump_one_file_per_tab_test.sh [test name...]

CFG="$(cd "$(dirname "$0")/.." && pwd)/.config/nvim/init.lua"
TMP=$(mktemp -d)
SOCK=$TMP/nvim.sock
SESSION=nvim-jump-test
fail=0
trap 'tmux kill-session -t $SESSION 2>/dev/null; rm -rf "$TMP"' EXIT

cat > "$TMP/helpers.lua" <<'EOF'
-- one line that says which tab shows which file; "*" marks the cursor, "+" joins splits
function _G.Layout()
  local api, tabs = vim.api, {}
  for _, tab in ipairs(api.nvim_list_tabpages()) do
    local wins = {}
    for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
      if api.nvim_win_get_config(win).relative == "" then
        local name = vim.fn.fnamemodify(api.nvim_buf_get_name(api.nvim_win_get_buf(win)), ":t")
        wins[#wins + 1] = (win == api.nvim_get_current_win() and "*" or "")
          .. (name == "" and "NoName" or name) .. ":" .. api.nvim_win_get_cursor(win)[1]
      end
    end
    tabs[#tabs + 1] = table.concat(wins, "+")
  end
  return table.concat(tabs, " | ")
end

-- 1 when lua_ls answers a definition request for the word under the cursor.
-- "Client attached" is not enough: lua_ls attaches long before it can answer.
function _G.LspReady()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" })[1]
  if not client then return 0 end
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local res = client:request_sync("textDocument/definition", params, 2000, 0)
  return (res and res.result and #res.result > 0) and 1 or 0
end
EOF

expr() { nvim --server "$SOCK" --remote-expr "$1"; }
start() { # start <nvim arguments>
  tmux kill-session -t $SESSION 2>/dev/null; rm -f "$SOCK"
  tmux new-session -d -s $SESSION -x 160 -y 45 "cd /tmp && nvim --listen $SOCK $1"
  for _ in $(seq 1 40); do [ -S "$SOCK" ] && break; sleep 0.25; done
  expr "execute('luafile $TMP/helpers.lua')" >/dev/null
}
# keys go in over RPC, so <C-i> is not confused with <Tab>
press() { for key in "$@"; do expr "nvim_input('$key')" >/dev/null; sleep 1.5; done; }
on() { expr "cursor($1, stridx(getline($1), '$2') + $3)" >/dev/null; } # on <line> <text> <offset>
waitlsp() {
  for _ in $(seq 1 60); do [ "$(expr 'luaeval("LspReady()")' 2>/dev/null)" = 1 ] && return; sleep 1; done
  echo "lua_ls never answered"; fail=1
}
checkexpr() { # checkexpr <name> <vim expression> <wanted value>
  local got; got=$(expr "$2")
  if [ "$got" = "$3" ]; then echo "PASS $1"; else echo "FAIL $1"; echo "   want: $3"; echo "   got:  $got"; fail=1; fi
}
check() { checkexpr "$1" 'luaeval("Layout()")' "$2"; } # check <name> <wanted layout>

# Every LSP test starts in init.lua with the cursor on `set` of this line, which
# lua_ls resolves to keymap.lua in the nvim runtime.  The line moves, so look it up.
L=$(rg --line-number --fixed-strings 'vim.keymap.set(mode, lhs, rhs, opts)' "$CFG" | cut -d: -f1)
fresh() { start "--cmd 'set shada=' $CFG"; on "$L" keymap.set 8; waitlsp; }
# second hop: `validate` of vim.validate on keymap.lua:67 is defined in shared.lua
hop2() { on 67 vim.validate 6; waitlsp; press gd; }

t_gd_then_back() {
  fresh
  press gd;      check "gd opens the definition in a new tab"  "init.lua:$L | *keymap.lua:66"
  press '<C-o>'; check "<C-o> returns to the first tab"        "*init.lua:$L | keymap.lua:66"
}

t_forward() {
  fresh
  press gd '<C-o>' '<C-i>'; check "<C-i> goes forward to the definition's tab"  "init.lua:$L | *keymap.lua:66"
  press '<C-o>';            check "<C-o> goes back again"                      "*init.lua:$L | keymap.lua:66"
}

t_chain() {
  fresh; press gd; hop2
  check "two gd in a row give three tabs"  "init.lua:$L | keymap.lua:67 | *shared.lua:1286"
  press '<C-o>';  check "back one"         "init.lua:$L | *keymap.lua:67 | shared.lua:1286"
  press '<C-o>';  check "back two"         "*init.lua:$L | keymap.lua:67 | shared.lua:1286"
  press '<C-i>';  check "forward one"      "init.lua:$L | *keymap.lua:67 | shared.lua:1286"
  press '<C-i>';  check "forward two"      "init.lua:$L | keymap.lua:67 | *shared.lua:1286"
  press '2<C-o>'; check "a count works"    "*init.lua:$L | keymap.lua:67 | shared.lua:1286"
}

t_tag_back() {
  fresh; press gd; hop2
  press '<C-t>'; check "<C-t> returns to where the last gd started"  "init.lua:$L | *keymap.lua:67 | shared.lua:1286"
  press '<C-t>'; check "<C-t> again returns to the first gd"         "*init.lua:$L | keymap.lua:67 | shared.lua:1286"
}

# "continue where I left off": a fresh nvim with no file, history from a copy of the real ShaDa file
t_fresh_start() {
  cp ~/.local/state/nvim/shada/main.shada "$TMP/copy.shada"
  start "-i $TMP/copy.shada"; sleep 3
  press '<C-o>'
  checkexpr "<C-o> in an empty nvim opens the last file"   'bufname() != ""' 1
  checkexpr "... in the same tab, with no blank tab left"  'tabpagenr("$")' 1
}

t_reuse_and_same_file() {
  fresh; press gd '<C-o>' gd
  check "a second gd reuses the tab that shows the file"  "init.lua:$L | *keymap.lua:66"
  press gg G '<C-o>'
  check "<C-o> inside one file stays in the tab"          "init.lua:$L | *keymap.lua:1"
}

[ $# -eq 0 ] && set -- t_gd_then_back t_forward t_chain t_tag_back t_fresh_start t_reuse_and_same_file
for t in "$@"; do
  echo "--- $t"; $t
  # a wrong window id once left the layout right and only showed up as an error message
  checkexpr "no error messages" 'execute("messages") =~ "E\\d\\+:\\|stack traceback"' 0
done
exit $fail
