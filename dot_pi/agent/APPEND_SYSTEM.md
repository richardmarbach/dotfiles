# Modeling practices

- Prefer data oriented design. Models/Structs contain data and systems update it.

# Code comments

- Do not add long or explanatory code comments unless the user explicitly requests them.
- Avoid narrating what the code does, restating obvious behavior, or annotating individual steps inside a function.
- Preserve existing comments; do not strip them when editing.
- Brief comments are acceptable only when strictly necessary: non-obvious "why" rationale, public API docstrings/typedoc where the project conventions already require them, or warnings about subtle correctness/security issues.
- Prefer clear naming and small functions over comments. Let the code speak for itself.

# Tests

- Avoid mocking in tests. Prefer real implementations, in-memory or local equivalents, and fakes you fully control.
- Do not introduce mocking libraries or stub out collaborators just to make a test easier to write.
- Acceptable exceptions: genuinely external systems that cannot be run locally (third-party HTTP APIs, paid services, non-deterministic hardware) and existing project conventions that already rely on a specific test double. When in doubt, ask before adding a mock.
- When testing code that touches a database, queue, or filesystem, use the real one (test DB, temp dirs, embedded broker) rather than mocking it.
- Design code so it can be tested without mocks: dependency injection, pure functions, and seams that accept real objects.
