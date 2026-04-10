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

if [[ "$FILE_PATH" != *"/db/entities/"* ]]; then
  echo '{}'
  exit 0
fi

if [[ "$FILE_PATH" == *"/enums/"* || "$FILE_PATH" != *.ts ]]; then
  echo '{}'
  exit 0
fi

TEXT=""
if [[ "$TOOL_NAME" == "StrReplace" ]]; then
  NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.newString // empty')
  if echo "$NEW_STRING" | grep -qE '@(Column|ManyToOne|OneToMany|OneToOne|ManyToMany|JoinColumn|JoinTable|Index|Unique|PrimaryColumn|PrimaryGeneratedColumn)'; then
    TEXT="Entity schema changed in $(basename "$FILE_PATH"). Remember to generate a migration:
  cd backend && yarn migration:generate -n DescriptiveName
Review the generated migration for unrelated changes before committing."
  fi
elif [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENTS=$(echo "$INPUT" | jq -r '.tool_input.contents // .tool_input.content // empty')
  if echo "$CONTENTS" | grep -qE '@(Column|ManyToOne|OneToMany|OneToOne|ManyToMany|JoinColumn|JoinTable|Index|Unique|PrimaryColumn|PrimaryGeneratedColumn)'; then
    TEXT="Entity schema may have changed in $(basename "$FILE_PATH"). Remember to generate a migration:
  cd backend && yarn migration:generate -n DescriptiveName
Review the generated migration for unrelated changes before committing."
  fi
fi

if [[ -z "$TEXT" ]]; then
  echo '{}'
  exit 0
fi

jq -n --arg c "$TEXT" '{additional_context: $c}'
exit 0
