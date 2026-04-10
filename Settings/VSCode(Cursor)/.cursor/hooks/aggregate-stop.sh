#!/bin/bash

INPUT=$(cat)
DIR="$(cd "$(dirname "$0")" && pwd)"
j1=$(echo "$INPUT" | bash "$DIR/check-validate-reminder.sh")
j2=$(echo "$INPUT" | bash "$DIR/remind-typecheck.sh")
f1=$(echo "$j1" | jq -r '.followup_message // empty')
f2=$(echo "$j2" | jq -r '.followup_message // empty')

if [[ -z "$f1" && -z "$f2" ]]; then
  echo '{}'
  exit 0
fi

jq -n --arg a "$f1" --arg b "$f2" '
  if ($a != "" and $b != "") then {followup_message: ($a + "\n\n" + $b)}
  elif ($a != "") then {followup_message: $a}
  elif ($b != "") then {followup_message: $b}
  else {} end
'
exit 0
