---
allowed-tools: Bash(git checkout --branch:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*), Bash(gh pr create:*), Bash(git pull:*)
description: Ship changes by committing, pushing, and creating a PR to main
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## Your task

Ship the current changes to a pull request:

1. If on main branch, create a new feature branch
2. If there are uncommitted changes, create a commit with a conventional commit message following the format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks
   - Include a clear, concise description
   - Add Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
3. Push the branch to origin (with `-u` flag if first push)
4. Create a pull request to main using `gh pr create` with:
   - A clear, descriptive title
   - A concise body that summarizes all changes/features added using markdown formatting
   - Include test plan or notes if relevant

You have the capability to call multiple tools in a single response. You MUST do all of the above in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
