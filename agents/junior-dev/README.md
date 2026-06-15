# Junior Developer agent

Headless implementation agent for "easy" Jira tickets (story points 1–3).
Picks up a ticket key, implements the change, pushes a branch, and opens
a Draft PR. Fully autonomous — no human in the loop until the PR review.

Part of the agentic workflow sketched in [`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Files

- `prompt.md` — the agent's prompt. Edit this to change behavior.
- `../../.github/workflows/junior-dev.yml` — workflow that runs the agent.

## How it runs

The workflow `junior-dev.yml` triggers on `workflow_dispatch` only.
Dispatches come from two places:

- **Manual** — `gh workflow run junior-dev.yml -f ticket_key=KAN-42`.
- **Automated** — the Development Orchestrator
  ([`orchestrator.yml`](../../.github/workflows/orchestrator.yml))
  fires it on the Jira "Dev Ready" transition for every ticket with
  story points 1–3, then moves the ticket to **In Progress** so the
  same transition can't re-fire it.

The workflow installs `jira` and the Claude Code CLI, configures git,
creates branch `junior-dev/<TICKET_KEY>` from `origin/main`, then hands
off to a single `claude -p` invocation. The agent reads the ticket,
implements, commits, pushes, and opens the Draft PR itself.

## Decisions

These are the three implementation decisions KAN-2 asks the agent
author to make. Each decision and why:

- **Prompt framing — direct prompt, no skill.** `/goal` and `/ralph-loop`
  (mentioned in the original sketch) don't exist as skills in this repo,
  and the loop-control mechanism we want (`--max-turns`) is a CLI flag,
  not skill behavior. A skill would be an empty wrapper.
- **Stop condition — `--max-turns 60` + `timeout-minutes: 90`.** Two
  bounded mechanisms. `--max-turns` makes the agent fail fast on hard
  tickets without burning the full job budget. The job timeout is a
  belt-and-suspenders against any agent step that hangs (e.g. a runaway
  test invocation). An attempt counter on the ticket would race the
  orchestrator and make failures sticky across runs — rejected.
- **Branch naming — `junior-dev/<TICKET_KEY>`.** Predictable, unique
  per ticket, and namespaced so it's obvious which agent owns it.
  Re-dispatching the same ticket force-resets the branch from
  `origin/main` (workflow uses `git checkout -B`), so a re-run gets a
  clean start.

## Runtime split

This agent is the first to run **headless `claude -p` directly** rather
than through `anthropics/claude-code-action@v1`. The action stays for
read/triage agents (jira-ticket, pr-review, agent-improver) where its
event-shaped plumbing is useful. The orchestrator now runs as plain
bash with no model. For
implementation, the action's PR-comment surface is dead weight; running
the CLI directly gives full control over `--max-turns`, allowed tools,
and exit handling. See the *Design choices* section in
[`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Manual run

```sh
gh workflow run junior-dev.yml -f ticket_key=KAN-42
```

Optional `max_turns` input overrides `--max-turns` (default 60). Use a
small value to deliberately exercise the stop condition (see below).

## Stop-condition exercise

To see the turn cap in action against a real ticket:

```sh
gh workflow run junior-dev.yml -f ticket_key=KAN-42 -f max_turns=5
```

Expected outcome:

- Agent reads the ticket and starts implementing.
- After 5 turns, `claude` exits non-zero on `--max-turns`.
- The workflow detects the non-zero exit, still pushes whatever the
  agent committed, and the agent's pre-finish push/PR step may not
  have run — in which case the workflow opens a fallback `[WIP]` Draft
  PR titled `[WIP] [<KEY>] junior-dev hit turn cap` with a body noting
  the cap.
- Run log is committed under
  `.github/agent-logs/junior-dev/<DATE>/<RUN_ID>.json`.
- agent-improver workflow is dispatched as usual.

Record the run URL here once exercised:

> _Stop condition exercised: <run URL TBD — fill in after first invocation>_

## Logs

Each run's execution log is committed back to `main` at
`.github/agent-logs/junior-dev/<YYYY-MM-DD>/<run-id>.json`. Format
matches the array shape produced by `claude-code-action` (the workflow
runs `jq -s '.'` over the CLI's JSONL stream so the existing
agent-improver `jq` queries work unchanged). Browse with
`bash tools/viewer.sh`.

## What's deliberately not configured

- No `--model` — uses the CLI's default.
- No assignee or label filtering. The orchestrator gates which tickets
  get dispatched.

## Required setup

In addition to `CLAUDE_CODE_OAUTH_TOKEN` (see
[`agents/pr-review/README.md`](../pr-review/README.md)) and the Jira
secrets/variables documented in
[`agents/jira-ticket/README.md`](../jira-ticket/README.md):

- **`DEV_PAT`** (repo secret) — fine-grained PAT scoped to this
  repo with permissions: `Contents: write`, `Pull requests: write`,
  `Workflows: write`. Used by the agent for `git push` and
  `gh pr create`, and by the workflow's fallback PR step. The
  `Workflows: write` scope is required for tickets that scaffold a
  new agent (which adds a file under `.github/workflows/`); the
  default `GITHUB_TOKEN` cannot push workflow files. The workflow
  falls back to `GITHUB_TOKEN` if `DEV_PAT` is unset, but
  workflow-file pushes will then be rejected at push time.

  Bonus: because the PAT is a user token rather than the runner's
  `GITHUB_TOKEN`, PRs it opens *do* trigger downstream workflows —
  so `pr-review.yml` fires automatically on junior-dev's PRs.

- **Repo setting** — *Settings → Actions → General → Allow GitHub
  Actions to create and approve pull requests* must be enabled.
  Without this, the workflow's fallback `gh pr create` step fails
  with `GitHub Actions is not permitted to create or approve pull
  requests` even when the PAT is configured for the agent's own
  `gh pr create` call.

## Known limitations

- **No automated test step.** The agent runs whatever tests it deems
  relevant to the change, but there's no separate testing agent
  enforcing coverage. Reviewers carry that load until/unless a
  testing agent is added.
