if vim.g.vscode then
  return {}
end

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    opts = function(_, opts)
      local colors = { "#F7F7D8", "#EFF7DB", "#FCEDE4", "#EAF3EF" }
      local highlights = {}
      for i in ipairs(colors) do
        highlights[i] = "RainbowIndentBackground" .. i
      end

      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        for i, color in ipairs(colors) do
          vim.api.nvim_set_hl(0, highlights[i], { bg = color })
        end
      end)

      -- Color the whitespace at each indentation level, not the code itself.
      opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, {
        char = "",
        tab_char = "",
        highlight = highlights,
      })
      opts.whitespace = vim.tbl_deep_extend("force", opts.whitespace or {}, {
        highlight = highlights,
        remove_blankline_trail = false,
      })
      opts.scope = vim.tbl_deep_extend("force", opts.scope or {}, { enabled = false })
    end,
  },
}
