-- Only format on save (prettier and organize imports) when the project opts
-- into prettier. Many projects (e.g. pxt) have their own style and would be
-- mangled.
local prettier_config_names = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.cts",
  ".prettierrc.mts",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
}

-- Cache results per directory so we don't stat the tree on every keypress.
local prettier_cache = {}

local function project_uses_prettier(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end
  local dir = vim.fs.dirname(name)
  if prettier_cache[dir] ~= nil then
    return prettier_cache[dir]
  end

  local found = false
  -- Look for a dedicated prettier config file walking upward.
  if #vim.fs.find(prettier_config_names, { path = dir, upward = true }) > 0 then
    found = true
  else
    -- Otherwise check for a "prettier" key in the nearest package.json.
    local pkg = vim.fs.find("package.json", { path = dir, upward = true })[1]
    if pkg then
      local ok, contents = pcall(function()
        return table.concat(vim.fn.readfile(pkg), "\n")
      end)
      if ok and contents:match('"prettier"%s*:') then
        found = true
      end
    end
  end

  prettier_cache[dir] = found
  return found
end

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      { "<leader>cf", function() require("conform").format() end, desc = "Format file" },
    },
    opts = function()
      -- Returns the prettier formatter list only when the project opts in.
      -- Otherwise an empty list, and with no LSP fallback the file is left alone.
      local function prettier_if_configured(bufnr)
        if project_uses_prettier(bufnr) then
          return { "prettierd", "prettier", stop_after_first = true }
        end
        return {}
      end

      return {
        formatters_by_ft = {
          javascript = prettier_if_configured,
          javascriptreact = prettier_if_configured,
          typescript = prettier_if_configured,
          typescriptreact = prettier_if_configured,
          json = prettier_if_configured,
          jsonc = prettier_if_configured,
          html = prettier_if_configured,
          css = prettier_if_configured,
          markdown = prettier_if_configured,
          yaml = prettier_if_configured,
        },
        -- Disabled: we run formatting manually in the unified BufWritePre below
        format_on_save = false,
      }
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "vtsls", "lua_ls" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", vim.lsp.buf.references, "References")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gy", vim.lsp.buf.type_definition, "Type definition")
          map("K", vim.lsp.buf.hover, "Hover")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })

      -- Unified format-on-save: organize imports + prettier as single undo entry
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(event)
          local bufnr = event.buf
          if not project_uses_prettier(bufnr) then
            return
          end
          local cursor = vim.api.nvim_win_get_cursor(0)
          local cursor_line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
          local snapshot = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          local changed = false

          -- Step 1: Organize imports for TS/JS files
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name:match("%.[jt]sx?$") then
            local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })
            if #clients > 0 then
              clients[1]:request_sync("workspace/executeCommand", {
                command = "typescript.organizeImports",
                arguments = { name },
              }, 2000, bufnr)
            end
          end

          -- Check if organize imports changed anything
          local after_imports = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          if not vim.deep_equal(snapshot, after_imports) then
            changed = true
          end

          -- Step 2: Run prettier/conform (undojoin so it merges with organize imports)
          if changed then
            vim.cmd("undojoin")
          end
          require("conform").format({ bufnr = bufnr, timeout_ms = 2000, lsp_format = "never" })

          -- Check if anything changed overall
          local final = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          if vim.deep_equal(snapshot, final) then
            -- Nothing changed, undo any intermediate noise
            if not vim.deep_equal(snapshot, after_imports) then
              vim.cmd("silent! undo")
            end
          end

          -- Restore cursor: find the original line content in the reformatted buffer
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if cursor_line then
            local final_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            -- Search near the original position first, expanding outward
            local best = math.min(cursor[1], line_count)
            for offset = 0, line_count do
              for _, dir in ipairs({ 0, -1, 1 }) do
                local row = cursor[1] + offset * dir
                if row >= 1 and row <= line_count and final_lines[row] == cursor_line then
                  best = row
                  goto found
                end
              end
            end
            ::found::
            pcall(vim.api.nvim_win_set_cursor, 0, { best, cursor[2] })
          else
            pcall(vim.api.nvim_win_set_cursor, 0, { math.min(cursor[1], line_count), cursor[2] })
          end
        end,
      })

      -- TypeScript via vtsls - automatically uses project-local TypeScript from node_modules
      lspconfig.vtsls.setup({
        capabilities = capabilities,
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
          },
        },
        on_attach = function(client)
          -- Suppress "client extension required" error after organizeImports
          vim.lsp.commands["_typescript.didOrganizeImports"] = function() end
        end,
      })

      -- Lua (for editing nvim config)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })
    end,
  },
}
