# Rex subagents

Adds a `rex_subagent` tool that delegates a task to a fresh pi session running in its own Rex tab.

## How it works

1. The parent creates a run directory in `$TMPDIR/pi-rex-subagents/` and opens a background tab with
   `rex window new -s ${REX_SESSION:-$REX_BLOCK} <label> -- pi --rex-subagent <run-dir> --name <label> -- <task>`.
2. The child loads the same extension. The `--rex-subagent` flag makes it read `<run-dir>/config.json`, apply the
   agent type's prompt, add a system-prompt section describing its role, skip registering `rex_subagent` unless the
   agent allows spawning, and record the current tool call in `<run-dir>/activity`.
3. When the child settles (not when the user aborts it), it writes its final assistant message to
   `<run-dir>/result.json` and quits unless `keep_open` is set.
4. The parent polls the run directory, streams the activity line as progress, and returns the report.
   It also runs `rex wait` on the pane, so a child that exits without reporting fails the call and includes
   the terminal's last lines.

Pressing Escape in the parent closes the subagent's tab. Pressing Escape in the child only interrupts it, so you can
steer it from its tab. The child reports after its next run finishes.

## Agent types

The model picks an agent type with the `agent` parameter. Types load from `~/.pi/agent/agents/*.md` and, in trusted
projects, `.pi/agents/*.md`. A project agent overrides a user agent with the same name. The tool description lists
each type's name, description, tools, model and thinking level, and the `agent` parameter only accepts those names.
Types load at session start, so run `/reload` after adding one.

```markdown
---
name: scout
description: Quickly investigates a codebase and reports relevant findings
tools: read,bash
thinking: low
model: openai-codex/gpt-6-luna
spawning: false
auto-exit: true
system-prompt: replace
---
You are a codebase research agent. ...
```

| Field | Effect |
| --- | --- |
| `name` | Agent type name. Default: the filename. |
| `description` | Shown to the parent model when it chooses a type. |
| `tools`, `model`, `thinking` | Defaults for the child. Explicit tool parameters override them. |
| `system-prompt` | `append` (default) adds the body as an `<agent>` section. `replace` replaces pi's default preamble, tools list and rules. |
| `spawning` | `true` lets the child call `rex_subagent` itself. Default: `false`. |
| `auto-exit` | `false` keeps the child's tab open after it reports. Default: `true`. |
| `disabled` | `true` hides the agent. |

## Parameters

| Name | Description |
| --- | --- |
| `task` | Self-contained instructions. The subagent does not see the parent conversation. |
| `agent` | Agent type. Omit for a general-purpose subagent. |
| `name` | Tab label, slugged. Default: `<agent or subagent>-<id>`. |
| `cwd` | Working directory. Default: the parent's cwd. |
| `model`, `thinking` | Default: the agent's values, then the parent's current model and thinking level. |
| `tools` | Tool allowlist passed to `--tools`. Default: the agent's tools. |
| `keep_open` | Leave the child running in its tab after it reports. Default: the inverse of the agent's `auto-exit`. |

Run several `rex_subagent` calls in one assistant message to run subagents in parallel.

The tool is only registered when `REX_SESSION` or `REX_BLOCK` is set, so it only appears when pi runs inside Rex.

## Tests

```sh
npm test
```
