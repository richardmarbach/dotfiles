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
model: anthropic/claude-haiku-*
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
| `tools`, `model`, `thinking` | Defaults for the child. Explicit tool parameters override them; task sizing overrides `model` and `thinking`. `model` may be a family like `anthropic/claude-sonnet-*`. |
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
| `model`, `thinking` | Default: picked by [task sizing](#task-sizing), then the agent's values, then the parent's current model and thinking level. |
| `tools` | Tool allowlist passed to `--tools`. Default: the agent's tools. |
| `keep_open` | Leave the child running in its tab after it reports. Default: the inverse of the agent's `auto-exit`. |

Run several `rex_subagent` calls in one assistant message to run subagents in parallel.

## Task sizing

When a call leaves `model` or `thinking` unset, the parent asks a decision model (a `classifier`, default
`typesafe/jev-latest`, else the first available one) three questions about the task and the agent's role, in one
request:

- **Size** (score) picks the model. It judges scope only: files, steps, and whether the approach is given. It is told
  to ignore wording about importance or risk, so "be careful, this is production" does not upgrade the model.
- **Effort** (score) picks the thinking level: `low` mechanical, `medium` ordinary care, `high` subtle logic or edge
  cases, `xhigh` concurrency, security or data integrity.
- **Review** (yes/no) sends reviews, audits and critiques of existing work to the review model whatever their size.
  Acting on review feedback is not a review. The answer counts as yes at a probability of 0.7 or more.

| Size | Description | `claude` (default) | `openai` | `mixed` |
| --- | --- | --- | --- | --- |
| trivial | one specific lookup, command or one-line edit | `claude-haiku-*` | `gpt-*-luna` | `claude-haiku-*` |
| small | self-contained, one or two files, approach clear | `claude-haiku-*` | `gpt-*-luna` | `gpt-*-luna` |
| medium | several files or steps, the task says what to do | `claude-sonnet-*` | `gpt-*-sol` | `claude-sonnet-*` |
| large | many files, or the goal is named but not the approach | `claude-sonnet-*` | `gpt-*-sol` | `gpt-*-sol` |
| very large | open-ended design across a whole system | `claude-opus-*` | `gpt-*-astra` | `claude-opus-*` |
| review (any size) | | `claude-opus-*` | `gpt-*-astra` | `claude-opus-*` |

Scores round to the nearest size, except "very large" needs a score of at least `topTierMinScore` (3.6). If the
effort question has no answer, the size's own thinking level is used.

A selection overrides the agent's `model` and `thinking`; those become fallbacks. Sizing falls back to them when no
decision model is available, the request errors or takes longer than `timeoutMs`, the size answer's confidence is
below `minConfidence`, or the chosen model has no credentials. If the fallback model's provider is not used by the
mode (say, a Claude agent default in `openai` mode), the mode's middle size is used instead. The result and progress
line show the choice and why, e.g. `auto: small, review, effort high (90%)`, `defaults: no classifier available` or
`openai fallback: medium; timeout`.

Every spawn appends a line to `~/.pi/agent/rex-subagent-decisions.jsonl`: time, cwd, mode, agent, the task (first
400 characters) and its length, the raw scores, and the chosen model, thinking level and note. Use it to tune the
descriptions against real tasks. Set `"log": false` to turn it off.

## Modes

The mode decides which models sizing may choose from: `claude` (default), `openai` or `mixed`. Set it per session:

- `/subagent-mode openai` (no argument opens a picker). It is saved in the session, so resuming keeps it.
- `pi --subagent-mode mixed` at startup, which wins over a saved choice.
- `defaultMode` in `~/.pi/agent/rex-subagent.json` for sessions that set neither.

The footer shows the current mode. Subagents inherit their parent's mode. A `model` passed in the call is always used,
whatever the mode.

## Staying current

Anywhere a model is named (tiers, agent `model:` frontmatter, the `model` parameter) you can give a family with `*`
in place of the version, like `anthropic/claude-opus-*` or `openai-codex/gpt-*-sol`. It resolves at spawn time to the
highest version among models with working credentials, comparing versions numerically and skipping dated snapshots
such as `claude-opus-4-5-20251101`. A new release is used as soon as pi's model catalog lists it (`pi update`); nothing
in this extension or the agent files needs editing. Pin an exact ID when you want to stay on a version.

## Configuration

Override any of the above in `~/.pi/agent/rex-subagent.json`. Top-level keys replace the defaults; `tiers` replaces
the whole list, may have any length, and every tier must name a model for all three modes. `efforts` and
`overrides` work the same way; an override is any yes/no question with a `threshold` and a model per mode.

```json
{
  "enabled": true,
  "defaultMode": "claude",
  "classifier": "typesafe/jev-latest",
  "timeoutMs": 10000,
  "minConfidence": 0,
  "topTierMinScore": 3.6,
  "log": true,
  "tiers": [
    {
      "size": "trivial",
      "description": "A lookup or one-line change",
      "models": {
        "claude": { "model": "anthropic/claude-haiku-*", "thinking": "low" },
        "openai": { "model": "openai-codex/gpt-*-luna", "thinking": "low" },
        "mixed": { "model": "anthropic/claude-haiku-*", "thinking": "low" }
      }
    }
  ]
}
```

The tool is only registered when `REX_SESSION` or `REX_BLOCK` is set, so it only appears when pi runs inside Rex.

## Tests

```sh
npm test
```
