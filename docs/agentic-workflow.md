# Agentic Development Workflow

> **Status:** First-draft vision. Extracted from a hand-drawn diagram (2026-06-04).
> Not yet scoped, designed, or implemented.

The flow describes an end-to-end pipeline where humans create tickets and merge
final PRs, and a chain of agents handles everything in between: ticket grooming,
complexity routing, implementation, testing, review, and refinement.

## High-level flow

```
Humans create tickets
        │
        ▼
   Ticket Agent
        │
        ▼
Development Orchestrator
        │
        ├──── complex ────► Senior developer agent  (OpenSpec /opsx)
        │                          │
        │                          ▼
        │                    PR Review agent ◄────┐
        │                          ▲              │
        │                          ▼              │
        │                    PR Refinement agent  │
        │                          │              │
        │                          ▼              │
        │                Humans test & merge PR   │
        │                                         │
        └──── easy ──────► Junior developer agent │
                                  │   (headless `claude -p`, --max-turns)
                                  ▼               │
                              Draft PR ───────────┘
                          (human picks up &
                           merges, or re-runs)
```

## Human touchpoints

- **Start:** humans create tickets.
- **End:** humans test the final PR and merge it.
- **Mid-loop (complex path only):** the Senior developer agent pulls a human
  into the loop before implementing.

## Agents

### Ticket Agent
**Goal:** manage Jira tickets.

- Does **not** invent new tickets.
- Works on a daily basis. 
- Decomposes tickets and improves descriptions based on the current code.
- Creates dependencies between tickets (`blocks`, `depends on`).

### Development Orchestrator
**Goal:** decide which development agent to launch for each ticket.

- **Deterministic, no LLM.** Pure routing on Jira story points: SP ≤ 3 →
  junior, SP ≥ 4 → senior. Unpointed tickets fail the workflow loudly so
  the team re-estimates before anything implements.
- **Triggered per-ticket** by a Jira automation rule on the "Dev Ready"
  status transition (GitHub `repository_dispatch`), not on a daily cron.

### Senior Developer Agent — OpenSpec (`/opsx` conventions)
**Goal:** tackle complex tasks **with a human in the loop**.

- Uses spec-driven development via the [OpenSpec](https://github.com/Fission-AI/OpenSpec)
  library (the originally sketched `/openspec:explore` doesn't exist;
  OpenSpec's `/opsx:*` commands are the real equivalent — see
  [`agents/senior-dev/README.md`](../agents/senior-dev/README.md)).
- Requests human input before moving to implementation: spec lands as a
  Draft PR; a native PR review (Approve / Request changes) resumes the
  agent into implement / revise.
- Same runtime shape as Junior: headless `claude -p` on a GHA runner with
  `--max-turns` and a workflow timeout. The OpenSpec conventions and
  human-in-the-loop pauses layer on top of that base.

### Junior Developer Agent
**Goal:** tackle easy tasks **without a human in the loop**.

- Headless `claude -p` invoked directly from a GitHub Actions workflow
  (no skill wrapper). Plans straight through to execution.
- Bounded by `--max-turns` per dispatch + a workflow-level `timeout-minutes`.
- Creates a Draft PR; a human picks it up from there.

### PR Review Agent
**Goal:** daily review of updated PRs.

- Inline comments.
- Severity.
- Reasoning.

### PR Refinement Agent
**Goal:** daily refinement of the PR.

- May use a different model (e.g. CODEX).
- Counteracts the review (acts as a deliberate counter-voice to the reviewer).

## Design choices worth calling out

- **Complexity gate at the orchestrator.** Two-tier routing keeps the
  human-in-the-loop cost only on work that needs it.
- **Runtime split.** `claude-code-action` for read/triage surfaces
  (ticket grooming, PR review, agent-improver); raw `claude -p` for
  implementation lanes (junior-dev, senior-dev); plain bash for the
  orchestrator (no LLM). The action's PR-comment plumbing is dead weight
  when the agent's job is to edit files, push a branch, and open a PR.
- **Bounded dev-agent runs.** `--max-turns` per dispatch + `timeout-minutes`
  on the job stop a hard ticket from spinning forever. Tickets stay in
  **In Progress** so the orchestrator won't re-fire them.
- **Review ↔ Refinement as an adversarial pair.** Using a different model for
  refinement is a deliberate hedge against single-model review bias.
- **Daily cadence** on review and refinement rather than per-PR-event triggers.

## Open questions (for follow-up)

- How does the Refinement agent know when to stop counteracting?
- How are the two daily passes (review + refinement) sequenced — same run, or
  staggered?
