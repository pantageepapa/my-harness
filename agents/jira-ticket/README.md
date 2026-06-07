# Jira Ticket agent

Daily groomer for the configured Jira project. Edits descriptions, creates
`Blocks` / `Depends on` links between tickets, and decomposes oversized
parents into sub-tasks. Never creates a top-level issue.

Part of the agentic workflow sketched in [`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Files

- `prompt.md` — the agent's prompt. Edit this to change behavior.
- `../../.github/workflows/jira-ticket.yml` — workflow that runs the agent.

## How it runs

The workflow `jira-ticket.yml` triggers on a daily cron (`17 7 * * *` UTC) and
on `workflow_dispatch`. It checks out the repo, installs the pinned
`bin/jira` via `scripts/install-jira-cli.sh`, materializes `.jira/config.yml`
from repo variables and the `JIRA_API_TOKEN` secret, prepends
`JIRA_PROJECT_KEY` to `prompt.md`, and feeds the result to
`anthropics/claude-code-action@v1`. The action runs a headless Claude Code
session with `jira` on `PATH`.

`track_progress: true` is enabled — execution status is captured for the log.

## Manual run

```sh
gh workflow run jira-ticket.yml
```

Uses the `workflow_dispatch` trigger. Useful for re-runs after a token rotation
or a prompt change.

## Editing the prompt

Edit `prompt.md` directly. The workflow reads it at run-time, so a change
takes effect on the next workflow run.

## What's deliberately not configured

- No `--model` — uses the action's default.
- No `--max-turns` — runs to completion.
- No filtering on assignee or labels — JQL stays minimal
  (`resolution = Unresolved`); refine in `prompt.md` if needed.

## Required setup (one-time, per clone)

In addition to `CLAUDE_CODE_OAUTH_TOKEN` (see
[`agents/pr-review/README.md`](../pr-review/README.md)), set:

**Repository secret:**
- `JIRA_API_TOKEN` — Atlassian API token. Generate at
  <https://id.atlassian.com/manage-profile/security/api-tokens>.

**Repository variables** (Settings → Secrets and variables → Actions →
Variables):
- `JIRA_SERVER` — e.g. `https://yourworkspace.atlassian.net`.
- `JIRA_LOGIN` — your Atlassian account email.
- `JIRA_PROJECT_KEY` — the project the agent should groom.
- `JIRA_BOARD_ID` — optional; defaults to `0` if unset.

## Logs

Each run's execution log is committed back to `main` at
`.github/agent-logs/jira-ticket/<YYYY-MM-DD>/<run-id>.json`. Browse with
`bash tools/viewer.sh`.
