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

  local function bridge(mode, lhs, command)
    vim.keymap.set(mode, lhs, function()
      require("vscode").action(command)
    end, { desc = "VS Code: " .. command, nowait = false })
  end

  -- VS Code owns language services, pickers, diagnostics, and editor groups.
  bridge("n", "gr", "editor.action.goToReferences")
  bridge("n", "gI", "editor.action.goToImplementation")
  bridge("n", "gy", "editor.action.goToTypeDefinition")
  bridge("n", "gD", "editor.action.revealDeclaration")
  bridge("n", "grn", "editor.action.rename")
  bridge("n", "gra", "editor.action.quickFix")
  bridge("n", "grr", "editor.action.goToReferences")
  bridge("n", "gri", "editor.action.goToImplementation")
  bridge("n", "gK", "editor.action.triggerParameterHints")
  bridge("i", "<C-k>", "editor.action.triggerParameterHints")
  bridge({ "n", "x" }, "<leader>ca", "editor.action.quickFix")
  bridge("n", "<leader>cr", "editor.action.rename")
  bridge("n", "<leader>co", "editor.action.organizeImports")
  bridge("n", "<leader>cf", "editor.action.formatDocument")
  bridge("x", "<leader>cf", "editor.action.formatSelection")

  -- Quick Open includes recent files; Open Recent lists projects/workspaces.
  bridge("n", "<leader>ff", "workbench.action.quickOpen")
  bridge("n", "<leader>fr", "workbench.action.quickOpen")
  bridge("n", "<leader>fp", "workbench.action.openRecent")
  bridge("n", "<leader>fb", "workbench.action.showAllEditors")
  bridge("n", "<leader>,", "workbench.action.showAllEditors")
  bridge("n", "<leader>fn", "workbench.action.files.newUntitledFile")
  bridge("n", "<leader>sg", "workbench.action.findInFiles")
  bridge("n", "<leader>sG", "workbench.action.findInFiles")
  bridge("n", "<leader>sS", "workbench.action.showAllSymbols")
  bridge("n", "<leader>sk", "workbench.action.openGlobalKeybindings")
  bridge({ "n", "x" }, "<leader>sr", "workbench.action.replaceInFiles")

  bridge("n", "[b", "workbench.action.previousEditor")
  bridge("n", "]b", "workbench.action.nextEditor")
  bridge("n", "<leader>bb", "workbench.action.openPreviousRecentlyUsedEditorInGroup")
  bridge("n", "<leader>`", "workbench.action.openPreviousRecentlyUsedEditorInGroup")
  -- Native close operations are editor/group-scoped, not global buffer deletion.
  bridge("n", "<leader>bd", "workbench.action.closeActiveEditor")
  bridge("n", "<leader>bo", "workbench.action.closeOtherEditors")
  bridge("n", "]d", "editor.action.marker.next")
  bridge("n", "[d", "editor.action.marker.prev")
  bridge("n", "<leader>xx", "workbench.actions.view.problems")
  bridge("n", "<leader>gg", "workbench.view.scm")
  bridge("n", "<leader>gd", "git.openChange")
  bridge("n", "<leader>gl", "workbench.scm.history")
  bridge("n", "<leader>e", "workbench.view.explorer")

  bridge("n", "<C-Up>", "workbench.action.increaseViewHeight")
  bridge("n", "<C-Down>", "workbench.action.decreaseViewHeight")
  bridge("n", "<C-Left>", "workbench.action.decreaseViewWidth")
  bridge("n", "<C-Right>", "workbench.action.increaseViewWidth")
  vim.keymap.set("n", "<leader>w", "<C-w>", {
    remap = true, desc = "Windows", nowait = false,
  })
end

-- VS Code owns its editor layout; these window mappings are for terminal Neovim.
if not vim.g.vscode then
  local maximized_terminal
  vim.keymap.set({ "n", "t" }, "<S-Esc>", function()
    if maximized_terminal and maximized_terminal:buf_valid() then
      maximized_terminal:toggle()
    else
      maximized_terminal = Snacks.terminal.open(nil, {
        cwd = LazyVim.root(),
        count = 99, -- Separate from the regular Ctrl+/ terminal.
        win = { position = "float", width = 0, height = 0, border = "none" },
      })
    end
  end, { desc = "Toggle maximized terminal" })

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

  vim.keymap.set("n", "<C-w><C-q>", "<Nop>", { desc = "Prevent accidental Ctrl-held quit" })

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
