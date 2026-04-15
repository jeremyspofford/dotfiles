#!/usr/bin/env bash
# sync-cursor — initialize personal Cursor rules in a client/project repo
# Run from the project root.
set -euo pipefail

DOTFILES="$HOME/workspace/dotfiles"
CURSOR_RULE_SRC="$DOTFILES/scripts/templates/cursor-jeremy-context.mdc"
CURSOR_RULE_DST=".cursor/rules/jeremy-context.mdc"

if [ ! -f "$CURSOR_RULE_SRC" ]; then
  echo "Error: template not found at $CURSOR_RULE_SRC" >&2
  exit 1
fi

if [ -f "$CURSOR_RULE_DST" ]; then
  echo "Already exists: $CURSOR_RULE_DST (skipping)"
else
  mkdir -p .cursor/rules
  cp "$CURSOR_RULE_SRC" "$CURSOR_RULE_DST"
  echo "Created: $CURSOR_RULE_DST"
fi
