# Project documentation

Documentation is grouped by purpose so implementation folders stay focused on runtime code.

- `architecture/`: project structure and architectural decisions. Start with
  [`project-structure.md`](architecture/project-structure.md).
  The current redesign effort is tracked in
  [`redesign-roadmap.md`](architecture/redesign-roadmap.md), with the code conventions it
  establishes in [`conventions.md`](architecture/conventions.md) and the work in flight in
  [`phase-2-plan.md`](architecture/phase-2-plan.md). Decisions intentionally deferred from
  that phase are listed in [`out-of-scope.md`](architecture/out-of-scope.md).
  The ten findings from the code review are covered together in
  [`unified-bugfix-plan.md`](architecture/unified-bugfix-plan.md).
- `api/`: REST API groups, authentication and response conventions.
- `development/`: local setup and developer workflows.
- `presentation/`: defense/demo script and scope notes.
- `testing/`: manual and automated testing guides.
- `troubleshooting/`: diagnostic notes and one-off recovery snippets.
- `archive/`: historical documents that are no longer current but still provide context.

The root `README.md` is the entry point for installation, running, and testing the application.
