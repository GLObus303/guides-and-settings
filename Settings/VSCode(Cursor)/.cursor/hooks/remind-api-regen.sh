#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$FILE_PATH" ]]; then
  echo '{}'
  exit 0
fi

if [[ -n "$CWD" && "$FILE_PATH" != /* ]]; then
  FILE_PATH="$CWD/$FILE_PATH"
fi

if [[ "$FILE_PATH" != *"/backend/"* ]]; then
  echo '{}'
  exit 0
fi

IS_DTO=false
IS_CONTROLLER=false

if [[ "$FILE_PATH" == *".dto.ts" || "$FILE_PATH" == *"/dto/"* || "$FILE_PATH" == *"/dtos/"* ]]; then
  IS_DTO=true
fi

if [[ "$FILE_PATH" == *".controller.ts" ]]; then
  IS_CONTROLLER=true
fi

if [[ "$IS_DTO" == false && "$IS_CONTROLLER" == false ]]; then
  echo '{}'
  exit 0
fi

TEXT=""
if [[ "$TOOL_NAME" == "StrReplace" ]]; then
  NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.newString // empty')
  if echo "$NEW_STRING" | grep -qE '@(ApiField|ApiProperty|ApiResponse|Get|Post|Put|Patch|Delete)\b'; then
    TEXT="API surface changed in $(basename "$FILE_PATH"). After you are done with changes:
  1. cd backend && yarn build
  2. cd frontend && yarn generate-api
  3. Update frontend imports from @momence/api-* as needed"
  fi
elif [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENTS=$(echo "$INPUT" | jq -r '.tool_input.contents // .tool_input.content // empty')
  if echo "$CONTENTS" | grep -qE '@(ApiField|ApiProperty|ApiResponse|Get|Post|Put|Patch|Delete)\b'; then
    TEXT="API surface may have changed in $(basename "$FILE_PATH"). After you are done with changes:
  1. cd backend && yarn build
  2. cd frontend && yarn generate-api
  3. Update frontend imports from @momence/api-* as needed"
  fi
fi

if [[ -z "$TEXT" ]]; then
  echo '{}'
  exit 0
fi

jq -n --arg c "$TEXT" '{additional_context: $c}'
exit 0
