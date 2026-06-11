## 1. Testing agent prompt

- [ ] 1.1 Create `agents/testing/prompt.md` — headless `claude -p` prompt instructing the agent to: read the PR diff, identify changed files, write tests appropriate to the language/framework, run them, and report pass/fail
- [ ] 1.2 Add loop-back logic to the prompt: on failure, query existing `<!-- testing-agent-loop-back -->` comments on the PR to determine current retry count; if count < 3 post a structured loop-back comment; if count >= 3 post a gave-up comment
- [ ] 1.3 Define the exact structured comment format in the prompt: HTML marker `<!-- testing-agent-loop-back -->` + fenced JSON block with `type`, `retry`, `run_id` fields + human-readable failure summary

## 2. Testing agent README

- [ ] 2.1 Create `agents/testing/README.md` documenting: trigger (PR events on `junior-dev/**`), loop-back mechanism (structured PR comment), hard cap (3 retries), log location (`.github/agent-logs/testing/pr-<n>/<run-id>.json`), and how to run manually

## 3. Testing workflow

- [ ] 3.1 Create `.github/workflows/testing.yml` with `pull_request` trigger filtering `branches: ['junior-dev/**']` and `types: [opened, synchronize, reopened]`
- [ ] 3.2 Add workflow steps: checkout, Node setup, install jira CLI, install Claude Code CLI, configure git, write jira config, build prompt, run `claude -p` with appropriate `--allowedTools` (read PR diff via `gh pr diff`, post comments via `gh pr comment`, run tests via `npm test` etc.), convert JSONL to JSON
- [ ] 3.3 Add log-commit step: checkout `main`, write to `.github/agent-logs/testing/pr-${{ github.event.pull_request.number }}/${{ github.run_id }}.json`, commit and push

## 4. Junior Dev workflow — loop-back re-trigger

- [ ] 4.1 Add `issue_comment: [created]` trigger to `.github/workflows/junior-dev.yml` alongside the existing `workflow_dispatch` trigger
- [ ] 4.2 Add a guard job (or step on the existing `implement` job gated by `if:`) that: checks `github.event.issue.pull_request` is non-null (is a PR comment), checks head branch matches `junior-dev/**`, checks comment author is `github-actions[bot]`, checks comment body contains `<!-- testing-agent-loop-back -->`
- [ ] 4.3 In the guard, extract `ticket_key` from the branch name (`junior-dev/<TICKET_KEY>` → `<TICKET_KEY>`) and dispatch `gh workflow run junior-dev.yml -f ticket_key=<KEY>`
- [ ] 4.4 Ensure the `workflow_dispatch` job path is unaffected — both triggers can share the `implement` job via `if:` conditions or a separate re-dispatch job

## 5. Verification

- [ ] 5.1 Open a deliberately-failing test PR on a `junior-dev/TEST-*` branch and confirm: `testing.yml` fires, tests fail, loop-back comment appears with `<!-- testing-agent-loop-back -->` marker, Junior Dev re-dispatches exactly once
- [ ] 5.2 Confirm the hard cap: after 3 loop-back comments the next Testing run posts a gave-up comment and does NOT trigger another Junior Dev dispatch
- [ ] 5.3 Confirm log file exists at `.github/agent-logs/testing/pr-<n>/<run-id>.json` after each Testing run
