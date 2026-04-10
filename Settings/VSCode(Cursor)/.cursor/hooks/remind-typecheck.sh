#!/bin/bash

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  echo '{}'
  exit 0
fi

if grep -qF "Verify types before finishing" "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo '{}'
  exit 0
fi

FRONTEND_EDITS=$(grep -oE '"path":"[^"]*frontend/(apps|libs)/[^"]*\.(ts|tsx)"' "$TRANSCRIPT_PATH" 2>/dev/null || true)
if [[ -z "$FRONTEND_EDITS" ]]; then
  echo '{}'
  exit 0
fi

TSC_RAN=$(grep -cE 'tsc --noEmit|type-check|npx tsc' "$TRANSCRIPT_PATH" 2>/dev/null || true)
if ! [[ "$TSC_RAN" =~ ^[0-9]+$ ]]; then
  TSC_RAN=0
fi

if [[ "$TSC_RAN" -gt 0 ]]; then
  echo '{}'
  exit 0
fi

APPS=""
echo "$FRONTEND_EDITS" | grep -q "host-dashboard" && APPS="$APPS host-dashboard"
echo "$FRONTEND_EDITS" | grep -q "checkout-pages" && APPS="$APPS checkout-pages"
echo "$FRONTEND_EDITS" | grep -q "admin-panel" && APPS="$APPS admin-panel"
echo "$FRONTEND_EDITS" | grep -q "corporate-dashboard" && APPS="$APPS corporate-dashboard"
echo "$FRONTEND_EDITS" | grep -q "micro-apps" && APPS="$APPS micro-apps"
echo "$FRONTEND_EDITS" | grep -q "on-demand" && APPS="$APPS on-demand"
echo "$FRONTEND_EDITS" | grep -q "workouts-wod" && APPS="$APPS workouts-wod"
echo "$FRONTEND_EDITS" | grep -q "frontend/libs" && APPS="$APPS host-dashboard"

APPS=$(echo "$APPS" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

if [[ -z "$APPS" ]]; then
  echo '{}'
  exit 0
fi

CMDS=""
for APP in $APPS; do
  CMDS="$CMDS
  cd frontend && npx tsc --noEmit -p apps/${APP}/tsconfig.json"
done

MSG="Frontend files were edited but tsc was not run. Verify types before finishing:$(echo "$CMDS")"
jq -n --arg m "$MSG" '{followup_message: $m}'
exit 0
