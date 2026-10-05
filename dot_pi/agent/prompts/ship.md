---
description: Stage everything, write a Conventional Commit, confirm, then push
argument-hint: "[optional: extra context for the commit message]"
model: claude-sonnet-5
thinking: medium
run: |
  echo "=== branch / upstream ==="
  git status --short --branch
  echo "=== staged ==="
  git diff --cached --stat
  echo "=== unstaged ==="
  git diff --stat
  echo "=== recent commits ==="
  git log --oneline -8
---
Create a git commit following the Conventional Commits specification and push it.
Do not review the changes for defects.

{{args}}

## Steps

1. Read the status and diffs above. If anything is unclear, run `git diff --cached`
   (or `git diff` when nothing is staged) for the full patch.
2. If there are unstaged changes, stage all changes with `git add -A`.
3. Compose a commit message following the Conventional Commits spec:
   - Format: `<type>[optional scope][optional !]: <description>`
   - Types: `feat` (new feature), `fix` (bug fix), `docs`, `style`, `refactor`,
     `perf`, `test`, `build`, `ci`, `chore`, `revert`
   - Add a scope in parentheses when it clarifies the area of change, e.g. `feat(slides):`
   - Use `!` before `:` for breaking changes
   - Keep the description concise, lowercase, imperative mood
   - Add a body after a blank line if more context is needed
   - Add footers (e.g. `BREAKING CHANGE: ...`) after another blank line if applicable
   - Don't add Co-authored-by
4. Show me the full commit message and a summary of what will be committed.
5. Ask me to confirm or request changes.
6. Once confirmed, create the commit and push the current branch to its upstream.
   If the branch has no upstream, push with `git push -u origin HEAD`.
