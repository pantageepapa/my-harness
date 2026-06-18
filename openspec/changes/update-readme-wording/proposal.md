## Why

The Jira ticket (KAN-33) is a deliberate end-to-end test of the senior-dev
spec-driven developer flow. Per the reporter's clarifying comment, the goal is a
single, low-risk, one-word edit to the **root `README.md`** whose only purpose is
to demonstrate that the propose → review → implement pipeline works. The change
must be real and verifiable, but intentionally minimal.

## What Changes

- Make one word change to the root `README.md` tagline.
- Specifically, change the verb in the opening tagline from "drop" to "install"
  so the project's one-line description aligns with the terminology already used
  throughout the rest of the README (`scripts/install-harness.sh`,
  "After bootstrapping…", the install steps), where the action is consistently
  called "install".
- No code, workflow, agent, or behavioral changes. Documentation only.

## Capabilities

### New Capabilities
- `readme-tagline`: Governs the wording of the root `README.md` opening tagline
  so it uses install-consistent terminology.

### Modified Capabilities
<!-- None: no existing specs in openspec/specs/, and no existing requirements change. -->

## Impact

- Affected file: `README.md` (line 3, the opening tagline only).
- No code, tests, CI workflows, agents, or dependencies are affected.
- Reversible single-word edit; zero runtime impact.
