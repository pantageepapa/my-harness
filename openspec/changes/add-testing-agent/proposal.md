## Why

The easy-path agentic workflow (Junior Dev → PR) has no automated quality gate: the Junior Dev agent commits whatever code it writes with no enforced test coverage. Adding a Testing agent closes that gap by writing and running tests on every Junior Dev PR before a human reviewer sees it — and bouncing failures back to the Junior agent automatically.

## What Changes

- New `agents/testing/prompt.md` — headless `claude -p` prompt that reads the PR diff, writes tests, runs them, and on failure posts a structured PR comment triggering the Junior agent to retry.
- New `agents/testing/README.md` — operational documentation (triggers, loop-back mechanism, log location, hard-cap rationale).
- New `.github/workflows/testing.yml` — triggered on `pull_request` events from branches matching `junior-dev/**`; runs the Testing agent; commits the run log to `.github/agent-logs/testing/pr-<n>/<run-id>.json`; enforces a hard re-trigger cap to prevent infinite ping-pong.

The loop-back mechanism is **option A**: on test failure the Testing agent posts a structured PR comment (JSON fenced block with a well-known marker) that the Junior Dev workflow can watch for to re-dispatch itself.

## Capabilities

### New Capabilities

- `testing-agent`: Automated test-writing and test-running agent triggered by Junior Dev PRs. Writes tests scoped to the PR diff, executes them, and either passes (does nothing more) or fails (posts a structured loop-back comment capped at a fixed number of retries).

### Modified Capabilities

- `junior-dev-agent`: The Junior Dev workflow gains a watch condition: if a structured loop-back comment from the Testing agent appears on its own PR (and the retry count is below the cap), it re-dispatches itself on the same branch.

## Impact

- **New files**: `agents/testing/prompt.md`, `agents/testing/README.md`, `.github/workflows/testing.yml`.
- **Modified file**: `.github/workflows/junior-dev.yml` — adds a `pull_request_review_comment` (or `issue_comment`) trigger / polling step to re-dispatch on a structured Testing-agent comment.
- **Branch filter**: `testing.yml` branches filter is `junior-dev/**` (the naming pattern from KAN-2, confirmed by `agents/junior-dev/README.md`).
- **Secrets/vars needed**: same `CLAUDE_CODE_OAUTH_TOKEN`, `DEV_PAT`, Jira secrets as `junior-dev.yml`; no new secrets required.
- **Log storage**: `.github/agent-logs/testing/pr-<n>/<run-id>.json` on `main` (mirrors the Junior Dev log pattern).
