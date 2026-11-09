-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local group = vim.api.nvim_create_augroup("mode_line_numbers", { clear = true })
local function update_numbers(event)
  -- VS Code's editable documents use acwrite; still skip terminals and panels.
  if vim.bo.buftype ~= "" and not (vim.g.vscode and vim.bo.buftype == "acwrite") then
    return
  end
  local insert = vim.fn.mode():sub(1, 1) == "i"
  if event and event.event == "InsertEnter" then
    insert = true
  elseif event and event.event == "InsertLeave" then
    insert = false
  end
  -- vscode-neovim also synchronizes these options with its active editor.
  vim.wo.number = true
  vim.wo.relativenumber = not insert
  if vim.g.vscode then
    -- Update the actual VS Code editor; do not depend on delayed option sync.
    require("vscode").eval_async([[
      const editor = vscode.window.activeTextEditor;
      if (!editor || (args.uri && editor.document.uri.toString() !== args.uri)) return;
      editor.options.lineNumbers = args.insert
        ? vscode.TextEditorLineNumbersStyle.On
        : vscode.TextEditorLineNumbersStyle.Relative;
    ]], { args = { insert = insert, uri = vim.b.vscode_uri } })
  end
end
vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave", "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = update_numbers,
  desc = "Absolute numbers in Insert mode, relative otherwise",
})
update_numbers()

if vim.g.vscode then
  local mode_group = vim.api.nvim_create_augroup("vscode_mode_name", { clear = true })
  local previous_color
  local function update_mode_name(event)
    local mode = event and event.match:match(":(.*)$") or vim.api.nvim_get_mode().mode
    local first = mode:sub(1, 1)
    local name = "normal"
    if first == "i" then
      name = "insert"
    elseif first == "R" then
      name = "replace"
    elseif first == "v" or first == "V" or first == "\22"
      or first == "s" or first == "S" or first == "\19" then
      name = "visual"
    end
    local label = name:upper()
    if first == "c" then
      label = "COMMAND"
    elseif first == "V" then
      label = "VISUAL LINE"
    elseif first == "\22" then
      label = "VISUAL BLOCK"
    elseif first == "s" or first == "S" or first == "\19" then
      label = "SELECT"
    end
    vim.o.statusline = label
    if name ~= previous_color then
      previous_color = name
      require("vscode").action("nvim-theme." .. name)
    end
  end
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = mode_group,
    pattern = "*",
    callback = update_mode_name,
    desc = "Show the current mode name in VS Code",
  })
  vim.schedule(function()
    update_mode_name()
  end)
end
