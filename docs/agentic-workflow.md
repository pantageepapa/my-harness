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
        ├──── complex ────► Senior developer agent  (/openspec:explore)
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
                                  │   (/goal or /ralph-loop)
                                  ▼               │
                            Testing agent ────────┘
                          (loops back to dev
                           agent on failure)
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
- Decomposes tickets and improves descriptions based on the current code.
- Creates dependencies between tickets (`blocks`, `depends on`).

### Development Orchestrator
**Goal:** decide which development agent to launch for each ticket.

- Reads the ticket.
- Decides the complexity (complex vs. easy) and routes accordingly.

### Senior Developer Agent — `/openspec:explore`
**Goal:** tackle complex tasks **with a human in the loop**.

- Uses spec-driven development.
- Requests human input before moving to implementation.

### Junior Developer Agent — `/goal` or `/ralph-loop`
**Goal:** tackle easy tasks **without a human in the loop**.

- Uses headless Claude, planning straight through to execution.
- Creates a PR and launches the testing agent.

### Testing Agent
**Goal:** write dedicated tests and run them.

- If tests fail, hands the work back to the developer agent.

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
- **Junior ↔ Testing tight loop.** The easy path stays fully autonomous —
  failures bounce inside the loop, not back to a human.
- **Review ↔ Refinement as an adversarial pair.** Using a different model for
  refinement is a deliberate hedge against single-model review bias.
- **Daily cadence** on review and refinement rather than per-PR-event triggers.

## Open questions (for follow-up)

- How is "complex vs. easy" actually decided? Heuristic, classifier, or LLM
  judgment with calibration?
- Where does the orchestrator live (cron, webhook, queue)?
- What stops the Junior↔Testing loop from running forever on a hard ticket?
- How does the Refinement agent know when to stop counteracting?
- How are the two daily passes (review + refinement) sequenced — same run, or
  staggered?
