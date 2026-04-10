#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$FILE_PATH" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

if [[ -n "$CWD" && "$FILE_PATH" != /* ]]; then
  FILE_PATH="$CWD/$FILE_PATH"
fi

if [[ "$FILE_PATH" != *"/db/migrations/"* ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

deny() {
  jq -n --arg msg "$1" '{permission: "deny", user_message: $msg, agent_message: $msg}'
  exit 0
}

if [[ "$TOOL_NAME" == "StrReplace" ]]; then
  deny "Blocked: $FILE_PATH is a migration file. Migrations should be generated with 'yarn migration:generate', not hand-edited. Create a new migration instead."
fi

if [[ "$TOOL_NAME" == "Write" && -f "$FILE_PATH" ]]; then
  deny "Blocked: $FILE_PATH is an existing migration. Migrations should be generated with 'yarn migration:generate', not hand-edited. If you need changes, create a new migration."
fi

echo '{"permission":"allow"}'
exit 0
