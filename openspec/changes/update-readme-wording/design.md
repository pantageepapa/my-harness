## Context

KAN-33 is an end-to-end test of the senior-dev spec-driven flow. The reporter
confirmed (Jira comment) that the desired change is a single one-word edit to the
root `README.md`, motivated solely by demonstrating that the developer pipeline
works. There is no architectural, security, performance, or migration complexity
here — this design doc exists only to satisfy the artifact build order and to
record the single judgment call (which word) explicitly.

## Goals / Non-Goals

**Goals:**
- Make exactly one word change to the root `README.md` tagline.
- Keep the edit reversible, semantically harmless, and verifiable.

**Non-Goals:**
- Any code, workflow, agent, or dependency change.
- Restructuring, expanding, or correcting other README content.
- Changing meaning beyond aligning vocabulary already used in the doc.

## Decisions

**Decision: change "drop" → "install" in the opening tagline (line 3).**

Rationale: The tagline currently reads "…glue that I drop into projects." The rest
of the README consistently frames the same action as *installing* — the script is
`scripts/install-harness.sh`, the section header is "Use this harness in another
project", and the steps say "After bootstrapping…". Swapping "drop" for "install"
makes the one-line summary consistent with the body and is a genuine (if tiny)
improvement rather than an arbitrary churn edit.

Alternatives considered:
- Changing a word in a less prominent line (e.g. inside a table) — rejected as less
  visible and therefore a weaker demonstration of the flow.
- A purely cosmetic synonym swap with no consistency benefit — rejected; even a test
  edit should leave the doc at least as good as before.

## Risks / Trade-offs

- [Reader could read more intent into a test edit than exists] → The proposal and
  this design state plainly that the change is a deliberate minimal flow test.
- [Merge conflict on README] → Negligible; single-line change, easily rebased.
