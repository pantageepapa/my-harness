## Context

The easy-path agentic workflow currently ends at the Junior Dev agent opening a Draft PR. No automated quality gate runs before human review, so reviewers absorb the full test-verification cost. The Testing agent closes this gap.

Existing art to build on:
- `junior-dev.yml` — the branch naming pattern (`junior-dev/**`), the run-log commit pattern (checkout `main`, commit to `.github/agent-logs/…`), and the agent-improver dispatch.
- `senior-dev.yml` / `senior-dev-resume.yml` — demonstrates two-workflow chaining: a primary workflow + a thin event-triggered resume workflow.

The Junior Dev workflow currently has only a `workflow_dispatch` trigger and no awareness of test results.

## Goals / Non-Goals

**Goals:**
- Trigger a Testing agent run on every Junior Dev PR open/sync/reopen.
- The agent writes tests, runs them, and either passes silently or posts a structured loop-back comment on failure.
- The Junior Dev workflow re-dispatches on a structured loop-back comment (once the comment is posted, the loop fires automatically).
- A hard cap (default 3 re-triggers) prevents infinite ping-pong.
- Each Testing agent run logs execution to `.github/agent-logs/testing/pr-<n>/<run-id>.json` on `main`.

**Non-Goals:**
- Testing PRs from branches other than `junior-dev/**`.
- Enforcing a particular test framework — the agent picks whatever fits the diff.
- Replacing human review — the Testing agent gates on automated tests only.
- Flipping the Draft PR to ready-for-review (that remains a human or future agent step).

## Decisions

### D1: Trigger — `pull_request` on `junior-dev/**`

`testing.yml` uses the `pull_request` event filtered to `branches: ['junior-dev/**']` with `types: [opened, synchronize, reopened]`. This fires on every new push to a Junior Dev PR branch without requiring the Junior Dev workflow to dispatch it explicitly.

**Alternative considered**: `workflow_dispatch` from `junior-dev.yml` — simpler coupling but breaks if Junior Dev's final step fails before the dispatch. The event-driven trigger is more resilient.

### D2: Loop-back — structured PR comment (option A)

On test failure, the Testing agent posts an `issue_comment` on the PR with a JSON fenced block containing a well-known marker:

```json
<!-- testing-agent-loop-back -->
```json
{ "type": "testing-agent-loop-back", "retry": <n>, "run_id": "<id>" }
\```
```

The Junior Dev workflow gains an `issue_comment` trigger. When it fires, a guard step checks:
1. Is the comment body on a PR whose head branch matches `junior-dev/**`? (via `github.event.issue.pull_request`)
2. Does the comment body contain the `testing-agent-loop-back` marker?
3. Has the hard cap (3) not been exceeded? (parse `"retry"` from the comment JSON)

If all three are true → `gh workflow run junior-dev.yml -f ticket_key=<KEY>`.

**Alternative considered**: label-based (option B, rejected by the ticket). Label presence/absence is harder to query inline and adds label-management overhead.

**Alternative considered**: `pull_request_review` trigger (same mechanism as `senior-dev-resume.yml`) — but that requires a human action; the Testing loop must be fully autonomous.

### D3: Hard cap — retry counter in the comment JSON

The Testing agent queries existing loop-back comments on the PR (`gh api repos/{owner}/{repo}/issues/{pr}/comments`) before posting. It counts comments whose body contains the `testing-agent-loop-back` marker. If the count equals the cap (3), it posts a `testing-agent-gave-up` comment instead (no `loop-back` marker → no re-dispatch).

This keeps all state in the PR comment thread; no external store or label required.

### D4: Runtime — headless `claude -p` (mirrors Junior Dev)

Same runtime split rationale as Junior Dev: the Testing agent edits files (test files) and runs shell commands; `claude-code-action` plumbing is dead weight here.

### D5: Log path — `pr-<pr_number>`

The ticket specifies `.github/agent-logs/testing/pr-<n>/<run-id>.json`. `n` is the PR number (`github.event.pull_request.number`), available in the workflow context.

## Risks / Trade-offs

- **`issue_comment` fires on all PR comments** → The Junior Dev guard step must parse the comment body before dispatching; a malformed or spoofed comment could trigger a re-dispatch. Mitigation: check that the comment author is `github-actions[bot]` before acting.
- **Race between Testing runs** → If two pushes arrive quickly, two Testing runs could both post loop-back comments. The Junior Dev dispatch guard reads `"retry"` from the comment, so both would dispatch but the cap check on the next Testing run prevents runaway growth. Acceptable for the current scale.
- **Log commit to `main` can conflict** → Same pattern as Junior Dev: `git fetch origin main`, `git checkout -B main origin/main`, commit, push. Non-atomic under concurrent log commits; a retry loop or `--force-with-lease` could improve this later.
- **No test framework installed** → The Testing agent must install whatever test runner it needs as part of its run, or call `npm test` / language-native commands that the repo already supports. The agent prompt should prefer existing tooling.
