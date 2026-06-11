## MODIFIED Requirements

### Requirement: Junior Dev workflow re-dispatches on Testing agent loop-back comment
The Junior Dev workflow (`junior-dev.yml`) SHALL gain an `issue_comment` trigger. When a new comment is created on an issue/PR, the workflow SHALL:
1. Verify the PR head branch matches `junior-dev/**`.
2. Verify the comment body contains the `<!-- testing-agent-loop-back -->` HTML marker.
3. Verify the comment author is `github-actions[bot]`.
4. If all three conditions are true: extract the `ticket_key` from the branch name and dispatch a new Junior Dev run for that ticket key.

#### Scenario: Loop-back comment triggers re-dispatch
- **WHEN** a comment is posted on a `junior-dev/**` PR whose body contains `<!-- testing-agent-loop-back -->` and whose author is `github-actions[bot]`
- **THEN** the Junior Dev workflow dispatches a new `junior-dev.yml` run with the ticket key extracted from the branch name

#### Scenario: Ordinary PR comment does not trigger re-dispatch
- **WHEN** a comment is posted on a `junior-dev/**` PR that does NOT contain the `<!-- testing-agent-loop-back -->` marker
- **THEN** the Junior Dev workflow does NOT dispatch a new run

#### Scenario: Testing agent gave-up comment does not trigger re-dispatch
- **WHEN** a comment is posted on a `junior-dev/**` PR whose body contains `<!-- testing-agent-gave-up -->` (no loop-back marker)
- **THEN** the Junior Dev workflow does NOT dispatch a new run
