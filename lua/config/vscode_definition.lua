local M = {}

function M.open()
  require("vscode").eval_async([[
    const source = vscode.window.activeTextEditor;
    if (!source) return;
    const selection = source.selection;
    const version = source.document.version;

    // Query only: never run a navigation/peek action in the source editor.
    const definitions = await vscode.commands.executeCommand(
      'vscode.executeDefinitionProvider', source.document.uri, selection.active
    );
    if (!definitions || definitions.length === 0) {
      vscode.window.showInformationMessage('No definition found.');
      return;
    }
    // Like multipleDefinitions: "goto", open one result without a peek widget.
    const definition = definitions[0];
    const uri = definition.targetUri || definition.uri;
    const range = definition.targetSelectionRange || definition.targetRange || definition.range;
    const document = await vscode.workspace.openTextDocument(uri);

    // Do not steal focus if the user moved while the language server was busy.
    if (vscode.window.activeTextEditor !== source ||
        !source.selection.isEqual(selection) || source.document.version !== version) return;

    // Beside may reuse a group; splitEditorRight starts an unawaited editor copy.
    // Create an empty right-hand group and wait for its extension-host identity.
    const existing = new Set(vscode.window.tabGroups.all);
    let subscription, timer, group;
    try {
      group = await new Promise((resolve, reject) => {
        const check = () => {
          const created = vscode.window.tabGroups.all.find(
            candidate => !existing.has(candidate) && candidate.isActive
          );
          if (created) resolve(created);
        };
        subscription = vscode.window.tabGroups.onDidChangeTabGroups(check);
        timer = setTimeout(() => reject(new Error('Definition split: new group did not become ready.')), 5000);
        vscode.commands.executeCommand('workbench.action.newGroupRight').then(check, reject);
      });
    } finally {
      subscription?.dispose();
      clearTimeout(timer);
    }

    // Explicit column prevents revealIfOpen/active-editor routing to the source.
    const target = await vscode.window.showTextDocument(document, {
      viewColumn: group.viewColumn,
      selection: new vscode.Range(range.start, range.start),
      preserveFocus: false,
      preview: false
    });
    target.revealRange(range, vscode.TextEditorRevealType.InCenterIfOutsideViewport);
  ]])
end

return M
