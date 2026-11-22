---
description: Non-interactively finish an in-progress rebase and resync the gh pr stack
argument-hint: "[optional: branch to rebase onto, e.g. main]"
run: |
  echo "=== branch / status ==="; git status --short --branch
  if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
    echo "REBASE IN PROGRESS"
  else
    echo "no rebase in progress"
  fi
  echo "=== conflicted files ==="; git diff --name-only --diff-filter=U
  echo "=== recent commits ==="; git log --oneline -8
  command -v gh >/dev/null 2>&1 && gh stack view 2>/dev/null | head -40 || true
---
Finish the in-progress rebase (or, if none is in progress, start one onto
{{args|default:"main"}}) **non-interactively**.

Rules:
- Never open an editor. Use `GIT_EDITOR=true` and `--no-edit` for every
  rebase / continue / commit / amend.
- Resolve each conflict by understanding **both** sides. For files we own
  outright (e.g. our service + its spec), `git checkout --ours <file>` then
  re-applying the intended change is acceptable — but confirm the result
  reads correctly and is internally consistent; never blindly take a side.
- After resolving: `git add` the files, then
  `GIT_EDITOR=true git rebase --continue`. Repeat until the rebase completes.
- If you get stuck or the state is ambiguous, inspect
  `git rebase --show-current-patch` before deciding.
- When done, show `git status` and `git log --oneline -8`.
- If this branch is part of a `gh pr` stack, resync the whole stack afterwards
  (restack, then `git push --force-with-lease` per branch) and report the final
  stack state via `gh stack view`.
- Do NOT push unless the rebase is clean and the working tree matches intent.
  Summarise what changed and flag anything that needs a human decision.
