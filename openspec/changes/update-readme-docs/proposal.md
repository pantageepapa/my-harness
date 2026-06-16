## Why

The top-level `README.md` explains how to install and configure the harness, but
it never gives a newcomer a quick map of the repository or a checklist of the
local tools the workflows assume are on `PATH`. A reader has to infer the
directory structure and prerequisites by reading every section. KAN-33 asks for
modifications to the README; the highest-value, lowest-risk change is to add the
two orientation sections the current document is missing.

## What Changes

- Add a **Repository layout** section near the top of `README.md`: a concise
  table/tree mapping each top-level directory (`agents/`, `.github/workflows/`,
  `.claude/`, `scripts/`, `tools/`, `docs/`, `openspec/`, `bin/`) and key config
  files (`.mcp.json`, `.env.example`) to a one-line purpose.
- Add a **Prerequisites** section listing the CLIs the workflows and per-clone
  setup assume exist locally (`git`, `bash`, the `jira` CLI, `gh`, `openspec`,
  and the `claude` CLI), with a one-line note on where each comes from.
- Changes are **additive documentation only**: no existing prose is removed or
  reworded, and the stray HTML marker comments at the end of the file are left
  untouched (they may be referenced by other agents/tests).
- No code, workflow, or agent-prompt changes.

## Capabilities

### New Capabilities
- `readme-onboarding`: Defines the orientation content the top-level `README.md`
  must provide to a newcomer — a repository-layout map and a local-tooling
  prerequisites list — and the constraint that these additions are non-destructive.

### Modified Capabilities
<!-- None. No existing OpenSpec specs exist (openspec/specs/ is empty), and no
     prior behavioral contract is being changed. -->

## Impact

- **Files:** `README.md` (additive edits only).
- **Code / APIs / dependencies:** none.
- **Risk:** minimal — documentation-only; the installer never overwrites a
  target repo's own README, so downstream clones are unaffected.
