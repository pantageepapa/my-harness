# Development Orchestrator agent

Daily router for groomed Jira tickets. Reads each **Development Ready**
ticket's story-point estimate, dispatches `junior-dev.yml` (easy path) or
`senior-dev.yml` (complex path), and transitions the ticket to **In
Progress** so it isn't re-dispatched. Tickets without an estimate are
skipped and surfaced in Slack.

Part of the agentic workflow sketched in
[`docs/agentic-workflow.md`](../../docs/agentic-workflow.md), sitting
between the Ticket agent and the dev agents.

## Files

- `prompt.md` — the agent's prompt. Edit this to change behavior.
- `../../.github/workflows/orchestrator.yml` — workflow that runs the agent.

## How easy vs. complex is decided

The agentic-workflow doc lists three options for the complexity gate:
heuristic, classifier, or LLM judgment with calibration. We picked
**story points** instead — a fourth option that emerged once we noticed
the Ticket agent already drives a human review loop where estimates can
be set.

| Story points (`customfield_10016`) | Path |
| ---------------------------------- | ---- |
| `1`, `2`, `3`                      | Junior — autonomous. |
| `≥ 4`                              | Senior — human-in-the-loop (spec-driven, OpenSpec). |
| `null` / unset / non-numeric       | Skip + surface in Slack as *Unpointed — needs estimate*. |

**Why story points over the doc's three options:**

- *Deterministic.* Same inputs → same routing. No prompt drift, no
  classifier retraining.
- *Already produced by humans.* The Ticket agent groomed the ticket and
  a human transitioned it to Dev Ready; estimating is a natural
  extension of that review, not new work.
- *Reuses Jira state.* No extra labels, comments, or sidecars. The
  estimate is visible to humans on the board where they expect to see it.
- *Cheap to override.* If a 3-pointer turns out to be complex, a human
  re-estimates and the next orchestrator run routes it correctly.

The downside — humans must point tickets — is mitigated by the explicit
*Unpointed* section in the Slack summary. Unpointed tickets stay in Dev
Ready and are surfaced every run until estimated.

## How it runs

The workflow `orchestrator.yml` triggers on a daily cron (`47 7 * * *`
UTC, staggered after the Ticket agent's `17 7 * * *`) and on
`workflow_dispatch`. It checks out the repo, installs the pinned
`bin/jira` via `scripts/install-jira-cli.sh`, materializes
`.jira/config.yml` from repo variables and the `JIRA_API_TOKEN` secret,
prepends `JIRA_PROJECT_KEY` to `prompt.md`, and feeds the result to
`anthropics/claude-code-action@v1`. The action runs a headless Claude
Code session with `jira` and `gh` on `PATH`.

Dispatch uses `gh workflow run senior-dev.yml -f ticket_key=KEY`
(matching the existing pattern in
[`jira-ticket.yml`](../../.github/workflows/jira-ticket.yml) where
`agent-improver.yml` is invoked the same way). `repository_dispatch`
was considered but rejected — no other workflow in this repo uses it,
and `gh workflow run` is sufficient with a single string input.

`track_progress: true` is enabled — execution status is captured for the
log.

## Manual run

```sh
gh workflow run orchestrator.yml
```

Useful for re-runs after a token rotation or a prompt change.

## Editing the prompt

Edit `prompt.md` directly. The workflow reads it at run-time, so a change
takes effect on the next workflow run.

## Senior / Junior dev workflows

Both paths are implemented: `junior-dev.yml`
([KAN-2](https://jaeyoonsworkspace-23358853.atlassian.net/browse/KAN-2),
see [`agents/junior-dev/README.md`](../junior-dev/README.md)) and
`senior-dev.yml`
([KAN-4](https://jaeyoonsworkspace-23358853.atlassian.net/browse/KAN-4),
see [`agents/senior-dev/README.md`](../senior-dev/README.md)). The
orchestrator only ever dispatches with `-f ticket_key=KEY`; senior-dev's
extra `phase` input defaults to `propose`, which is exactly the
spec-first entry point the complex path wants.

## Required setup (one-time, per clone)

Same Jira variables and secrets as the Ticket agent (see
[`agents/jira-ticket/README.md`](../jira-ticket/README.md)). No
additional setup — the workflow uses the auto-provided
`secrets.GITHUB_TOKEN` for `gh workflow run`.

## Logs

Each run's execution log is committed back to `main` at
`.github/agent-logs/orchestrator/<YYYY-MM-DD>/<run-id>.json`. Browse with
`bash tools/viewer.sh`.
