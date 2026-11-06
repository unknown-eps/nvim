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
  -- Leave terminals, help windows and plugin panels alone.
  if vim.bo.buftype ~= "" then
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
end
vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave", "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = update_numbers,
  desc = "Absolute numbers in Insert mode, relative otherwise",
})
update_numbers()
