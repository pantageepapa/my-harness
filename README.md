# my-harness

Personal harness for agentic workflows: reusable agents and GitHub Actions
glue that I use across projects.

## What's here

- [`agents/pr-review`](agents/pr-review) — a comment-only PR reviewer that
  runs as a GitHub Action.
- [`docs/agentic-workflow.md`](docs/agentic-workflow.md) — notes on how the
  pieces fit together.

## Adding a new agent

1. Drop the prompt in `agents/<name>/prompt.md`.
2. Wire a workflow in `.github/workflows/<name>.yml` that feeds the prompt to
   `anthropics/claude-code-action@v1`.
3. Set `CLAUDE_CODE_OAUTH_TOKEN` as a repo secret.

<!-- log-commit verification -->
