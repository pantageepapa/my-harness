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

# Symlink shared config dirs — edits stay in sync across worktrees
log "  Symlinking config dirs..."
for d in .claude .cursor .instrumental .agent_os; do
  if [ -d "${REPO_PATH}/$d" ]; then
    ln -s "${REPO_PATH}/$d" "${WORKTREE_PATH}/$d"
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

log "Worktree ready."

# The only thing on stdout — Claude parses this
echo "WORKTREE_PATH=$WORKTREE_PATH"
