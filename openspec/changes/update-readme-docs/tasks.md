## 1. Repository layout section

- [x] 1.1 Confirm the current set of top-level directories and config files
  (`agents/`, `.github/workflows/`, `.claude/`, `scripts/`, `tools/`, `docs/`,
  `openspec/`, `bin/`, `.mcp.json`, `.env.example`) against the working tree.
- [x] 1.2 Insert a `## Repository layout` section after the intro "What's here"
  list (before the first `---` divider) as a two-column Markdown table mapping
  each path to a one-line purpose.

## 2. Prerequisites section

- [x] 2.1 Insert a `## Prerequisites` section just before the
  "Use this harness in another project" section, listing `git`, `bash`, the
  `jira` CLI, `gh`, `openspec`, and the `claude` CLI, each with a one-line
  source/install note consistent with commands already in the README.

## 3. Verification

- [x] 3.1 Confirm the edits are additive: no existing prose removed or reworded,
  and the trailing HTML marker comments are still present and unchanged.
- [x] 3.2 Verify every path named in the new layout section resolves to a real
  path in the repo.
- [x] 3.3 Render/preview the Markdown to confirm both new sections are
  well-formed (tables and lists parse correctly).
