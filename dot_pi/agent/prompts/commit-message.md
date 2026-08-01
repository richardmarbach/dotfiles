---
description: Generate a git commit message from staged changes
model: claude-sonnet-4-6
thinking: low
run: git status -vv
handoff: always
---
Review the staged diff and generate a commit message using the following git commit message format:

**Title (first line):**
- Keep it concise and descriptive
- It must contain around 50 characters
- Use imperative mood (e.g., "Fix bug" not "Fixed bug" or "Fixes bug")
- Examples: `Add new feature`, `Correct a bug`, `Improve build system performance`

**Body (subsequent paragraphs):**
- Write in paragraph form, not bullet points
- Ensure lines wrap at 72 characters
- Explain WHAT changed and WHY it changed
- Focus on the motivation and context, not the implementation details
- Keep paragraphs concise but descriptive
- Separate paragraphs with blank lines for readability

**General rules:**
- Don't add Co-authored-by
- Do describe the overall impact and motivation in prose
- Be direct and to the point
- Don't create a commit
- Don't include a Title and a Body heading
