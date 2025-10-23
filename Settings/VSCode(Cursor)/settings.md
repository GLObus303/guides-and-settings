# Settings

[**<- Back to main**](../../README.md)

**Paste to JSON settings in VSCode - open with `cmd + shift + p` ( `ctrl + shift + p` ) and by typing `Preferences: Open Settings (JSON)`**

Some of those settings are tied to [Extensions](extensions.md).

```
{
  // Occasional
  "editor.folding": false,

  //Config
  "workbench.colorTheme": "Atom One Dark",
  "workbench.iconTheme": "vscode-icons",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.statusBar.visible": false,
  "workbench.activityBar.location": "hidden",
  "workbench.layoutControl.enabled": false,
  "window.commandCenter": false,
  "workbench.editorAssociations": {
    "git-rebase-todo": "default"
  },
  "window.newWindowDimensions": "fullscreen",
  // "workbench.editor.enablePreview": false,

  "explorer.openEditors.visible": 0,
  "explorer.confirmDragAndDrop": false,
  "explorer.confirmDelete": false,
  "explorer.compactFolders": false,
  "explorer.confirmPasteNative": false,

  "editor.gotoLocation.multipleDeclarations": "goto",
  "editor.gotoLocation.multipleDefinitions": "goto",
  "editor.gotoLocation.multipleImplementations": "goto",
  "editor.gotoLocation.multipleReferences": "goto",
  "editor.gotoLocation.multipleTypeDefinitions": "goto",
  "editor.accessibilitySupport": "off",
  "editor.tabSize": 2,
  "editor.wordWrap": "on",
  "editor.minimap.enabled": false,
  "editor.overviewRulerBorder": true,
  "editor.hideCursorInOverviewRuler": true,
  "editor.renderLineHighlight": "gutter",
  "editor.renderWhitespace": "none",
  "editor.guides.indentation": false,
  "editor.inlineSuggest.enabled": true,
  "editor.snippetSuggestions": "inline",
  "editor.hover.delay": 500,
  "editor.quickSuggestionsDelay": 500,

  // Formatter settings
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // // ESLint Settings
  "eslint.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
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
  "git.openRepositoryInParentFolders": "never",

  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.preferences.importModuleSpecifier": "relative",
  "javascript.preferences.importModuleSpecifier": "relative",
  "vsicons.dontShowNewVersionMessage": true,
```

Personal, and probably useless for most:

```
  "[go]": {
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "golang.go"
  },

  // Playwright
  "playwright.reuseBrowser": false,
  "playwright.showTrace": true,
  "playwright.env": {
    "env": "dev",
    "siteAndLanguage": "monster.com",
    // "branch": "master", // "master", // mnextv2-71236
    "branch": "master"
    // "routing": "jobs-search-ui=test-mbl-attribution", //profiles-profile-app-service=mnextv2-73226 //"jobs-search-ui=mnextv2-71134-mplus-ingestion",
    // "routing": "profiles-profile-app-service=mnextv2-81044",
    // "browsers": "chromium-desktop",
    // "browsers": "safari-desktop,firefox-desktop"
    // "PWDEBUG": "console",
    // "proxy": "http://localhost:8080"
  },

  // Sonar
  "sonarlint.rules": {
    "typescript:S909": {
      "level": "on"
    },
    "javascript:S6774": {
      "level": "off"
    },
    "typescript:S6606": {
      "level": "off"
    },
    "typescript:S6772": {
      "level": "off"
    },
    "typescript:S6479": {
      "level": "off"
    }
  },
  "sonarlint.connectedMode.connections.sonarqube": [],
  "sonarlint.output.showVerboseLogs": true,
  "sonarlint.disableTelemetry": true,

  // Other
  "files.watcherExclude": {
    "/.git/objects/**": true,
    "/.git/subtree-cache/**": true,
    "/node_modules/*/**": true
  },
  "security.workspace.trust.untrustedFiles": "open",
  "security.promptForLocalFileProtocolHandling": false,

  "svg.preview.mode": "svg",
  "extensions.ignoreRecommendations": true,
  "cSpell.userWords": [
    "Bugsnag",
    "bulletpoints",
    "Ethnicities",
    "EXTRACURRICULARS",
    "flowtype",
    "GSAP",
    "Hubspot",
    "noopener",
    "noreferrer",
    "onedrive",
    "overscan",
    "pageview",
    "persistor",
    "Strapi",
    "supabase",
    "testid",
    "trpc",
    "Whitelabel"
  ],

  "go.toolsManagement.autoUpdate": true,
  "cSpell.enabledNotifications": {
    "Average Word Length too Long": false,
    "Lines too Long": false,
    "Maximum Word Length Exceeded": false
  }
}

```
