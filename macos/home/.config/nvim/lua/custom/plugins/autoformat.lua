-- File: lua/custom/plugins/autoformat.lua
return {
  -- Re-open the existing plugin spec and tweak only what we need
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      -- Replace the original format_on_save callback
      opts.format_on_save = function(bufnr)
        -- skip Lua, but keep Kickstart’s original C/C++ guard
        local disable = { lua = true, c = true, cpp = true }
        if disable[vim.bo[bufnr].filetype] then
          return -- nil → “do nothing”
        end
        -- keep the rest identical to Kickstart’s default
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end
      return opts
    end,
  },
}
