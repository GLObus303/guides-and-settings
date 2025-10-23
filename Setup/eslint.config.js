import typescript from '@typescript-eslint/eslint-plugin';
import typescriptParser from '@typescript-eslint/parser';
import cssModules from 'eslint-plugin-css-modules';
import importPlugin from 'eslint-plugin-import';
import jsxA11y from 'eslint-plugin-jsx-a11y';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import jest from 'eslint-plugin-jest';
import disableAutofix from 'eslint-plugin-disable-autofix';
import globals from 'globals';
import nextVitals from 'eslint-config-next/core-web-vitals';

export default [
  // Global settings
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.es2021,
        ...globals.node,
      },
      ecmaVersion: 2021,
      sourceType: 'module',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },

  // TypeScript files configuration
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: {
        project: './tsconfig.json',
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    plugins: {
      '@typescript-eslint': typescript,
      'disable-autofix': disableAutofix,
    },
    rules: {
      // TypeScript-only rules (cannot be applied to JS files)
      'disable-autofix/@typescript-eslint/no-unnecessary-condition': 1, // Warn about unnecessary conditions, but disable autofix
      '@typescript-eslint/await-thenable': 2, // Disallow await statements that are not thenable, must be only applied to TS files
    },
  },

  // Test files configuration
  {
    files: ['**/*.test.{js,jsx,ts,tsx}'],
    plugins: {
      jest,
    },
    rules: {
      'no-unused-expressions': 0, // Allow unused expressions in tests
      '@typescript-eslint/no-unused-expressions': 0, // Allow unused expressions in tests
      'jest/no-focused-tests': 2, // Forbid focused tests
    },
  },

  // React and JSX files configuration
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    plugins: {
      react,
      'react-hooks': reactHooks,
      'jsx-a11y': jsxA11y,
      import: importPlugin,
      'css-modules': cssModules,
      '@typescript-eslint': typescript,
    },
    rules: {
      // React rules
      ...react.configs.recommended.rules,
      ...nextVitals.rules,
      'react/prop-types': 0, // Allow prop types to be optional
      'react/jsx-runtime': 0, // Use new JSX transform
      'react/react-in-jsx-scope': 0, // Use new JSX transform
      'react/display-name': 0, // Force displayName to be used for components
      'react/jsx-boolean-value': 2, // <Component someFlag={true} /> results to <Components someFlag />
      'react/self-closing-comp': 2, // Empty JSX tags will collapse. <div></div> results to <div/>
      'react/jsx-curly-brace-presence': 2, // Avoid having useless curly braces for string props
      'react/no-unused-prop-types': 2, // Forbid unused types for component props

      // React Hooks rules
      ...reactHooks.configs.recommended.rules,
      'react-hooks/exhaustive-deps': 0, // Allow missing dependencies in useEffect

      // General rules
      strict: [2, 'never'], // Avoid any unsafe functions that would not be allowed under strict mode
      'default-case': 0, // Allow switch without a default case
      'no-console': 2, // Forbid console logs
      'arrow-body-style': [2, 'as-needed'], // Remove all explicit returns that are not necessary
      'no-unneeded-ternary': [2, { defaultAssignment: false }], // Default ternary x ? x : 1 results to x || 1
      curly: 2, // Avoid single line ifs, force curly brace on the same line
      'newline-before-return': 2, // Add newline before every return
      eqeqeq: [2, 'always', { null: 'ignore' }], // force strict equality, except for null/undefined check
      'no-useless-return': 2, // Forbid all explicit returns that serve not purpose
      'no-irregular-whitespace': 2, // Silent guard from weird whitespace clashes in code
      'dot-notation': 2, // Force dot notation whether possible - Object['string'] results to object.string
      'no-nested-ternary': 2, // Forbid nesting of optional chaining which hinders readability
      'no-unsafe-optional-chaining': 2, // Forbid optional chaining when it could cause TypeError
      yoda: 2, // Forbid yoda conditions - if (1 === x) results to if (x === 1)
      'object-shorthand': 2, // Shorten objects - { someProp: someProp } result to {  someProp }
      'prefer-const': 2, // Force const declarations for variables that are not mutated
      'no-var': 2, // Forbid var declaration
      'spaced-comment': 2, // Force one whitespace after "//" comment

      'jsx-a11y/anchor-is-valid': 0, // Force anchor tag to have valid href attribute

      // Template and usage rules
      'no-template-curly-in-string': 0,
      'no-use-before-define': 0, // handled by TS
      'no-shadow': 0, // handled by TS
      'no-unused-vars': 0, // handled by TS

      // TypeScript rules that can be applied to JS files
      ...typescript.configs.recommended.rules,
      '@typescript-eslint/explicit-module-boundary-types': 0, // Allow functions without explicit return type
      '@typescript-eslint/no-explicit-any': 0, // Allows any type, does make sense in some places
      '@typescript-eslint/no-unused-vars': [
        2,
        {
          ignoreRestSiblings: true,
          args: 'all',
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrors: 'none',
        },
      ], // Forbid unused variables, except for the ones that start with "_"
      '@typescript-eslint/no-use-before-define': 2, // Variable must be declared before its use
      '@typescript-eslint/no-shadow': 2, // Forbid declaring variables that have duplicate names in the same scope
      '@typescript-eslint/no-var-requires': 0, // allow require
      '@typescript-eslint/no-empty-function': 0, // allow empty function

      // Import rules - matching original config
      'import/no-default-export': 0,
      'import/order': [
        1,
        {
          "groups": [
            ["builtin", "external"],
            ["internal", "parent", "sibling", "index"],
          ],
          "newlines-between": "always",
          "pathGroups": [
            {
              "pattern": "react",
              "group": "builtin",
              "position": "before",
            },
            {
              "pattern": "./**/*.{scss,css}",
              "group": "sibling",
              "position": "after",
            },
          ],
          "distinctGroup": false,
          "pathGroupsExcludedImportTypes": ["react", "scss"],
        },
      ], // Sort imports in groups, react first, then external. After a new line, components and lastly in the same group scss import
      'import/newline-after-import': 2, // Force a newline after imports
      'import/extensions': [
        0,
        'ignorePackages',
        {
          js: 'never',
          ts: 'never',
          tsx: 'never',
        },
      ], // Force extensions on imports apart from the JS/TS related ones
    },
  },
];
