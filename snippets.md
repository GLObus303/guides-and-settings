# Snippets

[**<- Back to main**](README.md)

You can find them in **Preferences > User Snippets**, they are separated into files per each language so they must be opened one by one. Recently, I have started using global settings which is just much more convenient. 

- Some of these settings might be project-related and I do recommend you trying to think of ways to automate your day-to-day proccesses.

## global.code-snippets

```
{
  "Props": {
    "prefix": "prs",
    "body": "$1={$1}$0",
    "description": "Props snippet"
  },
  "Props same": {
    "prefix": "prp",
    "body": "$1={$2}$0",
    "description": "Same Props snippet"
  },
  "Import styled": {
    "prefix": "ims",
    "body": "import styled from 'styled-components';",
    "description": "Import styled components"
  },
  "Styled template div": {
    "prefix": "scs",
    "body": ["const $1 = styled.${2:div}`", "$0", "`;"],
    "description": "Styled component template"
  },
  "Ternary": {
    "prefix": "ter",
    "body": "$1 ? $2 : $0",
    "description": "Ternary"
  },
  "Translation": {
    "prefix": "utrans",
    "body": "const [t] = useTranslation('$0')",
    "description": "Ternary"
  },
  "JSX translation": {
    "prefix": "jtr",
    "body": "{t('$0')}",
    "description": "JSX translation"
  },
  "Type function return void": {
    "prefix": "anfv",
    "body": "($1)=>${2:void}$0",
    "description": "Type function return void"
  },
  "Prescription for test": {
    "prefix": "dtest",
    "body": [
      "import { $3 } from '..$4';",
      "describe('${TM_FILENAME_BASE/js|ts|tsx|test|[.]//gi}$0', () => {",
      "it('should $2', () => {",
      "expect($3()).toEqual();",
      "});",
      "});"
    ],
    "description": "Prescription for test"
  },
  "useDispatch": {
    "prefix": "used",
    "body": "const dispatch = useDispatch();$0",
    "description": "useDispatch"
  },
  "useSelector": {
    "prefix": "uses",
    "body": "const $1 = useSelector($2);$0",
    "description": "useSelector"
  },
  "useLanguage": {
    "prefix": "usel",
    "body": [
      "const {languageTag} = useLanguage();$1",
      "const {localize} = useLocalization();$0"
    ]
  },
  "type": {
    "prefix": "type",
    "body": [
      "type ${TM_FILENAME_BASE/js|ts|tsx|test|[.]//gi}Props = {",
      "$0",
      "}"
    ]
  },
  "fc": {
    "prefix": "fc",
    "body": [
      "type ${TM_FILENAME_BASE/js|ts|tsx|test|[.]//gi}Props = {",
      "$0",
      "}",
      "",
      "export const ${TM_FILENAME_BASE/js|ts|tsx|test|[.]//gi}: React.FC<${TM_FILENAME_BASE/js|ts|tsx|test|[.]//gi}Props>"
    ]
  },
  "snap": {
    "prefix": "snap",
    "body": "expect(${0:container}).toMatchSnapshot();"
  },
  "theme": {
    "prefix": "theme",
    "body": ["@include themed() {", "$0$TM_SELECTED_TEXT", "}"]
  },
  "color": {
    "prefix": "col",
    "body": "t('$0$TM_SELECTED_TEXT')"
  },
  "white": {
    "prefix": "whi",
    "body": "t('color--white')"
  }
}
```
