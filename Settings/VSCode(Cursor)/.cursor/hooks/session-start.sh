#!/bin/bash

INPUT=$(cat)
ROOT=$(echo "$INPUT" | jq -r '.workspace_roots[0] // empty')
if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
fi

cd "$ROOT" 2>/dev/null || {
  echo '{"continue":true}'
  exit 0
}

TMP=$(mktemp)
{
  echo "=== Session Context ==="
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "Branch: $BRANCH"

  if command -v gh &>/dev/null; then
    PR_INFO=$(gh pr view "$BRANCH" --json number,title,state,reviewDecision,statusCheckRollup 2>/dev/null)
    if [[ -n "$PR_INFO" ]]; then
      PR_NUM=$(echo "$PR_INFO" | jq -r '.number')
      PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
      PR_STATE=$(echo "$PR_INFO" | jq -r '.state')
      PR_REVIEW=$(echo "$PR_INFO" | jq -r '.reviewDecision // "PENDING"')
      echo "PR #$PR_NUM: $PR_TITLE [$PR_STATE, review: $PR_REVIEW]"
    fi
  fi

  CHANGED=$(git diff --stat HEAD 2>/dev/null | tail -1)
  STAGED=$(git diff --cached --stat 2>/dev/null | tail -1)
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  if [[ -n "$CHANGED" ]]; then
    echo "Working tree: $CHANGED"
  fi
  if [[ -n "$STAGED" ]]; then
    echo "Staged: $STAGED"
  fi
  if [[ "$UNTRACKED" -gt 0 ]]; then
    echo "Untracked files: $UNTRACKED"
  fi

  DIVERGED=$(git log main..HEAD --oneline 2>/dev/null | head -5)
  if [[ -n "$DIVERGED" ]]; then
    echo ""
    echo "Commits ahead of main:"
    echo "$DIVERGED"
  fi

  echo "======================"

  if command -v gh &>/dev/null; then
    USERNAME=$(gh api user --jq '.login' 2>/dev/null)
    if [[ -n "$USERNAME" ]]; then
      TRACKER=""
      for DIR in "$HOME/.claude/projects/"*/memory; do
        if [[ -f "$DIR/processed_prs.md" ]]; then
          TRACKER="$DIR/processed_prs.md"
          break
        fi
      done
      if [[ -z "$TRACKER" ]]; then
        for DIR in "$HOME/.cursor/projects/"*/; do
          if [[ -f "$DIR/processed_prs.md" ]]; then
            TRACKER="$DIR/processed_prs.md"
            break
          fi
        done
      fi

      MERGED_PRS=$(gh pr list --repo Ribbon-Experiences/momence-monorepo \
        --author "$USERNAME" --state merged --limit 20 \
        --json number --jq '.[].number' 2>/dev/null)

      if [[ -n "$MERGED_PRS" && -n "$TRACKER" ]]; then
        UNPROCESSED=0
        while IFS= read -r PR_NUM; do
          if ! grep -q "#${PR_NUM}" "$TRACKER" 2>/dev/null; then
            UNPROCESSED=$((UNPROCESSED + 1))
          fi
        done <<< "$MERGED_PRS"

        if [[ "$UNPROCESSED" -gt 0 ]]; then
          echo ""
          echo "Skills improvement: $UNPROCESSED merged PR(s) with unprocessed review comments. Run /improve to learn from them."
        fi
      fi
    fi
  fi
} >"$TMP"

jq -n --rawfile ctx "$TMP" '{continue: true, additional_context: ($ctx | rtrimstr("\n"))}'
rm -f "$TMP"
exit 0
