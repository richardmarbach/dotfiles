# pi-coms

Local pi-to-pi communication.

- **Auto-join**: sessions join the cluster on `session_start`.
- **Identity**: resolved per-field in this order:
    1. **CLI flags** (`--name`, `--project`, `--purpose`, `--color`,
       `--explicit`).
    2. **Prompt-template frontmatter**, when the session was launched
       with a leading `/<template-name>` message. The extension looks
       up `<cwd>/.pi/prompts/<name>.md` then
       `~/.pi/agent/prompts/<name>.md` and parses its YAML frontmatter
       with the same parser pi uses for skills/templates. Templates
       registered via `pi.prompts` package dirs, the settings `prompts`
       array, or `--prompt-template <path>` are still invocable as
       `/name` but are **not** scanned for identity — those sessions
       fall back to defaults.
    3. **Defaults**: name = cwd basename (auto-disambiguated against
       live peers); project = `<basename>-<sha256(cwd):8>`.

  Precedence is per-field: `--name alice` plus a template with
  `project: foo` results in `alice` registered in project `foo`.
  A launcher reading frontmatter and passing CLI flags is still
  supported and remains the most explicit option, but is no longer
  required.
- **Endpoint**: each pi session listens on a single endpoint — a UNIX
  domain socket on POSIX (`~/.pi/coms/sockets/<peer-uuid>.sock`) or a
  Windows named pipe (`\\.\pipe\pi-coms-<peer-uuid>`).
- **Discovery**: per-project registry files at
  `~/.pi/coms/projects/<project>/agents/<name>.json`. The project key is
  derived from the launched cwd (`<basename>-<sha256(cwd):8>`).
- **Identity**: within a project a session is uniquely identified by its
  display name. Two sessions in the same project auto-disambiguate
  (`alice`, `alice-2`, …). Across projects, peers are addressed by
  `<project>/<name>`.

## Layout

```
~/.pi/coms/
├── projects/
│   └── <project-key>/
│       └── agents/
│           └── <name>.json     # {project, projectPath, name, peerId, pid, socket, startedAt}
└── sockets/                    # POSIX only
    └── <peer-uuid>.sock
```

Registrations whose `pid` is dead or whose endpoint is gone (socket file
missing on POSIX) are pruned by any peer that scans the registry. On
Windows liveness uses the pid alone since named pipes aren't on the
filesystem.

## Wire protocol

Newline-delimited JSON. One message per connection, then `ack` is
written back and the connection closes.

| type      | direction                | payload                                                |
| --------- | ------------------------ | ------------------------------------------------------ |
| `prompt`  | sender → recipient       | `{msgId, from: PeerInfo, content}`                     |
| `reply`   | recipient → sender       | `{msgId, inReplyTo, from: PeerInfo, content}`          |
| `ping`    | any → any                | `{}` — health probe                                    |
| `pong`    | response to ping         | `{from: PeerInfo}`                                     |
| `ack`     | response to prompt/reply | `{ok: boolean, error?}`                                |

## Tools

| Tool         | Purpose                                                                                       |
| ------------ | --------------------------------------------------------------------------------------------- |
| `coms_list`  | List peers. Default = current project; `project="all"` to list every project.                 |
| `coms_send`  | Send a prompt (non-blocking). Returns a `message_id`. Peer handle: bare name or `proj/name`. The outbox entry persists for the life of the session — the reply arrives proactively as a user message. |
| `coms_get`   | Diagnostic: read the current status (`pending` / `replied` / `failed`) of a previously-sent message. Replies arrive proactively as user messages, so polling is rarely needed. |
| `coms_end`   | Reply to an incoming prompt by `message_id`.                                                  |

## Reply delivery

Replies to a `coms_send` are delivered as **injected user messages**,
not via a blocking tool. The agent does not need to wait or poll —
when a peer replies (or when delivery to that peer fails, e.g. the
peer goes offline), pi-coms injects a user message identifying the
original `msgId` and carrying the reply or failure. Multiple
outstanding sends are disambiguated by `msgId` in the injection body.
`coms_get` remains available for explicit state checks but is rarely
needed.

Incoming prompts (📨) and reply results (📬) use distinct envelope
emoji so the agent can disambiguate quickly:

```
📬 Reply received via pi-coms: message_id=<id> from <peer-handle> has resolved.

--- Result ---
message_id=<id> to=<peer-handle> age=<n>s status=replied|failed
<reply body or error text>
--- End result ---
```

**Idiomatic usage:** call `coms_send` and end your turn (or keep
working on unrelated tasks). The harness will resume the conversation
when the reply lands. Do not poll, do not wait.

**Peer-gone failures** fire when the target peer's registration file is
actually gone — typically a clean shutdown (next tick ≤ 5s) or a hard
exit where the pid is dead and `pruneIfDead` removes the file on the
next tick. They also fire when a peer **restarts under the same handle**
with a fresh `peerId`: the old peer's outbox entries can never be
answered, so they're terminalized with the same `peer went offline`
error.

