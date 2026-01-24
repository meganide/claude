---
name: merge
description: Fetch latest from origin main and merge with the current branch. Handles conflicts interactively by presenting changes and recommendations.
allowed-tools: Bash(git fetch:*), Bash(git merge:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git checkout:*), Bash(git add:*), Bash(git branch:*)
---

# Merge - Sync with Origin Main

This skill fetches the latest changes from origin main and merges them into your current branch.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits on current branch: !`git log --oneline -5`

## Instructions

### Step 1: Fetch Latest from Origin

```bash
git fetch origin main
```

### Step 2: Attempt Merge

Run the merge command:

```bash
git merge origin/main
```

### Step 3: Handle Result

**If merge succeeds without conflicts:**
- Report success with a summary of what was merged
- Show any new commits that were brought in: `git log --oneline HEAD@{1}..HEAD`

**If merge has conflicts:**

1. Get the list of conflicted files:
   ```bash
   git status --porcelain | grep "^UU\|^AA\|^DD\|^AU\|^UA\|^DU\|^UD"
   ```

2. For EACH conflicted file, analyze the conflict:
   - Read the file to see the conflict markers
   - Use `git diff --base <file>` to see what changed
   - Use `git log --oneline -3 origin/main -- <file>` to understand incoming changes
   - Use `git log --oneline -3 HEAD -- <file>` to understand local changes

3. Present each conflict to the user using `AskUserQuestion` with:
   - **Question**: Clear description of the conflict in this file
   - **Header**: The filename (shortened if needed)
   - **Options** (provide 2-4 relevant options based on the conflict):
     - **Keep ours**: Description of what "our" version contains
     - **Keep theirs**: Description of what "their" (origin/main) version contains
     - **Keep both**: Combine both changes (only if this makes sense for the conflict)

   Include your recommendation by putting "(Recommended)" at the end of the option you think is best based on:
   - Which change is more complete
   - Which change is newer/more relevant
   - Whether one change encompasses the other

4. After user selects resolution for each file:
   - Apply the chosen resolution
   - Stage the resolved file: `git add <file>`

5. After ALL conflicts are resolved:
   - Complete the merge: `git commit --no-edit`
   - Report success

### Example Conflict Question

For a conflict in `src/utils/helpers.ts`:

```
Question: "Conflict in helpers.ts: Local branch adds a 'formatDate' function, while origin/main adds 'parseDate' function in the same location. Which version should we keep?"
Header: "helpers.ts"
Options:
- Label: "Keep ours (Recommended)"
  Description: "Keep local 'formatDate' function - appears to be new feature work"
- Label: "Keep theirs"
  Description: "Keep origin/main 'parseDate' function"
- Label: "Keep both"
  Description: "Include both functions - they don't conflict logically"
```

### Handling Specific Conflict Types

**For code conflicts:**
- Analyze what each side changed
- Recommend based on which change is more complete or logical

**For package.json/lock file conflicts:**
- Usually recommend keeping theirs and re-running install
- Mention if local has dependencies that need to be re-added

**For configuration files:**
- Carefully analyze what each change does
- Often recommend keeping both changes merged manually

**For deleted vs modified conflicts:**
- Check if the deletion was intentional
- Recommend based on whether the file should exist

### Important Notes

- NEVER force push or use destructive git commands
- NEVER skip conflict resolution
- Always explain what's happening at each step
- If something goes wrong, report the error and suggest how to recover
- If user wants to abort the merge, run `git merge --abort`
