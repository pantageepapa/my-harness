## ADDED Requirements

### Requirement: Repository layout map

The top-level `README.md` SHALL document the repository's top-level structure so
a newcomer can orient without reading every section. It SHALL list each tracked
top-level directory — `agents/`, `.github/workflows/`, `.claude/`, `scripts/`,
`tools/`, `docs/`, `openspec/`, and `bin/` — and the key top-level config files
`.mcp.json` and `.env.example`, each paired with a one-line description of its
purpose. Every path named in this section MUST exist in the repository.

#### Scenario: Reader looks up where agents live

- **WHEN** a reader opens `README.md` and scans the repository-layout section
- **THEN** they find an entry for `agents/` describing it as the home of the
  per-agent prompts/configuration
- **AND** every other top-level directory and config file listed resolves to a
  real path in the repo

#### Scenario: Layout stays accurate

- **WHEN** the layout section names a path
- **THEN** that path exists in the repository at the time the change is made
- **AND** no listed path is invented or aspirational

### Requirement: Local prerequisites list

The top-level `README.md` SHALL list the command-line tools the workflows and
per-clone setup assume are available on `PATH`: `git`, `bash`, the `jira` CLI,
`gh`, `openspec`, and the `claude` CLI. Each entry SHALL include a one-line note
on where the tool comes from or how it is installed (for example, that the `jira`
CLI is installed locally via `scripts/install-jira-cli.sh`).

#### Scenario: Reader checks what to install

- **WHEN** a reader consults the prerequisites section before setting up a clone
- **THEN** they see each required CLI with a short note on its source
- **AND** the listed setup commands match those already documented elsewhere in
  the README (e.g. `scripts/install-jira-cli.sh`)

### Requirement: Additions are non-destructive

The change SHALL only add new content to `README.md`. It MUST NOT delete or
reword existing prose, and MUST NOT remove or alter the trailing HTML marker
comments (`<!-- log-commit verification -->`,
`<!-- pr-review test marker: v2 prompt -->`), which may be referenced by other
agents or tests.

#### Scenario: Existing content preserved

- **WHEN** the change is applied to `README.md`
- **THEN** all previously existing sections and their wording remain intact
- **AND** the trailing HTML marker comments are still present and unchanged
