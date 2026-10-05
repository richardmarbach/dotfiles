# Prompt snippets

Reusable instructions that apply to the next message sent to Pi.

## Usage

- Press `Ctrl+\` or run `/snippets`.
- Move with the configured selection keys, toggle with `Space`, preview with `Tab`, and apply with `Enter`.
- Send a message. Selected snippets are applied once and then cleared.
- Run `/snippets clear` to clear the current selection.

Messages starting with `/` and messages injected by other extensions are left unchanged. The snippet selection remains active for the next regular message.

The picker reads snippets each time it opens and immediately before applying them:

1. `~/.pi/agent/snippets/*.md`
2. `<project>/.pi/snippets/*.md` for trusted projects

A project snippet with the same filename overrides a global snippet. A project file containing `disabled: true` disables the matching global snippet.

## Format

Frontmatter is optional. Without it, the filename is the name and the snippet is appended.

```markdown
---
name: Verify changes
description: Run focused checks before finishing
placement: append
order: 20
---
Run the relevant tests and inspect the final diff before finishing.
```

Fields:

- `name`: picker label
- `description`: short picker description
- `placement`: `prepend` or `append` (default: `append`)
- `order`: numeric ordering within each placement group (default: `100`)
- `disabled`: `true` to remove the same filename from a lower-precedence directory
