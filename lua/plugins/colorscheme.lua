return {
  {
    "Ferouk/bearded-nvim",
    name = "bearded",
    lazy = false,
    priority = 1000,
    opts = {
      flavor = "solarized-light",
      italic = false,
      on_highlights = function(set)
        set("WinSeparator", { fg = "#000000", bold = true })
        for _, group in ipairs({ "Visual", "VisualNOS" }) do
          set(group, { fg = "#FDF6E3", bg = "#185A78" })
        end
        for _, group in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
          set(group, { fg = "#073642", bg = "#B8DDE8" })
        end
        set("Search", { fg = "#073642", bg = "#E9D88B" })
        set("IncSearch", { fg = "#073642", bg = "#8CCBD9", bold = true })
        set("CurSearch", { fg = "#073642", bg = "#8CCBD9", bold = true })
        for name, highlight in pairs(vim.api.nvim_get_hl(0, { link = false })) do
          if highlight.italic then
            highlight.italic = false
            set(name, highlight)
          end
        end
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "bearded" },
  },
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options.style_preset = require("bufferline").style_preset.no_italic
    end,
  },
}
