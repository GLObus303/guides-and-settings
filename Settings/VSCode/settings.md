# Settings

[**<- Back to main**](README.md)

**Paste to JSON settings in VSCode - open with `cmd + shift + p` ( `ctrl + shift + p` ) and by typing `Preferences: Open Settings (JSON)`**

Some of those settings are tied to [Extensions](extensions.md).

```
{
  "http.proxySupport": "off",
  "workbench.iconTheme": "vscode-icons",
  "workbench.colorTheme": "Atom One Dark",
  "workbench.activityBar.visible": false,
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "breadcrumbs.enabled": true,
  "workbench.editorAssociations": {
    "git-rebase-todo": "default"
  },
  // "workbench.editor.enablePreview": false,

  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "telemetry.enableTelemetry": false,
  "editor.minimap.enabled": false,
  "editor.overviewRulerBorder": true,
  "editor.hideCursorInOverviewRuler": true,
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
  "[go]": {
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "golang.go"
  },
  // "editor.formatOnSaveMode": "modifications",

  // // ESLint Settings
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

  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.preferences.importModuleSpecifier": "relative",
  "javascript.preferences.importModuleSpecifier": "relative",
  "tabnine.experimentalAutoImports": true,
  "svg.preview.mode": "svg",
  "extensions.ignoreRecommendations": true,
  "security.workspace.trust.untrustedFiles": "open",
  "gitlens.hovers.currentLine.over": "line",
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": false,
  "editor.guides.indentation": false,
  "editor.folding": false
}
```
