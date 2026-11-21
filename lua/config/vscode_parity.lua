-- VS Code-only helpers for LazyVim keys (used by keymaps.lua and VS Code's which-key menu).
if not vim.g.vscode then
  return {}
end

local M = {}
local vscode = require("vscode")

-- Fallback for gc when Neovim has no commentstring for the language (keymaps.lua uses
-- Neovim's own comment operator otherwise). Toggles whole lines even for a characterwise
-- motion, and leaves all-blank ranges unchanged, like Neovim.
function M.comment_lines()
  local from, to = vim.api.nvim_buf_get_mark(0, "["), vim.api.nvim_buf_get_mark(0, "]")
  -- Like Neovim's vim/_comment.lua operator: "from" after "to" (an empty text object
  -- such as gci'' on '') means there is nothing to comment.
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    return
  end
  local first, last = from[1] - 1, to[1] - 1
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, first, last + 1, false)) do
    if line:find("%S") then
      M.comment_and_keep_cursor(first, last)
      return
    end
  end
end

-- Neovim's gc keeps the cursor's column number when it adds or removes "-- ".
-- VS Code's edit shifts the cursor with the text, so put it back once the edit has
-- reached Neovim. Skip it if focus, mode or line changed meanwhile.
function M.comment_and_keep_cursor(first, last)
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local pos = vim.fn.getcurpos() -- Where Neovim's g@ left the cursor (with offset/curswant).
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local before_len = #vim.fn.getline(pos[2])
  local function restore()
    if vim.api.nvim_get_current_win() ~= win or vim.api.nvim_win_get_buf(win) ~= buf then
      return
    end
    if vim.fn.mode() ~= "n" or vim.fn.line(".") ~= pos[2] then
      return
    end
    -- Only undo the sync's shift: the cursor must be where g@ left it, or moved by exactly
    -- the length the comment marker added/removed. Anything else is a motion typed meanwhile.
    local col = vim.fn.col(".")
    local shifted = math.max(1, pos[3] + #vim.fn.getline(pos[2]) - before_len)
    if col ~= pos[3] and col ~= shifted then
      return
    end
    vim.fn.setpos(".", pos)
  end
  vscode.action("editor.action.commentLine", {
    range = { first, last },
    callback = function(err)
      if err then
        return
      end
      if vim.api.nvim_buf_get_changedtick(buf) ~= tick then
        return restore()
      end
      -- The edit hasn't synced to Neovim yet: restore right after it does.
      local active = true
      vim.defer_fn(function()
        active = false
      end, 1000)
      vim.api.nvim_buf_attach(buf, false, {
        on_lines = function()
          if active then
            active = false
            vim.schedule(restore)
          end
          return true -- Detach.
        end,
      })
    end,
  })
end

-- Tab actions that ignore pins, like Snacks.bufdelete and bufferline's close commands.
-- VS Code's own Close Others/Left/Right skip pinned tabs.
function M.tabs(op)
  vscode.eval_async(
    [[
    const group = vscode.window.tabGroups.activeTabGroup;
    const tab = group.activeTab;
    if (!tab) return;
    if (args === 'pin') {
      await vscode.commands.executeCommand(
        tab.isPinned ? 'workbench.action.unpinEditor' : 'workbench.action.pinEditor');
      return;
    }
    const index = group.tabs.indexOf(tab);
    const tabs = args === 'other'
      ? vscode.window.tabGroups.all.flatMap(g => g.tabs).filter(t => t !== tab)
      : args === 'left' ? group.tabs.slice(0, index) : group.tabs.slice(index + 1);
    if (tabs.length) await vscode.window.tabGroups.close(tabs);
  ]],
    { args = op }
  )
end

local function visual_text()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end
  local text = table.concat(
    vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
      type = mode,
      exclusive = vim.o.selection == "exclusive",
    }),
    "\n"
  )
  -- The Visual mappings in keymaps.lua leave Visual mode by returning <Esc> themselves
  -- (feedkeys would queue it behind keys typed after the mapping).
  return text
end

