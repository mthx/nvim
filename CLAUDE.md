# Neovim Config

Neovim 0.12 config using the built-in plugin manager (`vim.pack`). Plugin
versions are pinned in `nvim-pack-lock.json`; update with `:lua vim.pack.update()`.

## Structure

- `init.lua` — options, keymaps, plugin build hooks (`PackChanged`), requires the plugin modules
- `lua/plugins/lsp.lua` — LSP via `vim.lsp.config` (vtsls, lua_ls; mason installs and enables them), conform.nvim (prettier), organize imports on save — only when the project uses prettier
- `lua/plugins/editor.lua` — telescope, treesitter (main branch) and textobjects, gitsigns, neo-tree
- `lua/plugins/completion.lua` — blink.cmp
- `lua/plugins/ui.lua` — colorscheme, which-key, lualine

## Validating changes

After any config change, run:

```sh
nvim --headless -c 'qall' 2>&1
```

Suggest committing changes.

No output means success. Any errors will be printed to stderr.

## Plugin policy

Prefer well-maintained, popular plugins. Drop a feature rather than use something unmaintained or obscure.
