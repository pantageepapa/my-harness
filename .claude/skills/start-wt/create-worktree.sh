#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:?Usage: create-worktree.sh <branch-name>}"
REPO_PATH="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
PROJECT_NAME="$(basename "$REPO_PATH")"
WORKTREE_PARENT="$(dirname "$REPO_PATH")/${PROJECT_NAME}-worktrees"
WORKTREE_PATH="${WORKTREE_PARENT}/${BRANCH//\//-}"

# Progress to /dev/tty — stdout reserved for Claude
log() { echo "$*" > /dev/tty 2>/dev/null || true; }

log "Creating worktree (branch: $BRANCH)..."

mkdir -p "$WORKTREE_PARENT"
git worktree add -b "$BRANCH" "$WORKTREE_PATH" >/dev/null 2>&1

# Symlink shared config dirs — edits stay in sync across worktrees.
# Use `ln -sn` and skip if the target already exists, so that if $d is
# already a symlink to a directory we don't follow it and write the new
# link *inside* the real target (that's how a self-referential
# `.claude/.claude` symlink got committed in PR #43).
log "  Symlinking config dirs..."
for d in .claude .cursor .instrumental .agent_os; do
  if [ -d "${REPO_PATH}/$d" ] && [ ! -e "${WORKTREE_PATH}/$d" ] && [ ! -L "${WORKTREE_PATH}/$d" ]; then
    ln -sn "${REPO_PATH}/$d" "${WORKTREE_PATH}/$d"
    log "    linked $d"
  fi
done

# Copy env files — these often need per-worktree tweaks
log "  Copying env files..."
for f in .env .env.local; do
  if [ -f "${REPO_PATH}/$f" ]; then
    cp "${REPO_PATH}/$f" "${WORKTREE_PATH}/$f"
    log "    copied $f"
  fi
done

# Copy gitignored Jira config — tracked .jira files arrive via git checkout,
# but config.yml (and its backup) are per-clone and need to travel.
for f in .jira/config.yml .jira/config.yml.bkp; do
  if [ -f "${REPO_PATH}/$f" ]; then
    mkdir -p "${WORKTREE_PATH}/$(dirname "$f")"
    cp "${REPO_PATH}/$f" "${WORKTREE_PATH}/$f"
    log "    copied $f"
  fi
done

log "Worktree ready."

# The only thing on stdout — Claude parses this
echo "WORKTREE_PATH=$WORKTREE_PATH"
