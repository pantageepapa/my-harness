---
name: start-wt
description: Start a new feature using a git worktree. Takes a plain-language description of what you plan to build, proposes a branch name for your approval, creates the worktree as a sibling to the project root (same pattern as the wt() shell function), symlinks tool configs (.claude, .cursor, etc.) and copies .env, then offers to clear context for a fresh start in the new worktree.
---

You are setting up a new feature branch using a git worktree. The user has described what they want to build in `$ARGUMENTS`.

## Step 1 — Parse the feature description

Read `$ARGUMENTS`. If empty or vague, ask "What are you planning to build?" before proceeding.

## Step 2 — Propose a branch name

From the description, generate **one branch name**:
- Format: `kebab-case`, 2–4 words
- Prefer type prefixes when obvious: `feat/`, `fix/`, `chore/`
- Good: `feat/user-auth`, `fix/invoice-pdf`
- Avoid: generic words (`new-stuff`, `wip`), dates, underscores

Show the candidate via `AskUserQuestion`. **Do not proceed until confirmed.**

## Step 3 — Pre-flight checks

```bash
git rev-parse --show-toplevel    # capture as $REPO_PATH
git worktree list                 # check if target path already exists
git status                        # warn (don't block) on uncommitted changes
```

Target path: `$(dirname $REPO_PATH)/$(basename $REPO_PATH)-worktrees/$BRANCH`. If it already appears in `git worktree list`, stop and tell the user to `git worktree remove <path>` first.

## Step 4 — Create the worktree

```bash
"${CLAUDE_PROJECT_DIR}/.claude/skills/start-wt/create-worktree.sh" "$BRANCH"
```

The script handles worktree creation, symlinks config dirs (`.claude`, `.cursor`, `.instrumental`, `.agent_os`), and copies env files. It outputs `WORKTREE_PATH=...` on stdout.

If it fails, show the error and stop.

## Step 5 — Enter the worktree

Use the `EnterWorktree` tool with `path: "$WORKTREE_PATH"` (from script output). The rest of the conversation operates inside the worktree.

If `EnterWorktree` fails, fall back to printing `cd "$WORKTREE_PATH" && claude` and stop.

## Step 6 — Summary + clear

Print:

```
✅  Worktree ready and entered

   Branch : <branch>
   Path   : <worktree-path>

   Run /clear next so we start the feature with a fresh context.
```

End your turn — only the user can `/clear`.
