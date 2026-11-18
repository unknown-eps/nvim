return {
  "hong4rc/copy-path.nvim",
  event = "VeryLazy",
  vscode = true,
  opts = {},
  config = function(_, opts)
    local cp = require("copy-path")
    cp.setup(opts)

    if vim.g.vscode then
      -- Snacks is installed even in VS Code, so the plugin's auto-detection
      -- would choose a Neovim floating picker. Use VS Code's vim.ui bridge.
      cp.pick = function()
        local items = {}
        for kind, resolver in pairs(cp.resolvers()) do
          local value = resolver.fn()
          if value and value ~= "" then
            items[#items + 1] = { kind = kind, label = resolver.label, value = value }
          end
        end
        table.sort(items, function(a, b)
          return a.label < b.label
        end)
        vim.ui.select(items, {
          prompt = "Copy Path:",
          format_item = function(item)
            return item.label .. ": " .. item.value
          end,
        }, function(item)
          if item then
            cp.copy(item.kind)
          end
        end)
      end
    end
  end,
}
