#!/usr/bin/env bash
# Per-clone Jira CLI setup for this scaffold.
#
# Produces .jira/config.yml in the repo root, scoped to whichever Atlassian
# instance + project the user is configuring this clone against. The token
# itself is never written to disk — it stays in JIRA_API_TOKEN, the same way
# the jira CLI expects it.
#
# Run from anywhere: `bash scripts/jira-init.sh`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/.jira/config.yml"
ENV_FILE="$REPO_ROOT/.env"
LOCAL_JIRA="$REPO_ROOT/bin/jira"

err() { printf >&2 'error: %s\n' "$*"; }
note() { printf '%s\n' "$*"; }

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -x "$LOCAL_JIRA" ]]; then
  jira_bin="$LOCAL_JIRA"
elif command -v jira >/dev/null 2>&1; then
  jira_bin="$(command -v jira)"
else
  err "jira CLI not found."
  err "  install locally:  bash scripts/install-jira-cli.sh"
  err "  or system-wide:   brew install ankitpokhrel/jira-cli/jira-cli"
  exit 1
fi

if [[ -z "${JIRA_API_TOKEN:-}" ]]; then
  err "JIRA_API_TOKEN is not set."
  err "  create one: https://id.atlassian.com/manage-profile/security/api-tokens"
  err "  then add it to .env at the repo root:"
  err "    echo 'JIRA_API_TOKEN=...' >> $ENV_FILE"
  err "  (or export it in your shell)"
  exit 1
fi

mkdir -p "$REPO_ROOT/.jira"

if [[ -e "$CONFIG_PATH" ]]; then
  printf '%s already exists. Overwrite? [y/N] ' "$CONFIG_PATH"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) note "aborted; existing config kept."; exit 0 ;;
  esac
fi

note "Running '"$jira_bin" init' — answer the prompts for your Atlassian instance."
note "  installation type: Cloud"
note "  server URL:        e.g. https://yourworkspace.atlassian.net"
note "  login:             your Atlassian account email"
note "  default project:   the project key the agent will operate on"
note ""

"$jira_bin" init -c "$CONFIG_PATH"

note ""
note "Smoke test: 'jira me' against the new config..."
JIRA_CONFIG_FILE="$CONFIG_PATH" "$jira_bin" me

note ""
note "Done. To use the local CLI in this repo:"
note "  export JIRA_CONFIG_FILE=\"$CONFIG_PATH\""
note "or pass -c .jira/config.yml on every invocation."
