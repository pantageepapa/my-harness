# Senior Developer agent

Spec-driven implementation agent for "complex" Jira tickets (story
points ≥ 4), with a **human checkpoint between spec and
implementation**. The agent explores the code, writes an OpenSpec
change proposal, opens a Draft PR, and stops. A human reviews the spec
in the PR; their review verdict resumes the agent into revision or
implementation. The checkpoint exists to stop wasted implementation
work on misunderstood requirements.

Part of the agentic workflow sketched in
[`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Files

- `prompt.md` — the agent's prompt (phase-conditional). Edit this to
  change behavior.
- `../../.github/workflows/senior-dev.yml` — workflow that runs the
  agent (all three phases).
- `../../.github/workflows/senior-dev-resume.yml` — thin
  `pull_request_review` trigger that maps human review verdicts to
  phase dispatches.
- `../../openspec/` — OpenSpec scaffolding (`openspec init`), where
  change proposals live.

## How it runs

```
orchestrator ──dispatch(ticket_key)──► senior-dev.yml [phase=propose]
                                          │ explore, write OpenSpec change,
                                          │ open Draft PR, STOP
                                          ▼
              human reviews the spec diff in the Draft PR
              (comments = discussion; nothing runs meanwhile)
                          │                            │
              "Request changes" review          "Approve" review
                          │                            │
              senior-dev-resume.yml (draft-gated, permission-checked)
                          │                            │
            senior-dev.yml [phase=revise]   senior-dev.yml [phase=implement]
              update spec, push, STOP         execute tasks.md, push,
              (review again)                  mark PR ready-for-review
                                              (pr-review.yml takes over)
```

There is **no running process while a human reviews** — each phase is
a separate headless `claude -p` run, and all state lives on the
`senior-dev/<TICKET_KEY>` branch and its PR thread. A resumed run
re-reads the ticket, the committed spec, and the full PR conversation
(including inline review comments) from scratch.

Dispatches come from three places:

- **Automated** — the Development Orchestrator's post-step fires
  `phase=propose` for every Dev-Ready ticket with story points ≥ 4,
  then transitions the ticket to **In Progress**.
- **Reviews** — `senior-dev-resume.yml` fires `phase=revise` /
  `phase=implement` from human review verdicts (see below).
- **Manual** — `gh workflow run senior-dev.yml -f ticket_key=KAN-42
  [-f phase=...]`.

## Decision: spec exploration via the OpenSpec library

KAN-4 required choosing how the spec gets produced, because the
`/openspec:explore` command referenced in `docs/agentic-workflow.md`
**does not exist** — it is neither a built-in Claude Code command nor
a skill in this repo.

What was verified: the real [OpenSpec](https://github.com/Fission-AI/OpenSpec)
project (v1.3.x at time of writing) ships exactly this workflow,
installed per-repo by `openspec init --tools claude`
(non-interactive) as skills under `.claude/skills/openspec-*/` plus
`/opsx:*` command wrappers under `.claude/commands/opsx/`. The init
also scaffolds `openspec/` (changes/, specs/, config.yaml).

**Choice: vendor the real library** rather than imitating its format
in the prompt:

- The artifact conventions (proposal/design/tasks/specs) are
  maintained upstream and driven by the CLI: `openspec new change`
  scaffolds, `openspec instructions <artifact> --json` supplies each
  artifact's template and rules, and `openspec status --json` is the
  machine-checkable definition of "spec complete" (all
  `applyRequires` artifacts done).
- This agent runs **headless `claude -p`** (not
  `claude-code-action@v1`, whose PR-comment plumbing is dead weight
  here — same runtime-split rationale as junior-dev). The prompt
  therefore doesn't depend on interactive slash-command invocation:
  it points the agent at the vendored opsx instruction files and the
  `openspec` CLI, which work identically in print mode.
- The workflow installs the CLI on the runner
  (`npm install -g @fission-ai/openspec`).

## Decision: human-in-the-loop via native PR reviews

KAN-4 offered (A) draft PR + magic-keyword comment, or (B) Jira
comment + transition. **Choice: a refinement of (A) — draft PR +
native GitHub review verdicts** instead of magic keywords:

- **Approve** (on the draft spec PR) → dispatches `phase=implement`.
- **Request changes** (body = feedback) → dispatches `phase=revise`.
- **Comment-only reviews and ordinary comments** → inert; they're
  discussion the agent reads on its next run. This is the "answer
  questions without triggering anything" channel.
- Inline review comments on specific spec lines work and reach the
  agent (it reads `pulls/<n>/comments` via `gh api`).

Why this beats the alternatives:

- vs. **magic keywords**: nothing to remember or typo; approval is
  the same button reviewers already use; inline-on-spec-line feedback
  comes for free.
- vs. **Jira (B)**: `pull_request_review` is a native Actions
  trigger, while Jira transitions would need Jira Automation →
  `repository_dispatch` webhook plumbing; spec diffs render properly
  in a PR and poorly in Jira comments.

Safety rails in `senior-dev-resume.yml`:

- **Draft-gated** — reviews only act while the PR is a draft. After
  `implement` flips it to ready, Approve/Request-changes mean
  ordinary code review again, and the resume workflow ignores them.
- **Permission-gated** — the reviewer's `author_association` must be
  `OWNER`/`MEMBER`/`COLLABORATOR`; drive-by reviews don't dispatch.
- **Acknowledged** — the workflow posts a PR comment naming the phase
  it dispatched, so the human knows the review landed.

### Adaptive questions-only mode

The propose phase decides for itself whether the ticket is specable:

- **Confident** → full OpenSpec change + an *Assumptions* section.
- **Blocked** → the Draft PR carries `proposal.md` with the gathered
  context and numbered blocking questions only — no design/tasks
  built on guesses. Humans answer in comments and submit **Request
  changes**, which re-runs the spec phase with the answers.

## Manual run

```sh
# spec phase (what the orchestrator dispatches)
gh workflow run senior-dev.yml -f ticket_key=KAN-42

# resume phases are normally review-triggered, but can be forced:
gh workflow run senior-dev.yml -f ticket_key=KAN-42 -f phase=implement
```

Optional `max_turns` overrides `--max-turns` (phase defaults:
propose 30, revise 20, implement 60). Use a small value to exercise
the stop condition; the propose fallback opens a `[WIP]` Draft PR,
and resumed phases post an early-exit PR comment instead.

## Logs

Each run (any phase) commits its execution log to `main` at
`.github/agent-logs/senior-dev/<YYYY-MM-DD>/<run-id>.json` (same
`jq -s` array format as junior-dev) and dispatches agent-improver
with `agent_name=senior-dev`. Browse with `bash tools/viewer.sh`.

## Required setup

Same as junior-dev (see
[`agents/junior-dev/README.md`](../junior-dev/README.md)):
`CLAUDE_CODE_OAUTH_TOKEN`, Jira secrets/variables, **`DEV_PAT`**, and
the *Allow GitHub Actions to create and approve pull requests* repo
setting. Notes specific to this agent:

- `DEV_PAT` matters doubly here: PRs/comments it authors trigger
  downstream workflows, and `gh pr ready` flipping the PR fires
  `pr-review.yml`'s `ready_for_review` trigger.
- `senior-dev-resume.yml` needs no extra secrets — it only uses
  `GITHUB_TOKEN` (`actions: write` to dispatch, `pull-requests:
  write` to ack). Explicit `gh workflow run` dispatches from
  `GITHUB_TOKEN` are allowed; the no-recursive-workflows rule only
  blocks *event-caused* triggers.

## Known limitations

- **Resume requires the workflows on `main`.** `pull_request_review`
  runs the workflow definition from the PR's base context, so the
  full loop can only be exercised after this lands on the default
  branch. The propose phase can be tested from any branch via
  `gh workflow run --ref`.
- **Re-review = re-dispatch.** Submitting Approve twice dispatches
  two implement runs; there's no dedup/lock. The ack comment makes
  this visible, and the second run mostly no-ops on an already-done
  tasks.md, but don't do it on purpose.
- **No automatic `/opsx:archive`.** After the implementation PR
  merges, archiving the change into `openspec/specs/` is a human (or
  future-agent) step.
- **No automated test enforcement** beyond what the agent chooses to
  run — same gap as junior-dev.
