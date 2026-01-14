---
allowed-tools: Bash(git worktree:*), Bash(git switch:*), Bash(git checkout:*)
argument-hint: <worktree-path>
description: Delete a git worktree after switching to main branch
model: claude-3-5-haiku-20241022
---

Delete the specified git worktree with the following requirements:

Worktree path: $1

Steps:
1. First, switch to the main branch (try 'main' first, then 'master' if main doesn't exist)
2. Remove the worktree at the specified path
3. If the worktree is locked or has uncommitted changes, force remove it with appropriate warnings
4. Confirm the worktree was removed successfully by listing all remaining worktrees
