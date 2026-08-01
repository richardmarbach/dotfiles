# readonly

Read-only mode for **pi** — restrict the agent to a configurable tool
whitelist. The LLM is not told the mode is active; it simply sees a smaller
toolset and adapts. You, the user, see a window-title `[RO]` prefix and a
yellow `read-only` footer indicator.

## Install

This extension lives in `~/.pi/agent/extensions/readonly/` and is
auto-discovered.

```bash
ls ~/.pi/agent/extensions/readonly/   # package.json, src/, tests/, README.md
```

No build step. Pi loads `src/index.ts` directly via jiti.

## Usage

### CLI flag

```bash
pi --readonly                # start in read-only mode
pi --readonly "Review main.py"
```

### Slash commands (interactive mode only)

| Command | Effect |
|---|---|
| `/readonly` | enable read-only mode |
| `/readonly on` | enable read-only mode |
| `/readonly off` | disable (asks for confirmation) |
| `/readonly allow <tool>` | add `<tool>` to the active whitelist |
| `/readonly deny <tool>` | remove `<tool>` from the active whitelist |
| `/readonly list` | print the current whitelist to the transcript |
| `/readonly status` | toast `read-only: ON · N tools allowed` |
| `/readonly reset` | restore the whitelist to settings.json defaults |

Tab-completion lists subcommands and (for `allow`/`deny`) tool names from
`pi.getAllTools()`.

`/readonly` is **disabled in print mode (`-p`), JSON mode (`--mode json`), and
RPC mode (`--mode rpc`)**. The `--readonly` flag still governs those runs.
Anything that tries to invoke `/readonly` non-interactively shows up in the
transcript as a `[readonly] ... rejected - interactive input required` banner
that is filtered out of the LLM's context.

## Default whitelist

```
read
grep
glob
web_search
code_search
fetch_content
get_search_content
coms_list
coms_get
coms_send
coms_end
```

**Not** allowed by default: `bash`, `edit`, `write`, `subagent`, anything
else.

## Configuring via settings.json

Override the default wholesale with `readOnly.whitelist`. Both global
(`~/.pi/agent/settings.json`) and project (`.pi/settings.json`) are read;
project wins.

```jsonc
{
  "readOnly": {
    "whitelist": ["read", "grep", "coms_*"]
  }
}
```

Entries ending in `*` are treated as **prefix matches** (`"coms_*"` matches
`coms_send`, `coms_list`). Everything else is an exact match. No general
globs.

Validation is permissive:

- Missing key → use the in-code default.
- Wrong shape (not an array) → warn and use the in-code default.
- Non-string entries → warn and skip them.
- Non-existent tool names → accepted (pre-authorises tools registered later).
- Empty array `[]` → accepted; agent has no tools while read-only is active.

## Lifecycle behaviour

| Event | On/off state | Whitelist |
|---|---|---|
| Process start | Determined by `--readonly` | In-code default OR settings.json |
| `/new`, `/resume`, `/fork`, `/clone` | Re-init from `--readonly` | Reset to settings.json defaults |
| `/reload` | **Preserved** | Re-read from settings.json (ephemeral `allow`/`deny` dropped) |
| `/compact` | unchanged | unchanged |

State is **in-memory only** and not persisted in the session.

## Coexistence with other extensions

We narrow only. At `turn_start` we compute
`whitelist ∩ pi.getActiveTools()` and call `pi.setActiveTools(intersection)`,
so any other extension that already restricted the active set keeps its
restrictions. A `tool_call` backstop blocks anything not on our whitelist
even if another extension overwrites the active list later. The backstop's
rejection message is intentionally neutral (`Tool '<name>' is not currently
available`) so the LLM cannot infer that read-only is active.

## Subagent

`subagent` is **default-blocked**. If you explicitly `/readonly allow
subagent`, the spawned subagent runs as a normal pi subprocess with **no
read-only propagation**.

## Failure modes

| Scenario | Behaviour |
|---|---|
| `--readonly` + settings.json malformed | Use in-code defaults, still apply read-only. |
| `--readonly` + `pi.setActiveTools()` throws | Show a degraded banner; the `tool_call` backstop continues to enforce. |
| No `--readonly` flag + extension errors | Logged; pi proceeds normally. |

## Tests

Pure unit tests, no pi runtime, no mocks.

```bash
cd ~/.pi/agent/extensions/readonly
bun run tests/run.ts
```
