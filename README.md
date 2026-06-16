# my-harness

Personal harness for agentic workflows: reusable agents and GitHub Actions
glue that I drop into projects.

## Contents

- [What's here](#whats-here)
- [Use this harness in another project](#use-this-harness-in-another-project)
- [GitHub Actions configuration](#github-actions-configuration)
- [Jira → GitHub automation (Dev Ready trigger)](#jira--github-automation-dev-ready-trigger)
- [Adding a new agent](#adding-a-new-agent)

## What's here

- [`agents/pr-review`](agents/pr-review) — comment-only PR reviewer.
- [`agents/jira-ticket`](agents/jira-ticket) — daily Jira backlog groomer.
- [`agents/junior-dev`](agents/junior-dev) — headless implementer for small
  tickets (SP ≤ 3).
- [`agents/senior-dev`](agents/senior-dev) — OpenSpec-driven implementer
  for complex tickets, with a human-in-the-loop pause on the spec PR.
- [`agents/agent-improver`](agents/agent-improver) — meta-agent that
  proposes prompt edits from execution logs.
- [`.github/workflows/orchestrator.yml`](.github/workflows/orchestrator.yml)
  — deterministic Jira → junior/senior router on the **Dev Ready**
  transition.
- [`scripts/install-harness.sh`](scripts/install-harness.sh) — copy this harness into
  another repo (see below).
- [`docs/agentic-workflow.md`](docs/agentic-workflow.md) — how the pieces
  fit together.

---

## Use this harness in another project

`scripts/install-harness.sh` `rsync`s every tracked file from this repo into a
target repo, skipping per-clone state (`.env`, `.jira/config.yml`,
`bin/.jira-bin`, agent-log history). Default is dry-run.

```sh
# from anywhere
bash /path/to/my-harness/scripts/install-harness.sh ~/Dev/other-repo            # dry-run
bash /path/to/my-harness/scripts/install-harness.sh ~/Dev/other-repo --apply    # do it
```

What gets copied: `.github/workflows/`, `agents/`, `.claude/`, `.mcp.json`,
`scripts/`, `tools/`, `docs/`, `openspec/`, `.env.example`, `.jira/.gitkeep`.

What's left alone in the target:
- The target's existing `README.md` — never overwritten.
- The target's existing `.gitignore` — harness rules are appended in a
  delimited `# --- my-harness ---` block. Re-running won't duplicate.
- Anything not tracked in the harness (project source, `node_modules`, etc.).

After bootstrapping, run the per-clone setup in the target repo:

```sh
# 1. project-local jira binary into ./bin/ (no brew needed)
bash scripts/install-jira-cli.sh

# 2. paste tokens into a gitignored .env
cp .env.example .env
# JIRA_API_TOKEN=...      https://id.atlassian.com/manage-profile/security/api-tokens
# CONTEXT7_API_KEY=...    https://context7.com/dashboard

# 3. wire this clone to a Jira instance / project
bash scripts/jira-init.sh
```

`jira-init.sh` writes `.jira/config.yml` (gitignored). For day-to-day CLI
use: `source .env && export JIRA_CONFIG_FILE=$PWD/.jira/config.yml`, or
let the `bin/jira` wrapper handle it (it auto-injects `JIRA_CONFIG_FILE`
from the repo root).

---

## GitHub Actions configuration

The workflows read repo **secrets** (sensitive) and repo **variables**
(non-sensitive) from *Settings → Secrets and variables → Actions*. Set
these once per target repo.

### Secrets

| Name | Used by | Source |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | every Claude-driven workflow | Run `claude` locally and grab the token, or use an Anthropic API key |
| `JIRA_API_TOKEN` | jira-ticket, orchestrator, junior-dev, senior-dev | <https://id.atlassian.com/manage-profile/security/api-tokens> |
| `CONTEXT7_API_KEY` | workflows that pass it through to the Context7 MCP | <https://context7.com/dashboard> |
| `SLACK_MCP_XOXB_TOKEN` | jira-ticket Slack summary | Slack app *Bot User OAuth Token* (`xoxb-…`) with `chat:write` |
| `DEV_PAT` *(optional)* | senior-dev / junior-dev when they need to push to a protected branch | Fine-grained PAT, `Contents: read/write` + `Pull requests: read/write`. Falls back to `GITHUB_TOKEN` if unset |

### Variables

| Name | Required? | Purpose |
|---|---|---|
| `JIRA_SERVER` | yes | e.g. `https://yourworkspace.atlassian.net` |
| `JIRA_LOGIN` | yes | Atlassian account email |
| `JIRA_PROJECT_KEY` | yes | Project the agents groom / route on |
| `JIRA_BOARD_ID` | optional | Defaults to `0` |
| `SLACK_OBSERVABILITY_CHANNEL_ID` | only if you want jira-ticket Slack summaries | Channel ID (not name) — `C0123456789` |
| `AGENT_APP_BOT_LOGIN` | yes (if running pr-review on App-authored PRs) | The App's bot login, e.g. `narcie-dev[bot]`. Wired into `pr-review.yml`'s `allowed_bots` so `claude-code-action` doesn't reject senior/junior-dev PRs as bot-initiated. |

### Things to review per repo

Every workflow under `.github/workflows/` was written for *this* repo.
After bootstrapping, scan the new repo's copy for:

- **Cron times** in `jira-ticket.yml` (currently `17 7 * * *` UTC).
- **Triggers** (`pull_request` types, `pull_request_review` types) in
  `pr-review.yml` and `senior-dev-resume.yml` — adjust if the project's
  branching model differs.
- **`max_turns` / `timeout-minutes`** on dev-agent workflows — defaults
  bias toward small tickets.

---

## Jira → GitHub automation (Dev Ready trigger)

The orchestrator only runs when Jira tells it a ticket is ready. Wire
this **once per Jira project** (the rule lives in Jira automation, not
in code).

### 1. Create a fine-grained GitHub PAT

In *github.com → Settings → Developer settings → Personal access tokens →
Fine-grained tokens*:

- **Repository access:** only the target repo.
- **Permissions:**
  - `Contents: Read`
  - `Actions: Read and write`

Copy the token — you'll paste it into Jira next.

### 2. Store the PAT as a Jira automation secret

In Jira: *Project settings → Automation → … → Manage secrets*.
Add a secret, e.g. `GITHUB_DISPATCH_PAT`, paste the token, save.
Jira automation rules can reference it as `{{secrets.GITHUB_DISPATCH_PAT}}`.

### 3. Add the automation rule

*Project settings → Automation → Create rule*:

- **Trigger:** *Issue transitioned* → To status: **Dev Ready**.
- **(Optional) Conditions:** issue type is *Story* / *Sub-task*; project
  is the right one; story points field is set (the orchestrator fails
  loudly on unpointed tickets, so you can pre-filter here).
- **Action:** *Send web request*.

  | Field | Value |
  |---|---|
  | URL | `https://api.github.com/repos/<owner>/<repo>/dispatches` |
  | Method | `POST` |
  | Headers | `Authorization: Bearer {{secrets.GITHUB_DISPATCH_PAT}}` <br> `Accept: application/vnd.github+json` <br> `Content-Type: application/json` |
  | Body type | Custom data |
  | Body | `{"event_type":"jira-dev-ready","client_payload":{"ticket_key":"{{issue.key}}"}}` |

  Tick *Wait for response* if you want failures to surface in the rule's
  audit log.

Save and enable the rule.

### 4. Verify

Move a pointed ticket to **Dev Ready**. Within ~30 seconds:

- *Jira → Project settings → Automation → Audit log* shows the rule
  firing with HTTP 204 (the GitHub dispatches endpoint returns 204 on
  success, no body).
- *GitHub → Actions → Orchestrator* shows a new run with
  `repository_dispatch` as the trigger.
- The orchestrator either dispatches `junior-dev.yml` / `senior-dev.yml`
  by story points, or fails the run with a "no story points" error.

### 5. Linking PRs back to tickets

Jira's **Smart Commits** auto-link if the Jira key (e.g. `KAN-42`)
appears in:

- Commit messages
- Branch names
- PR titles or descriptions

The dev agents already prefix branches and PR titles with the ticket
key, so links appear under *Development* on the ticket once the GitHub
↔ Jira app is connected (*Apps → GitHub for Jira* on the Atlassian
side, one-time per workspace).

---

## Adding a new agent

1. Drop the prompt at `agents/<name>/prompt.md`.
2. Wire a workflow at `.github/workflows/<name>.yml` that feeds the
   prompt to `anthropics/claude-code-action@v1` (or `claude -p` for
   implementers).
3. Make sure the secrets/vars it references are listed above; add any
   new ones to this README.

<!-- log-commit verification -->

<!-- pr-review test marker: v2 prompt -->
