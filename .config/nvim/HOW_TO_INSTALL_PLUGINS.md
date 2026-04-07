<!-- vim:nowrap -->

## Plugin Management

Plugins are declared directly in `~/.config/nvim/init.vim` with Neovim's built-in
package manager, `vim.pack`.

Neovim installs managed plugins into:

- `~/.local/share/nvim/site/pack/core/opt/`

`vim.pack` also writes a lockfile here:

- `~/.config/nvim/nvim-pack-lock.json`

## First Install

1. Start `nvim`
2. `vim.pack.add(...)` in `init.vim` will install any missing plugins automatically.
3. Restart Neovim after the first install so newly installed plugin code is available from startup.

## Update Plugins

Run:

```vim
:lua vim.pack.update()
```

This opens a review buffer.

- `:write` confirms updates
- `:quit` discards them

After updating, restart Neovim.

## Remove A Plugin

1. Remove its spec from `init.vim`
2. Restart Neovim
3. Delete it from disk:

```vim
:lua vim.pack.del({ 'plugin-name' })
```

## Rebuild Native Plugins

`telescope-fzy-native.nvim` is built automatically via a `PackChanged` autocmd in
`init.vim` which runs `make` after install or update.

## Test That Plugin Management Works

Headless smoke test:

```sh
NVIM_APPNAME=nvim-pack-test nvim --headless
```

The throwaway test config lives at:

- `~/.config/nvim-pack-test/init.vim`

It installs a plugin with `vim.pack` and writes `ok` to:

- `~/.local/state/nvim-pack-test/pack-test-result.txt`

## Notes

- Built-in Neovim plugins like commenting, `matchit`, and `nvim.undotree` do not
  need to be installed separately.
- If a plugin update overwrites a local patch, reapply the patch or move the
  workaround into `init.vim`.
