# Snippets

[**<- Back to main**](README.md)

You can find them in **Preferences > User Snippets**, they are separated into files per each language so they must be opened one by one yet the similar languages are identical.

## CSS/SASS

```
{
	"Anon func css": {
		"prefix": "anfn",
		"body": "${({ $1 }) => $0};",
		"description": "Anon func for styled comp"
	},
	"Ternary": {
		"prefix": "ter",
		"body": "$1 ? $2 : $0",
		"description": "Ternary"
	},
	"Flex center": {
		"prefix": "flexcen",
		"body": "display: flex; justify-content: center; align-items: center;",
		"description": "Centered flex"
	}
}
```

## JavaScript/TypeScript/TypeScriptReact

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
		"body": [
			"const $1 = styled.${2:div}`",
			"$0",
			"`;"
		],
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
	"useDispatch": {
		"prefix": "used",
		"body": "const dispatch = useDispatch();$0",
		"description": "useDispatch"
	},
	"useSelector": {
		"prefix": "uses",
		"body": "const $1 = useSelector($2);$0",
		"description": "useDispatch"
	},
	"Prescription for test": {
		"prefix": "dtest",
		"body": [
			"import { $3 } from '..$4';",
			"describe('$TM_FILENAME$0', () => {",
			"it('should $2', () => {",
			"expect($3()).toEqual();",
			"});",
			"});"
		],
		"description": "Prescription for test"
	},
}
```
