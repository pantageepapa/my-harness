## ADDED Requirements

### Requirement: Testing agent workflow triggers on Junior Dev PRs
The system SHALL trigger the Testing agent (`testing.yml`) on `pull_request` events with event types `opened`, `synchronize`, and `reopened` for branches matching `junior-dev/**`.

#### Scenario: New Junior Dev PR opens
- **WHEN** a PR is opened with head branch matching `junior-dev/**`
- **THEN** `testing.yml` starts a new job run for that PR

#### Scenario: Junior Dev pushes a new commit to an existing PR
- **WHEN** a commit is pushed to a branch matching `junior-dev/**` that already has an open PR
- **THEN** `testing.yml` starts a new job run for that PR

#### Scenario: Non-Junior-Dev PR is opened
- **WHEN** a PR is opened with head branch NOT matching `junior-dev/**`
- **THEN** `testing.yml` does NOT run

### Requirement: Testing agent writes and runs tests
The Testing agent SHALL read the PR diff, write tests appropriate to the changed code, run those tests, and capture the pass/fail result.

#### Scenario: Tests pass
- **WHEN** the Testing agent runs and all tests pass
- **THEN** the agent posts no loop-back comment and takes no further action (PR is left as-is for human review)

#### Scenario: Tests fail
- **WHEN** the Testing agent runs and one or more tests fail
- **THEN** the agent posts a structured loop-back comment on the PR (subject to the retry cap)

### Requirement: Testing agent enforces a hard retry cap
The Testing agent SHALL count existing loop-back comments (identified by the `testing-agent-loop-back` HTML marker) on the PR before posting a new one. If the count equals or exceeds the cap (3), it SHALL post a `testing-agent-gave-up` comment instead and stop without triggering another Junior Dev run.

#### Scenario: Retry count below cap
- **WHEN** tests fail AND the count of prior loop-back comments on the PR is less than 3
- **THEN** the agent posts a structured loop-back comment with the current retry number

#### Scenario: Retry cap reached
- **WHEN** tests fail AND the count of prior loop-back comments on the PR equals or exceeds 3
- **THEN** the agent posts a `testing-agent-gave-up` comment (no loop-back marker) and does NOT trigger another Junior Dev run

### Requirement: Testing agent posts a structured loop-back comment
When re-triggering the Junior Dev agent, the Testing agent SHALL post an `issue_comment` on the PR whose body contains:
1. An HTML comment marker `<!-- testing-agent-loop-back -->` on its own line.
2. A fenced JSON block containing at minimum the keys `"type": "testing-agent-loop-back"`, `"retry": <n>` (1-indexed), and `"run_id": "<github-run-id>"`.
3. A human-readable summary of which tests failed.

#### Scenario: Loop-back comment structure
- **WHEN** the Testing agent posts a loop-back comment
- **THEN** the comment body contains the `<!-- testing-agent-loop-back -->` HTML marker AND a JSON fenced block with `type`, `retry`, and `run_id` fields

### Requirement: Testing agent commits run log
After each run (pass or fail), the Testing agent workflow SHALL commit the execution JSONL log to `main` at `.github/agent-logs/testing/pr-<pr_number>/<run_id>.json`.

#### Scenario: Log committed after successful test run
- **WHEN** the Testing agent run completes with tests passing
- **THEN** an execution log is committed to `main` under `.github/agent-logs/testing/pr-<pr_number>/<run_id>.json`

#### Scenario: Log committed after failed test run
- **WHEN** the Testing agent run completes with tests failing
- **THEN** an execution log is committed to `main` under `.github/agent-logs/testing/pr-<pr_number>/<run_id>.json`
