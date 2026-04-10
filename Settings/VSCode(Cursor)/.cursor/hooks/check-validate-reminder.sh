#!/bin/bash

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  echo '{}'
  exit 0
fi

if grep -qF "Consider running /validate" "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo '{}'
  exit 0
fi

EDIT_COUNT=$(grep -cE '"name":"(Write|StrReplace)"' "$TRANSCRIPT_PATH" 2>/dev/null || true)
if ! [[ "$EDIT_COUNT" =~ ^[0-9]+$ ]]; then
  EDIT_COUNT=0
fi

VALIDATE_USED=$(grep -cE '/validate|review-reuse|review-backend|review-frontend|review-typeorm|review-robustness|review-ai-agent|review-security' "$TRANSCRIPT_PATH" 2>/dev/null || true)
if ! [[ "$VALIDATE_USED" =~ ^[0-9]+$ ]]; then
  VALIDATE_USED=0
fi

if [[ "$EDIT_COUNT" -ge 5 && "$VALIDATE_USED" -eq 0 ]]; then
  MSG="You made $EDIT_COUNT file edits but have not run /validate or review agents. Consider running /validate before finishing to catch common PR feedback patterns (reuse opportunities, missing manager params, styled components, deprecated TypeORM methods, etc.)."
  jq -n --arg m "$MSG" '{followup_message: $m}'
  exit 0
fi

echo '{}'
exit 0
