## Context

`README.md` is the single entry point for someone adopting this harness. It
already covers installation, GitHub Actions configuration, the Jira → GitHub
trigger, and how to add an agent. It lacks two pieces of orientation: a map of
the repository's top-level layout, and an explicit list of the local CLIs the
workflows assume. This is a documentation-only change driven by KAN-33; there is
no code, dependency, or data-model impact. A design doc is included mainly
because the OpenSpec `tasks` artifact depends on it — the "how" here is limited
to placement and wording decisions.

## Goals / Non-Goals

**Goals:**
- Give a newcomer a one-screen map of the repo and a setup-tool checklist.
- Keep every documented path and command accurate against the current repo.
- Make purely additive edits — no risk to existing content.

**Non-Goals:**
- Rewriting or restructuring existing README sections.
- Removing the trailing HTML marker comments (left intact deliberately).
- Documenting per-agent internals (those live in `agents/*/README.md`).
- Any change to code, workflows, or agent prompts.

## Decisions

- **Placement of "Repository layout":** insert it immediately after the intro
  "What's here" bullet list (around current line 23, before the `---` divider).
  Rationale: orientation belongs up top, and it complements the existing
  "What's here" list (which is feature-oriented) with a structural view.
  Alternative considered: a single combined section — rejected to avoid
  reworking the existing list (keeps the change additive).
- **Format — table vs. tree:** use a two-column Markdown table (path → purpose),
  matching the table style already used in the GitHub Actions section.
  Alternative: an ASCII tree — rejected as harder to keep aligned and less
  consistent with the document's existing style.
- **Placement of "Prerequisites":** insert it just before the existing
  "Use this harness in another project" section, so a reader sees required tools
  before the setup commands that use them.
- **Source of truth for both sections:** derive entries only from paths that
  currently exist in the repo and commands already referenced in the README, so
  the additions cannot drift from reality at authoring time.

## Risks / Trade-offs

- [Documentation drift — layout/prereqs go stale as the repo evolves] →
  Mitigation: keep descriptions short and structural; the spec requires every
  listed path to exist when the change is made.
- [Accidentally touching the trailing marker comments] → Mitigation: the spec
  and tasks call out leaving them untouched; verification step greps for them
  after editing.
- [Section placement nudges line numbers referenced elsewhere] → Low impact:
  no other file references README line numbers; edits are append/insert only.
