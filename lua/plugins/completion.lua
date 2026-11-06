if vim.g.vscode then
  return {}
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<CR>"] = { "fallback" },
        ["<C-y>"] = { "fallback" },
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      },
    },
  },
  {
    "folke/noice.nvim",
    keys = {
      {
        "<C-d>",
        function()
          if not require("noice.lsp").scroll(4) then
            return "<C-d>"
          end
        end,
        mode = { "n", "i", "s" },
        expr = true,
        silent = true,
        desc = "Scroll documentation down",
      },
      {
        "<C-u>",
        function()
          if not require("noice.lsp").scroll(-4) then
            return "<C-u>"
          end
        end,
        mode = { "n", "i", "s" },
        expr = true,
        silent = true,
        desc = "Scroll documentation up",
      },
    },
  },
}
