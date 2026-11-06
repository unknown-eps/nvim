-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

if vim.g.vscode then
  -- Let VS Code skip folded lines instead of revealing Neovim's hidden cursor.
  for key, direction in pairs({ j = "down", k = "up" }) do
    vim.keymap.set("n", key, function()
      require("vscode").action("cursorMove", {
        args = { to = direction, by = "wrappedLine", value = vim.v.count1 },
      })
    end, { desc = "Move " .. direction .. " by visible rows" })
  end

  local folds = {
    zc = { "editor.fold", "Collapse block" },
    zo = { "editor.unfold", "Expand block" },
    za = { "editor.toggleFold", "Toggle block folding" },
    zM = { "editor.foldAll", "Collapse all blocks" },
    zR = { "editor.unfoldAll", "Expand all blocks" },
  }
  for key, binding in pairs(folds) do
    vim.keymap.set("n", key, function()
      require("vscode").action(binding[1])
    end, { desc = binding[2] })
  end

  vim.keymap.set("n", "gh", function()
    require("vscode").action("editor.action.showHover", {
      args = { focus = "autoFocusImmediately" },
    })
  end, { desc = "Show and focus hover documentation" })

  vim.keymap.set("n", "<leader>wm", function()
    require("vscode").action("workbench.action.toggleMaximizeEditorGroup")
  end, { desc = "Toggle editor group maximization" })
end

-- VS Code owns its editor layout; these window mappings are for terminal Neovim.
if not vim.g.vscode then
  for _, key in ipairs({ "<C-~>", "<C-`>" }) do
    vim.keymap.set({ "n", "t" }, key, function()
      Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
    end, { desc = "Toggle terminal (Root Dir)" })
  end

  for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
    vim.keymap.set("n", key, "<Nop>", { desc = "Arrow movement disabled in Normal mode" })
  end

  vim.keymap.set("n", "<C-w>q", function()
    local splits = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative == "" then
        splits = splits + 1
      end
    end
    if splits > 1 then
      vim.api.nvim_win_close(0, false)
    else
      local buffers = vim.fn.getbufinfo({ buflisted = 1 })
      if #buffers > 1 then
        Snacks.bufdelete()
      else
        -- Close the last window/tab, exiting Neovim when nothing remains.
        vim.cmd("confirm quit")
      end
    end
  end, { desc = "Close split, buffer, or Neovim" })

  local function definition_in(layout)
    vim.lsp.buf.definition({
      on_list = function(result)
        if #result.items == 0 then
          return
        end
        -- Open the layout only after the server has returned a destination.
        vim.cmd(layout)
        vim.fn.setqflist({}, " ", result)
        vim.cmd("cfirst")
      end,
    })
  end

  vim.keymap.set("n", "<C-w>gd", function()
    definition_in("vsplit")
  end, { desc = "Definition in vertical split" })
end
