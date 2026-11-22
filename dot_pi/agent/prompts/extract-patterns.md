---
description: Mine .pi session history for re-usable patterns (prompt templates, scripts, workflows)
argument-hint: "[focus e.g. 'testing' or 'backbone']"
deterministic:
  script:
    path: ../bin/pi-session-patterns.py
    args: ["--days", "45", "--max-sessions", "120", "--top", "25", "--max-requests", "400"]
  handoff: always
  timeout: 120000
---
You are analyzing a digest of my recent **pi** coding-agent session history. The
deterministic step above ran `pi-session-patterns.py`; its stdout (attached as the
tool result) contains aggregate tool/command/file tallies plus a `FULL_DIGEST_FILE:`
path.

**First, `read` that `FULL_DIGEST_FILE`** — it holds the complete digest including
every individual user request. The stdout tallies are only a summary; the request
list is the raw material you need and lives in the file.

Your job: mine that history for **re-usable patterns** — things I do repeatedly
that could be captured as a prompt template, a helper script, a skill, or a
documented workflow shortcut.

Optional focus from me (ignore if empty): $@

Do the following:

1. **Cluster the user requests** into recurring intents (e.g. "run a scoped
   spec", "open a PR", "query a prod DB via cloud-sql-proxy", "scaffold a
   service"). Note roughly how often each recurs and in which projects.

2. **Cross-reference the aggregate tallies** (top tools, recurring full command
   lines, most-touched files/dirs, existing prompt-template usage) to confirm
   which intents are frequent and mechanical enough to be worth automating.

3. For each strong pattern, propose a concrete **re-usable artifact**. Prefer the
   lightest form that fits:
   - a **prompt template** (`~/.pi/agent/prompts/<name>.md`) — give the frontmatter
     (description, argument-hint, any deterministic `run`/`script`) and body,
   - a **helper script** (`~/.pi/agent/bin/<name>`) — sketch its interface,
   - a **skill** or a note for an `AGENTS.md` — when it's guidance rather than a command.
   Note if any recurring command line is already a good candidate to wrap verbatim.

4. **Skip** one-off or already-covered work. If an existing prompt template
   (see the "Prompt-template usage" section) already covers an intent, say so
   instead of re-proposing it.

Output a ranked list (most valuable first). For each: the pattern, the evidence
(counts/examples from the digest), the proposed artifact form, and a ready-to-use
draft. End with the 2–3 you'd build first and why.

Do **not** create any files yet — this is a proposal. Wait for me to pick.
