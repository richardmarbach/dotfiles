#!/bin/bash

# cron has a minimal PATH; ensure Homebrew binaries are reachable.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Path to the notes directory
NOTES_DIR=~/notes

cd "$NOTES_DIR" || exit 1

if git status --porcelain | grep -q .; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # Async tag scan on changed notes before committing (best-effort, non-blocking).
    if [ -x ~/.local/bin/autotag.sh ]; then
        ZK_NOTEBOOK_DIR="$NOTES_DIR" ~/.local/bin/autotag.sh || echo "autotag skipped/failed"
        zk index >/dev/null 2>&1 || true
    fi

    git add .
    git commit -m "Auto-commit: $TIMESTAMP"
    git pull
    git push
    
    echo "Changes committed successfully at $TIMESTAMP"
else
    echo "No changes to commit at $(date +"%Y-%m-%d %H:%M:%S")"
fi
