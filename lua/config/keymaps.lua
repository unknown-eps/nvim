-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

if vim.g.vscode then
  local vscode = require("vscode")
  local function action(mode, lhs, command, desc)
    vim.keymap.set(mode, lhs, function()
      vscode.action(command)
    end, { desc = desc })
  end

  -- Let VS Code skip folded lines instead of revealing Neovim's hidden cursor.
  -- Like LazyVim: visible rows without a count, real lines with a count.
  for key, direction in pairs({ j = "down", k = "up" }) do
    vim.keymap.set("n", key, function()
      vscode.action("cursorMove", {
        args = { to = direction, by = vim.v.count == 0 and "wrappedLine" or "foldedLine", value = vim.v.count1 },
      })
    end, { desc = "Move " .. direction .. " by visible rows" })
  end

  -- Neovim owns Ctrl+W (vscode-neovim maps <C-w>h/j/k/l/s/v/q/o/=/...).
  vim.keymap.set("n", "<C-w>gd", function()
    require("config.vscode_definition").open()
  end, { desc = "Definition in vertical split" })
  vim.keymap.set("n", "<C-w><C-q>", "<Nop>", { desc = "Prevent accidental Ctrl-held quit" })

  -- Normal-mode Ctrl+Space (sent here by keybindings.json): append after the cursor and
  -- open VS Code's suggestions, like terminal Neovim. with_insert runs the action once VS
  -- Code is in Insert mode; it enters before the cursor, so step right unless the line is
  -- empty (Normal mode can't sit past the last character).
  vim.keymap.set("n", "<C-Space>", function()
    local empty = vim.fn.col("$") == 1
    vscode.with_insert(function()
      local commands = empty and {} or { "cursorRight" }
      commands[#commands + 1] = "editor.action.triggerSuggest"
      vscode.action("runCommands", { args = { commands = commands } })
    end)
  end, { desc = "Append and show completions" })

  -- VS Code sends Normal-mode Space as <F35> (keybindings.json), so it also completes a
  -- pending <C-w>. <C-w><Space> opens the Window menu, like LazyVim's window hydra.
  vim.keymap.set("n", "<F35>", function()
    vscode.action("whichkey.show")
  end, { desc = "Which-key menu" })
  vim.keymap.set("n", "<C-w><F35>", function()
    vscode.action("runCommands", {
      args = { commands = { "whichkey.show", { command = "whichkey.triggerKey", args = "w" } } },
    })
  end, { desc = "Window menu" })
  -- vscode-neovim reports operator-pending as Normal, so Space arrives as <F35> there too.
  vim.keymap.set("o", "<F35>", "<Space>", { desc = "Space motion (e.g. d<Space>)" })

  -- gc/gcc: Neovim's own comment operator (as in terminal Neovim, with ts-comments for the
  -- commentstring). It edits Neovim's buffer synchronously and vscode-neovim syncs the edit
  -- to VS Code, so counts, dot-repeat, the cursor, blank lines and keys typed right after
  -- gc behave exactly as in terminal Neovim. vscode-neovim's own gc runs VS Code's comment
  -- commands asynchronously (block comments for characterwise motions, and keys queued
  -- after it can land first). If Neovim has no commentstring for this language, fall back
  -- to VS Code's commentLine.
  local function comment()
    if vim.bo.commentstring == "" then
      vim.go.operatorfunc = "v:lua.require'config.vscode_parity'.comment_lines"
      return "g@"
    end
    return require("vim._comment").operator()
  end
  vim.keymap.set({ "n", "x" }, "gc", comment, { expr = true, desc = "Toggle comment" })
  vim.keymap.set("n", "gcc", function()
    return comment() .. "_"
  end, { expr = true, desc = "Toggle comment line" })

  -- Arrows are disabled in Normal mode; multicursor.nvim's layer still maps Left/Right.
  for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
    vim.keymap.set("n", key, "<Nop>", { desc = "Arrow movement disabled in Normal mode" })
  end

  -- LazyVim's LSP keys. Drop Neovim's default gr* LSP maps (no LSP client here) so gr fires at once.
  for _, lhs in ipairs({ "grr", "gra", "grn", "gri", "grt", "grx" }) do
    for _, mode in ipairs({ "n", "x" }) do
      pcall(vim.keymap.del, mode, lhs)
    end
  end
  action("n", "gr", "editor.action.goToReferences", "References")
  action("n", "gI", "editor.action.goToImplementation", "Goto Implementation")
  action("n", "gy", "editor.action.goToTypeDefinition", "Goto T[y]pe Definition")
  action("n", "gD", "editor.action.revealDeclaration", "Goto Declaration")
  action("n", "gK", "editor.action.triggerParameterHints", "Signature Help")

  -- These take a count in LazyVim (2]d jumps two diagnostics): run the VS Code jump that
  -- many times, in order.
  local function action_count(lhs, command, desc)
    vim.keymap.set("n", lhs, function()
      local commands = {}
      for i = 1, vim.v.count1 do
        commands[i] = command
      end
      vscode.action("runCommands", { args = { commands = commands } })
    end, { desc = desc })
  end
  action_count("]d", "editor.action.marker.next", "Next Diagnostic")
  action_count("[d", "editor.action.marker.prev", "Prev Diagnostic")
  action_count("]h", "workbench.action.editor.nextChange", "Next Hunk")
  action_count("[h", "workbench.action.editor.previousChange", "Prev Hunk")
  action_count("]]", "editor.action.wordHighlight.next", "Next Reference")
  action_count("[[", "editor.action.wordHighlight.prev", "Prev Reference")
  -- keybindings.json sends Alt+N/Alt+P here so the count reaches Neovim.
  action_count("<A-n>", "editor.action.wordHighlight.next", "Next Reference")
  action_count("<A-p>", "editor.action.wordHighlight.prev", "Prev Reference")
  action("n", "]b", "workbench.action.nextEditor", "Next Buffer")
  action("n", "[b", "workbench.action.previousEditor", "Prev Buffer")
  action("n", "]B", "workbench.action.moveEditorRightInGroup", "Move buffer next")
  action("n", "[B", "workbench.action.moveEditorLeftInGroup", "Move buffer prev")

  -- Visual-mode Space reaches Neovim (which-key only handles Normal mode). Replace LazyVim's
  -- Snacks picker / formatter maps, which don't work inside VS Code.
  local parity = require("config.vscode_parity")
  -- Expr maps: read the selection, start the search, then return <Esc> so Visual mode
  -- ends before any keys typed after the mapping run.
  local function visual_grep(lhs, kind, desc)
    vim.keymap.set("x", lhs, function()
      parity.grep(kind)
      return "<Esc>"
    end, { expr = true, desc = desc })
  end
  visual_grep("<leader>sw", "word", "Search selection (whole word)")
  visual_grep("<leader>sW", "word", "Search selection (whole word)")
  visual_grep("<leader>sr", "replace", "Search and replace selection")
  action("x", "<leader>cf", "editor.action.formatSelection", "Format selection")
  -- LazyVim's Visual <leader>ghs stages just the selected lines (gitsigns with a range).
  -- Pass the lines explicitly and leave Visual mode, like gitsigns' ":" command does.
  -- (No Visual <leader>ghr: VS Code's revert command reverts whole hunks, which would
  -- discard changes outside the selection.)
  vim.keymap.set("x", "<leader>ghs", function()
    local l1, l2 = vim.fn.line("v"), vim.fn.line(".")
    vscode.action("git.stageSelectedRanges", { range = { math.min(l1, l2) - 1, math.max(l1, l2) - 1 } })
    return "<Esc>"
  end, { expr = true, desc = "Stage selected lines" })

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
end

