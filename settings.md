# Settings

**Paste to JSON settings in VSCode - open with `cmd + shift + p` ( `ctrl + shift + p` ) and by typing `Preferences: Open Settings (JSON)`**

Some of those settings are tied to [Extensions](extensions.md).

```
{
  "workbench.iconTheme": "vscode-icons",
  "workbench.colorTheme": "Atom One Dark",
  "workbench.activityBar.visible": false,
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "breadcrumbs.enabled": false,
  "window.zoomLevel": 0,

  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "telemetry.enableTelemetry": false,
  "editor.minimap.enabled": false,
  "editor.folding": false,
  "editor.overviewRulerBorder": true,
  "editor.hideCursorInOverviewRuler": true,
  "editor.renderIndentGuides": false,
  "editor.renderLineHighlight": "gutter",
  "editor.renderWhitespace": "none",
  "editor.multiCursorModifier": "alt",

  "explorer.openEditors.visible": 0,
  "explorer.confirmDragAndDrop": false,
  "explorer.confirmDelete": false,

  // Formatter settings
  "editor.formatOnSave": true,

  // ESLint Settings
  "eslint.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },

  // Other
  "gitlens.advanced.messages": {
    "suppressShowKeyBindingsNotice": true
  },
  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "files.watcherExclude": {
    "/.git/objects/**": true,
    "/.git/subtree-cache/**": true,
    "/node_modules/*/**": true
  }
}
```
