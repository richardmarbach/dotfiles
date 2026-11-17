#!/bin/bash
set -euo pipefail

ENTRY='*/30 * * * * ~/.local/bin/auto-commit-notes.sh >> ~/.local/share/auto-commit-notes/auto-commit-notes.log 2>&1'

mkdir -p ~/.local/share/auto-commit-notes
{ crontab -l 2>/dev/null | grep -vF 'auto-commit-notes.sh' || true; echo "$ENTRY"; } | crontab -
