#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$FILE_PATH" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

if [[ -n "$CWD" && "$FILE_PATH" != /* ]]; then
  FILE_PATH="$CWD/$FILE_PATH"
fi

deny() {
  jq -n --arg msg "$1" '{permission: "deny", user_message: $msg, agent_message: $msg}'
  exit 0
}

if [[ "$FILE_PATH" == *"/libs/api/src/generated/"* ]]; then
  deny "Blocked: $FILE_PATH is a generated API file. Run 'yarn generate-api' instead of editing directly."
fi

if [[ "$FILE_PATH" == *"yarn.lock"* || "$FILE_PATH" == *"package-lock.json"* ]]; then
  deny "Blocked: $FILE_PATH is a lock file. Use yarn add/remove to modify dependencies."
fi

if [[ "$(basename "$FILE_PATH")" == .env* && "$(basename "$FILE_PATH")" != ".env.example" && "$(basename "$FILE_PATH")" != ".env.sample" ]]; then
  deny "Blocked: $FILE_PATH may contain secrets. Edit .env files manually."
fi

if [[ "$FILE_PATH" == *"/dist/"* || "$FILE_PATH" == *"/build/"* || "$FILE_PATH" == *"/.next/"* ]]; then
  deny "Blocked: $FILE_PATH is compiled output. Edit source files instead."
fi

echo '{"permission":"allow"}'
exit 0
