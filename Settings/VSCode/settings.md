# Settings

[**<- Back to main**](README.md)

**Paste to JSON settings in VSCode - open with `cmd + shift + p` ( `ctrl + shift + p` ) and by typing `Preferences: Open Settings (JSON)`**

Some of those settings are tied to [Extensions](extensions.md).

```
{
  // Testing
  "editor.gotoLocation.multipleDeclarations": "goto",
  "editor.gotoLocation.multipleDefinitions": "goto",
  "editor.gotoLocation.multipleImplementations": "goto",
  "editor.gotoLocation.multipleReferences": "goto",
  "editor.gotoLocation.multipleTypeDefinitions": "goto",

  // Basic setup
  "workbench.colorTheme": "Atom One Dark",
  "workbench.iconTheme": "vscode-icons",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "workbench.activityBar.visible": false,
  "window.commandCenter": false,
  "workbench.layoutControl.enabled": false,
  "workbench.editorAssociations": {
    "git-rebase-todo": "default"
  },
  "window.newWindowDimensions": "fullscreen",
  // "workbench.editor.enablePreview": false,

  "explorer.openEditors.visible": 0,
  "explorer.confirmDragAndDrop": false,
  "explorer.confirmDelete": false,
  "explorer.compactFolders": false,

  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "editor.minimap.enabled": false,
  "editor.overviewRulerBorder": true,
  "editor.hideCursorInOverviewRuler": true,
  "editor.renderLineHighlight": "gutter",
  "editor.renderWhitespace": "none",
  "editor.guides.indentation": false,
  "editor.inlineSuggest.enabled": true,
  "editor.snippetSuggestions": "top",

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

  // // ESLint Settings
  "eslint.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },

  // Tailwind
  "editor.quickSuggestions": {
    "strings": true
  },

  // Git/GitLens
  "gitlens.hovers.currentLine.over": "line",
  "gitlens.codeLens.enabled": false,
  "gitlens.statusBar.enabled": false,
  "git.mergeEditor": false,

  // Other
  "files.watcherExclude": {
    "/.git/objects/**": true,
    "/.git/subtree-cache/**": true,
    "/node_modules/*/**": true
  },
  "security.workspace.trust.untrustedFiles": "open",

  "svg.preview.mode": "svg",
  "extensions.ignoreRecommendations": true,

  // Occasional
  "editor.folding": false,

  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.preferences.importModuleSpecifier": "relative",
  "javascript.preferences.importModuleSpecifier": "relative",
}

```
