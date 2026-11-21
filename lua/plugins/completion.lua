if vim.g.vscode then
  return {}
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        -- Same as VS Code: Enter inserts a newline, Tab accepts (the first item if none is
        -- selected), Ctrl+Space opens the list or toggles its documentation.
        ["<CR>"] = { "fallback" },
        ["<C-y>"] = { "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      },
      completion = {
        -- Browsing suggestions must not change the buffer before Tab.
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
