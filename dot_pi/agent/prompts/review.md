---
description: Review the code for issues
---

Perform an adversarial review, looking for the following attributes:

- Consistency.
- Difficult to understand code.
- High cognitive load.
- If you have to read a block of code multiple times, it’s an indicator that the code needs improvement.
- Improvements on naming.
- Code which is prone to bugs (even if it’s not buggy *yet*).
- Inflexible, rigid, hard to refactor implementations.
- Code which doesn’t scale well.
- Missing tests.
- There’s an easier solution with additional advantages.

If correctness is not clear from the context, ask the user for clarification.

If you need a paragraph-long comment to justify why the workaround is OK, the code is wrong — fix the code.
