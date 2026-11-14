if vim.g.vscode then
  return {}
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<C-y>"] = { "fallback" },
        ["<C-space>"] = { "select_next", "show", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      },
      completion = {
        -- Browsing suggestions must not change the buffer before Enter.
        list = { selection = { auto_insert = false } },
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