-- kind = "word": literal whole-word search for the selection or the word under the cursor
-- (LazyVim grep_word). kind = "replace": search and replace, regex when empty and literal
-- when seeded from a selection (grug-far adds --fixed-strings for a Visual selection).
-- Every flag is set so toggles left on by an earlier search don't carry over.
function M.grep(kind)
  local selection = visual_text()
  local query = selection or (kind == "word" and vim.fn.expand("<cword>")) or ""
  if query:find("${", 1, true) then
    -- Find in Files would expand ${...} as a VS Code variable.
    vim.notify("Query contains ${…}; type it into the search box instead.")
    query = ""
  end
  local args = {
    query = query,
    isRegex = kind ~= "word" and selection == nil,
    matchWholeWord = kind == "word",
    isCaseSensitive = false,
    useExcludeSettingsAndIgnoreFiles = true,
    onlyOpenEditors = false,
    triggerSearch = query ~= "",
  }
  if kind == "replace" then
    args.replace = ""
  end
  vscode.action("workbench.action.findInFiles", { args = args })
end

-- Insert-mode Ctrl+D/U with the suggestion list open: page its docs (blink's
-- scroll_documentation), then give focus back to the editor so typing, Enter, Tab and Esc
-- keep working. VS Code can only page docs by focusing them. If the docs were hidden, VS
-- Code shows and focuses them on the next animation frame, so take focus back after that.
function M.page_suggest_docs(direction)
  vscode.eval_async(
    [[
    const refocus = 'workbench.action.focusActiveEditorGroup';
    // One runCommands batch: tested more reliable than separate awaited commands.
    await vscode.commands.executeCommand('runCommands', {
      commands: [
        'toggleSuggestionFocus',
        args === 'down' ? 'selectNextPageSuggestion' : 'selectPrevPageSuggestion',
        'toggleSuggestionFocus',
        refocus,
      ],
    });
    await new Promise((resolve) => setTimeout(resolve, 100));
    await vscode.commands.executeCommand(refocus);
  ]],
    { args = direction }
  )
end

-- LazyVim <leader>cR (Snacks.rename.rename_file): rename the *active editor's* file. The
-- prompt shows its path relative to the cwd (or its own folder if outside the cwd). A
-- WorkspaceEdit rename lets language servers update imports, like Snacks' LSP notify.
function M.rename_file()
  vscode.eval_async(
    [[
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.uri.toString() !== args.uri) return;
    const from = editor.document.uri;
    if (from.scheme !== 'file') {
      vscode.window.showInformationMessage('Rename File only works for files on disk.');
      return;
    }
    const file = from.fsPath;
    let root = args.cwd.replace(/\/+$/, '');
    if (!file.startsWith(root + '/')) root = file.slice(0, file.lastIndexOf('/'));
    const current = file.slice(root.length + 1);
    const value = await vscode.window.showInputBox({ prompt: 'New File Name', value: current });
    if (!value || value === current) return;
    const to = vscode.Uri.joinPath(vscode.Uri.file(root), value);
    const edit = new vscode.WorkspaceEdit();
    edit.renameFile(from, to, { overwrite: false });
    if (!(await vscode.workspace.applyEdit(edit))) {
      vscode.window.showErrorMessage('Could not rename to ' + to.fsPath);
    }
  ]],
    { args = { uri = vim.b.vscode_uri, cwd = vim.fn.getcwd() } }
  )
end

-- LazyVim <leader>cd: every diagnostic on the cursor line, from VS Code's language servers.
function M.line_diagnostics()
  vscode.eval_async(
    [[
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.uri.toString() !== args) return;
    const line = editor.selection.active.line;
    const items = vscode.languages.getDiagnostics(editor.document.uri)
      // Same filter as Neovim's line scope (vim/diagnostic.lua): a multi-line diagnostic
      // ending at column 0 of this line belongs to the previous line.
      .filter(d => d.range.start.line <= line && d.range.end.line >= line &&
        (d.range.start.line === d.range.end.line || d.range.end.line !== line ||
          d.range.end.character !== 0))
      .map(d => ({ label: d.message.split('\n')[0], detail: d.message, description: d.source }));
    if (items.length) await vscode.window.showQuickPick(items, { title: 'Line diagnostics' });
    else vscode.window.showInformationMessage('No diagnostics on this line.');
  ]],
    { args = vim.b.vscode_uri }
  )
end

return M
