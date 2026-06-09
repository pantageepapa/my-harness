# my-harness

Personal harness for agentic workflows: reusable agents and GitHub Actions
glue that I use across projects.

## What's here

- [`agents/pr-review`](agents/pr-review) — a comment-only PR reviewer that
  runs as a GitHub Action.
- [`agents/jira-ticket`](agents/jira-ticket) — a daily Jira ticket groomer
  (descriptions, links, sub-tasks) backed by the project-local `jira` CLI.
- [`docs/agentic-workflow.md`](docs/agentic-workflow.md) — notes on how the
  pieces fit together.

## Setup

This is a scaffold — every clone wires its own Jira instance / project.
Nothing about the maintainer's setup is committed.

One-time, per-clone:

```sh
# 1. drop a project-local jira binary into ./bin/ (no brew needed)
bash scripts/install-jira-cli.sh

# 2. paste an Atlassian API token into a gitignored .env
cp .env.example .env
# edit .env, paste token after JIRA_API_TOKEN=
# generate one at: https://id.atlassian.com/manage-profile/security/api-tokens

# 3. wire this clone to your Jira instance / project
bash scripts/jira-init.sh
```

`scripts/jira-init.sh` sources `.env`, runs `jira init` to write
`.jira/config.yml` (gitignored), and smoke-tests with `jira me`. The
install script also accepts an existing system `jira` on `PATH` if you
prefer brew.

For day-to-day CLI use in this repo:
`source .env && export JIRA_CONFIG_FILE=$PWD/.jira/config.yml`
(or use [direnv](https://direnv.net) with an `.envrc` that does the same).

## Adding a new agent

1. Drop the prompt in `agents/<name>/prompt.md`.
2. Wire a workflow in `.github/workflows/<name>.yml` that feeds the prompt to
   `anthropics/claude-code-action@v1`.
3. Set `CLAUDE_CODE_OAUTH_TOKEN` as a repo secret.

## Context7 setup

The `pr-review` agent uses the Context7 MCP server (`@upstash/context7-mcp`,
run via `npx`) to verify library/SDK references before commenting on them.
Wire it once:

1. Generate an API key at https://context7.com/dashboard.
2. **Local**: paste it into `.env` as `CONTEXT7_API_KEY=...`. The key is
   read from the `--api-key` flag passed in `.mcp.json`.
3. **CI**: add the same value as a `CONTEXT7_API_KEY` repo secret. The
   workflow's `settings.env` propagates it into the spawned MCP server.
4. The package also accepts a `--cache-ttl` flag to control how long fetched
   docs are cached locally — defaults to 24h if unset.

<!-- log-commit verification -->

<!-- pr-review test marker: v2 prompt -->
