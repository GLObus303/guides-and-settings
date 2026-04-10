#!/bin/bash

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

deny() {
  jq -n --arg msg "$1" '{permission: "deny", user_message: $msg, agent_message: $msg}'
  exit 0
}

if [[ -z "$CMD" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

if echo "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)(\/|\.\.|~|\.\/\*)'; then
  deny "Blocked: Destructive rm command on broad path. Be more specific about what to delete."
fi

if echo "$CMD" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
  deny "Blocked: Force push detected. Use --force-with-lease if you must, or ask the user first."
fi

if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
  deny "Blocked: git reset --hard can lose uncommitted work. Stage or stash changes first."
fi

if echo "$CMD" | grep -qE 'git\s+clean\s+.*-f'; then
  deny "Blocked: git clean -f permanently deletes untracked files. Review with git clean -n first."
fi

if echo "$CMD" | grep -qiE 'drop\s+(database|schema)\s'; then
  deny "Blocked: DROP DATABASE/SCHEMA detected. This is irreversible."
fi

echo '{"permission":"allow"}'
exit 0
