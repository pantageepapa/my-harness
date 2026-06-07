# Prompt Improver agent

Reads one execution log of another agent and, if it finds a concrete
weakness, edits that agent's `prompt.md`. A downstream step in the
workflow opens a PR with the edit for human review. If there's nothing
worth changing, the run exits silently.

Part of the agentic workflow sketched in [`docs/agentic-workflow.md`](../../docs/agentic-workflow.md).

## Files

- `prompt.md` — generic improver prompt. Never names a specific agent.
- `../../.github/workflows/prompt-improver.yml` — workflow that runs it.

## How it runs

`prompt-improver.yml` is `workflow_dispatch`-only and takes three inputs:

- `agent_name` — must match `agents/<name>/prompt.md`.
- `log_path` — repo path to the just-committed log JSON.
- `log_ref` — branch the log was committed to (PR branch for pr-review,
  `main` for jira-ticket).

Each agent's own workflow ends with one step that fires this workflow:

```yaml
- name: Trigger prompt improver
  if: always() && steps.claude.outputs.execution_file != ''
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh workflow run prompt-improver.yml \
      -f agent_name=<name> \
      -f log_path=<repo-path-to-log.json> \
      -f log_ref=<branch>
```

That step needs `actions: write` in the calling workflow's permissions.

## Opting in a new agent

1. Live at `agents/<name>/prompt.md`.
2. Commit run logs anywhere — pass the path explicitly.
3. Add the trigger step above to the agent's workflow.
4. Grant `actions: write`.

## What it will and won't do

The improver edits *only* `agents/<agent_name>/prompt.md`. It is told to
make the smallest change that addresses an issue grounded in the run, or
to do nothing. The PR is the human checkpoint — review the diff and
merge if it holds up.
