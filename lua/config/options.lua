-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.background = "light"
vim.opt.clipboard = "unnamedplus"

if vim.g.vscode then
  -- Use the extension's clipboard bridge, not terminal escape sequences.
  if not vim.g.vscode_clipboard then
    vim.cmd("runtime vscode/clipboard.lua")
  end
  vim.g.clipboard = vim.g.vscode_clipboard
elseif vim.fn.executable("wl-copy") == 0 and vim.fn.executable("xclip") == 0 and vim.fn.executable("xsel") == 0 then
  -- WezTerm/tmux support OSC 52 copying, but not external clipboard reads.
  local clipboard = { {}, "v" }
  local function copy(register)
    local osc52 = require("vim.ui.clipboard.osc52").copy(register)
    return function(lines, regtype)
      clipboard = { vim.deepcopy(lines), regtype }
      osc52(lines, regtype)
    end
  end
  local function paste()
    return clipboard
  end
  vim.g.clipboard = {
    name = "OSC 52 (WezTerm/tmux)",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
