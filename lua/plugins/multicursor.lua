return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    vscode = true,
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or { "n", "x" }, lhs, rhs, { desc = desc })
      end

      -- Zed Vim mode: matches of the current word or visual selection.
      map("gl", function() mc.matchAddCursor(1) end, "Add cursor at next match")
      map("gL", function() mc.matchAddCursor(-1) end, "Add cursor at previous match")
      map("ga", mc.matchAllAddCursors, "Add cursors at all matches")
      map("g>", function() mc.matchSkipCursor(1) end, "Skip to next match")
      map("g<", function() mc.matchSkipCursor(-1) end, "Skip to previous match")
      -- Zed's gn/gN operate on the current search pattern.
      map("gn", function() mc.searchAddCursor(1) end, "Add cursor at next search match", "n")
      map("gN", function() mc.searchAddCursor(-1) end, "Add cursor at previous search match", "n")
      map("<C-A-Up>", function() mc.lineAddCursor(-1) end, "Add cursor above")
      map("<C-A-Down>", function() mc.lineAddCursor(1) end, "Add cursor below")

      mc.addKeymapLayer(function(set)
        set({ "n", "x" }, "<Left>", mc.prevCursor, { desc = "Previous main cursor" })
        set({ "n", "x" }, "<Right>", mc.nextCursor, { desc = "Next main cursor" })
        set("n", "<Esc>", function()
          mc.clearCursors()
          vim.cmd("nohlsearch")
        end, { desc = "Clear extra cursors" })
      end)
    end,
  },
}
