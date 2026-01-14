---
allowed-tools: Bash(git worktree:*), Bash(git branch:*)
argument-hint: <branch-name> [path]
description: Create a new git worktree for the specified branch
model: claude-3-5-haiku-20241022
---

Create a new git worktree with the following requirements:

Branch name: $1
Path: ${2:-$1}

Steps:
1. Check if the branch exists locally or remotely
2. Create the worktree at the specified path (or use branch name as path if not specified)
3. If the branch doesn't exist, create it from the current HEAD
4. Confirm the worktree was created successfully by listing all worktrees