**Transient unreachability does NOT terminalize.** If pings keep
failing but the peer's registration file still looks alive (pid alive,
endpoint present, `lastSeen` fresh), the pool entry sticks and the
outbox stays pending. The recovery loop keeps probing every
`RECONNECT_INTERVAL_MS` (1.5s) and brings the peer back to `online` as
soon as it's responsive again. This is the auto-reconnect path: a
busy peer, a brief socket hiccup, or a peer mid-restart no longer
costs the cluster its view of that session.

## Auto-reconnect / recovery

The pool's view is repaired on three levels:

1. **Send retry**: `coms_send` and `coms_end` retry transient connect/
   ack failures for up to `SEND_RETRY_TOTAL_MS` (2.5s) with exponential
   backoff. The peer's registry entry is re-resolved between attempts,
   so a peer that restarted with a fresh socket path can still be
   reached on the same handle. Retries stop immediately if the
   registration file is gone (peer truly offline).
2. **Recovery loop**: a 1.5s tick re-probes every pool entry whose
   status is not `online`. It re-resolves the registry (catching
   peer-restart-with-new-peerId) and pings. Successful pings flip the
   entry back to `online`.
3. **Sticky pool**: the main 5s tick evicts a `gone` entry only when
   `pruneIfDead` succeeds — i.e. the registration file is missing,
   pid is dead, endpoint is gone, or `lastSeen > 180s`. There is no
   longer a fixed "gone-tick" countdown that drops live-but-slow
   peers from the pool.

**Server self-heal**: each session installs a permanent `error`
handler on its listening socket and re-creates the listener if it
dies after startup (e.g. another peer's prune wiped the socket file).
The main tick also checks every cycle that its own socket file still
exists on disk and restarts the listener if it's missing.

## Commands

| Command              | Purpose                                                |
| -------------------- | ------------------------------------------------------ |
| `/coms`              | List peers in the current project.                     |
| `/coms all`          | List peers across every project.                       |
| `/coms reconnect`    | Force an immediate discover + ping sweep, then list.   |

`/coms reconnect` is just a manual nudge — the recovery loop already
reconverges automatically. It's useful for tests, debugging, and "do
it now" moments. To pick up a **new build of this extension** in an
already-running session, use pi's `/reload`. That fires
`session_shutdown` (clean removal of the old socket + registration)
followed by `session_start` with `reason="reload"`, which re-registers
immediately. Other peers detect the new `peerId` for the same handle
on their next tick and recover via the peer-restart path.

## CLI flags

The extension registers these flags so pi's argument parser accepts them
(pi 0.73+ otherwise errors on unknown options before extension hooks run).
A launcher may still derive these from frontmatter and pass them on the
command line for an explicit override; without flags, the extension reads
the same frontmatter itself on first input.

| Flag         | Type    | Wired                                  | Purpose                                                                  |
| ------------ | ------- | -------------------------------------- | ------------------------------------------------------------------------ |
| `--name`     | string  | yes — overrides peer name              | Override agent name (otherwise from frontmatter or cwd basename).        |
| `--project`  | string  | yes — overrides project namespace      | Project namespace for peer discovery (default = derived from cwd).       |
| `--purpose`  | string  | parsed only (not yet used by pi-coms)  | Override agent purpose (otherwise from frontmatter `purpose`/`description`). |
| `--color`    | string  | parsed only (not yet used by pi-coms)  | Hex color `#RRGGBB` (otherwise from frontmatter or palette fallback).    |
| `--explicit` | boolean | parsed only (not yet used by pi-coms)  | Hide this agent from auto-discovery; only addressable by exact name.     |

## Frontmatter keys

When identity is resolved from a prompt template's frontmatter, these
top-level keys are honored (all optional, all string except `explicit`):

| Key           | Maps to     | Notes                                                                  |
| ------------- | ----------- | ---------------------------------------------------------------------- |
| `name`        | `--name`    | Slugged via the same rule as the flag.                                 |
| `project`     | `--project` | Slugged via the same rule as the flag.                                 |
| `purpose`     | `--purpose` | Falls back to `description` (the standard prompt-template key).        |
| `color`       | `--color`   | Hex `#RRGGBB`.                                                         |
| `explicit`    | `--explicit`| Boolean.                                                               |

## Registration timing

On fresh sessions (`reason` = `startup` or `new`) the bus join is
deferred briefly (≤ 1s) so the first user/CLI input can surface a
`/<template>` invocation. As soon as either fires, identity is
finalized and the registration file is written. Resumed and reloaded
sessions register eagerly with CLI flags + defaults — there's no
launching template to inspect for those.

During that pre-finalize window the session is not yet visible to other
peers, and `/coms` listings won't include this session under its final
name. In practice this is at most one second, and only affects fresh
sessions before the first message lands.

`input` events whose `source` is `"extension"` (i.e. a `/command`
synthesized by another extension via `sendUserMessage`) do not finalize
identity — only the human's first turn or the defer timer can. This
keeps identity tied to the launching user, not to auto-kickoff helpers.

## Notes

- Replies survive multi-turn work on the receiver: the sender keeps the
  outbox entry around and can poll or await at any time.
- If the receiver session restarts before replying, the original `inbox`
  entry is lost and the sender's entry stays `pending` until any optional
  send-side timeout fires.
- On POSIX the socket file is `chmod 0600`. Only the local user can talk
  to another local pi.
