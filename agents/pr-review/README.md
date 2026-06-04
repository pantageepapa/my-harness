# PR Review agent

Daily/per-PR reviewer. Reads the PR diff, posts inline comments with severity
and reasoning, optionally a short top-level summary. Comment-only — never
approves, merges, or pushes code.

Part of the agentic workflow sketched in [`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Files

- `prompt.md` — the agent's prompt. Edit this to change behavior.
- `../../.github/workflows/pr-review.yml` — workflow that runs the agent.

## How it runs

The workflow `pr-review.yml` triggers on pull_request events
(`opened`, `synchronize`, `ready_for_review`, `reopened`). It checks out the
PR, prepends repo and PR number to `prompt.md`, and feeds the result to
`anthropics/claude-code-action@v1`. The action installs Claude Code on the
runner and runs a headless session in the working directory.

`track_progress: true` is enabled — the action posts a sticky tracking
comment ("Claude Code is reviewing this pull request…") and updates it as
work progresses.

## Manual run

```sh
gh workflow run pr-review.yml
```

This uses the `workflow_dispatch` trigger and runs against the default branch.
For a real review, push to a PR — the `pull_request` trigger fires
automatically.

## Editing the prompt

Edit `prompt.md` directly. The workflow reads it at run-time, so a change to
the prompt takes effect on the next workflow run — no other plumbing needed.

## What's deliberately not configured

- No `--model` — uses the action's default.
- No `--max-turns` — runs to completion.
- No `--system-prompt` flag — `prompt.md` *is* the system-level guidance.
- No write access to `contents:` — review-only by construction.

## Required setup (one-time)

Authenticated via Claude Pro/Max OAuth (uses your subscription quota, not
per-token API billing):

1. Locally: `claude setup-token` → log in with your Claude.ai account →
   it prints a long-lived OAuth token.
2. On GitHub: **Settings → Secrets and variables → Actions → New repository
   secret**, name `CLAUDE_CODE_OAUTH_TOKEN`, paste the token.

Heads up: CI runs draw from the same 5-hour usage buckets as your local
Claude Code sessions. If you'd rather use per-token API billing, swap
`claude_code_oauth_token:` for `anthropic_api_key:` in the workflow and use
an `ANTHROPIC_API_KEY` secret instead.
