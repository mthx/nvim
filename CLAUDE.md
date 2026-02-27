# Neovim Config

Neovim config using lazy.nvim.

## Structure

- `init.lua` — options, keymaps, lazy.nvim bootstrap, treesitter textobject keymaps
- `lua/plugins/lsp.lua` — LSP (vtsls for TypeScript, lua_ls), conform.nvim (prettier), organize imports on save
- `lua/plugins/editor.lua` — telescope, treesitter, gitsigns, neo-tree
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