-- VS Code owns its editor layout; these window mappings are for terminal Neovim.
if not vim.g.vscode then
  -- Normal-mode Ctrl+Space: append after the cursor and open completions, like VS Code's
  -- Ctrl+Space (Visual Ctrl+Space keeps flash's incremental selection; plugins/flash.lua).
  vim.keymap.set("n", "<C-Space>", "a<Cmd>lua require('blink.cmp').show()<CR>", {
    desc = "Append and show completions",
  })

  -- Match VS Code's documentation shortcut (replaces Vim's Select-mode gh).
  vim.keymap.set("n", "gh", function()
    vim.lsp.buf.hover()
  end, { desc = "Show hover documentation" })

  -- Noice hides documentation on cursor movement, but not on Escape.
  -- In terminal Neovim, Ctrl+[ sends the same key code as Escape.
  for _, mode in ipairs({ "n", "i", "s" }) do
    local escape = vim.fn.maparg("<Esc>", mode, false, true)
    vim.keymap.set(mode, "<Esc>", function()
      vim.schedule(function()
        local docs = package.loaded["noice.lsp.docs"]
        if docs then
          docs.on_close()
        end
      end)
      -- Keep LazyVim's search clearing and snippet cancellation.
      return escape.callback and escape.callback() or "<Esc>"
    end, { expr = true, desc = "Escape, clear hlsearch, and dismiss documentation" })
  end

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
