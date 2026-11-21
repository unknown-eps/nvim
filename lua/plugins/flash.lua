-- Normal-mode Ctrl+Space opens completions instead (config/keymaps.lua), like VS Code.
-- Keep LazyVim's flash incremental selection on Ctrl+Space in Visual and Operator-pending.
return {
  {
    "folke/flash.nvim",
    keys = {
      { "<c-space>", mode = "n", false },
    },
  },
}
