## ADDED Requirements

### Requirement: Root README tagline uses install-consistent terminology

The root `README.md` opening tagline SHALL describe the action of adding the
harness to another project using the verb "install", matching the terminology
used elsewhere in the README (`scripts/install-harness.sh` and the install
steps), rather than the informal "drop".

#### Scenario: Tagline reads "install into projects"

- **WHEN** a reader opens the root `README.md`
- **THEN** the opening tagline reads "Personal harness for agentic workflows: reusable agents and GitHub Actions glue that I install into projects."
- **AND** the word "drop" no longer appears in that tagline

#### Scenario: No other README content changes

- **WHEN** the change is applied
- **THEN** only the opening tagline line of `README.md` is modified
- **AND** all other sections, links, and tables remain byte-for-byte unchanged
