#!/usr/bin/env bash
# install-cron.sh — install or update the Scout cron job on this machine
#
# Idempotent — safe to re-run. Re-running updates the schedule.
# Works on Linux (cron) and macOS (cron — launchd not used for simplicity).
#
# Usage:
#   ./install-cron.sh              # install with default schedule (6am daily)
#   ./install-cron.sh '0 */6 * * *'  # install with custom schedule
#   ./install-cron.sh remove       # remove the cron entry

set -euo pipefail

CRON_TAG="# scout-wiki"
RUNNER="$HOME/.claude/hooks/run-scout.sh"
DEFAULT_SCHEDULE="0 6 * * *"

# Handle 'remove' argument
if [ "${1:-}" = "remove" ]; then
  TMPFILE=$(mktemp)
  crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$TMPFILE" || true
  crontab "$TMPFILE"
  rm -f "$TMPFILE"
  echo "Scout cron removed."
  exit 0
fi

SCHEDULE="${1:-$DEFAULT_SCHEDULE}"

# Validate runner exists
if [ ! -f "$RUNNER" ]; then
  echo "Error: $RUNNER not found."
  echo "Make sure dotfiles are stowed: cd ~/workspace/dotfiles && stow claude"
  exit 1
fi
chmod +x "$RUNNER"

# Build and install cron entry
CRON_LINE="$SCHEDULE $RUNNER $CRON_TAG"
TMPFILE=$(mktemp)
crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$TMPFILE" || true
echo "$CRON_LINE" >> "$TMPFILE"
crontab "$TMPFILE"
rm -f "$TMPFILE"

echo "Scout cron installed on $(hostname):"
echo "  Schedule : $SCHEDULE"
echo "  Runner   : $RUNNER"
echo "  Log      : /tmp/scout.log"
echo ""
echo "Useful commands:"
echo "  View cron  : crontab -l | grep scout"
echo "  Watch log  : tail -f /tmp/scout.log"
echo "  Remove     : $0 remove"
echo "  Run now    : $RUNNER"
