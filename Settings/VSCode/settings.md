# Settings

[**<- Back to main**](README.md)

**Paste to JSON settings in VSCode - open with `cmd + shift + p` ( `ctrl + shift + p` ) and by typing `Preferences: Open Settings (JSON)`**

Some of those settings are tied to [Extensions](extensions.md).

```
{
  "workbench.iconTheme": "vscode-icons",
  "workbench.colorTheme": "Atom One Dark",
  "workbench.activityBar.visible": false,
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "breadcrumbs.enabled": true,
  "workbench.editorAssociations": [
    {
      "viewType": "default",
      "filenamePattern": "git-rebase-todo"
    }
  ],
  // "workbench.editor.enablePreview": false,

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
  "explorer.compactFolders": false,

  // Formatter settings
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  // "editor.formatOnSaveMode": "modifications"

  // ESLint Settings
  "eslint.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },

  // Tailwind
  "editor.quickSuggestions": {
    "strings": true
  },

  // Other
 
  "files.watcherExclude": {
    "/.git/objects/**": true,
    "/.git/subtree-cache/**": true,
    "/node_modules/*/**": true
  },
  "sync.gist": "7c861aa9b54c66a429cc816310a8589e",
  "sync.autoUpload": true,

  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.preferences.importModuleSpecifier": "relative",
  "javascript.preferences.importModuleSpecifier": "relative",
  "tabnine.experimentalAutoImports": true,
  "svg.preview.mode": "svg",
  "extensions.ignoreRecommendations": true,
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": false,
}
```
