#!/usr/bin/env bash
# Copy this harness into another repo.
#
# Manifest comes from `git ls-files` so anything gitignored (.env,
# .jira/config.yml, bin/.jira-bin, tools/log-index.json,
# .claude/settings.local.json) is automatically skipped. A few tracked paths
# are also held back because they're per-clone or about the harness itself:
# agent-log history, this repo's README, and .gitignore (merged, not copied).
#
# Default is dry-run. Pass --apply to actually write.
#
# Usage:
#   bash scripts/bootstrap.sh <target-dir>            # dry-run
#   bash scripts/bootstrap.sh <target-dir> --apply    # do it

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

err() { printf >&2 'error: %s\n' "$*"; }
note() { printf '%s\n' "$*"; }

target=""
apply=0
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    -h|--help)
      sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*) err "unknown flag: $arg"; exit 1 ;;
    *)
      if [[ -n "$target" ]]; then
        err "multiple target dirs: $target, $arg"; exit 1
      fi
      target="$arg"
      ;;
  esac
done

if [[ -z "$target" ]]; then
  err "missing target dir. usage: bash scripts/bootstrap.sh <target-dir> [--apply]"
  exit 1
fi

if [[ ! -d "$target" ]]; then
  err "target is not a directory: $target"
  exit 1
fi

target="$(cd "$target" && pwd)"
if [[ "$target" == "$REPO_ROOT" ]]; then
  err "target is the harness itself; refusing"
  exit 1
fi

# Paths to skip on top of whatever git already ignores.
# - .github/agent-logs/**: per-clone run history
# - README.md: about this harness, would clobber the target's
# - .gitignore: merged in separately so we don't blow away target's rules
exclude_re='^(\.github/agent-logs/|README\.md$|\.gitignore$)'

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT

git -C "$REPO_ROOT" ls-files \
  | grep -Ev "$exclude_re" \
  > "$manifest"

count="$(wc -l < "$manifest" | tr -d ' ')"

note "harness:  $REPO_ROOT"
note "target:   $target"
note "files:    $count tracked files (excluding agent-logs, README, .gitignore)"
note ""

# .gitignore lines this harness needs in the target. Idempotent — we grep
# before appending so re-running doesn't duplicate entries.
gitignore_block=$(cat <<'EOF'

# --- my-harness ---
.env
.jira/config.yml
.jira/config.yml.bkp
bin/
tools/log-index.json
.claude/settings.local.json
.claude/.claude
# --- /my-harness ---
EOF
)

target_gitignore="$target/.gitignore"
gitignore_action="append harness block"
if [[ -f "$target_gitignore" ]] && grep -q '# --- my-harness ---' "$target_gitignore"; then
  gitignore_action="already present, skip"
elif [[ ! -f "$target_gitignore" ]]; then
  gitignore_action="create new"
fi

if [[ $apply -eq 0 ]]; then
  note "DRY RUN — pass --apply to actually copy."
  note ""
  note "would copy:"
  sed 's/^/  /' "$manifest"
  note ""
  note ".gitignore at $target_gitignore: $gitignore_action"
  note ""
  note "no changes made."
  exit 0
fi

if ! command -v rsync >/dev/null 2>&1; then
  err "rsync not found on PATH"
  exit 1
fi

note "copying $count files…"
rsync -a --files-from="$manifest" "$REPO_ROOT/" "$target/"

case "$gitignore_action" in
  "append harness block"|"create new")
    printf '%s\n' "$gitignore_block" >> "$target_gitignore"
    note "updated $target_gitignore ($gitignore_action)"
    ;;
  *)
    note "$target_gitignore already has harness block, leaving alone"
    ;;
esac

note ""
note "done. next steps in $target:"
note "  1. cp .env.example .env   # then fill in JIRA_API_TOKEN, CONTEXT7_API_KEY"
note "  2. bash scripts/install-jira-cli.sh"
note "  3. bash scripts/jira-init.sh"
note "  4. add GitHub repo secrets used by the workflows:"
note "       CLAUDE_CODE_OAUTH_TOKEN, CONTEXT7_API_KEY"
note "       (and any others the workflows under .github/workflows/ reference)"
note "  5. review .github/workflows/ — workflow names, triggers, and"
note "     branch refs may need adjusting for the new repo"
