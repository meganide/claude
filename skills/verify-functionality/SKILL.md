---
name: verify-functionality
description: Checks all changes in the current branch and writes a step-by-step manual verification guide with expected outcomes.
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(git show:*), Read, Glob, Grep, Write, AskUserQuestion
---

# Verify Functionality - Manual Testing Guide Generator

This skill analyzes all changes in the current branch compared to main and generates a step-by-step manual verification checklist, saved as `verification.md` in the corresponding spec folder.

## Context

- Current branch: !`git branch --show-current`
- Main branch comparison base: !`git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "main"`
- Files changed: !`git diff --name-only $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "main")..HEAD 2>/dev/null || git diff --name-only main`
- Commit summary: !`git log --oneline $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "main")..HEAD 2>/dev/null || git log --oneline main..HEAD`
- Available spec folders: !`ls -d specs/*/ 2>/dev/null | sed 's|specs/||g' | sed 's|/||g' || echo "No spec folders found"`

## Instructions

### Step 0: Determine the Target Spec Folder

Before generating the verification guide, determine which spec folder to save it to:

1. **Check for existing spec folders** using `ls specs/` or similar
2. **Infer from context**:
   - If the branch name matches a spec folder (e.g., branch `feature/user-auth` and folder `specs/user-auth/`), use that
   - If commit messages or changed files clearly relate to a single spec, use that
   - If recent conversation context mentions a specific feature, use that
3. **If unclear, ask the user** using `AskUserQuestion`:
   - List the available spec folders as options
   - Include an "Other" option for custom path

Example:
```
AskUserQuestion:
  question: "Which spec folder should I save the verification guide to?"
  header: "Spec folder"
  options:
    - label: "user-auth"
      description: "specs/user-auth/"
    - label: "shopping-cart"
      description: "specs/shopping-cart/"
    - label: "Create new folder"
      description: "I'll create a new spec folder"
```

### Step 1: Gather All Changes

1. Get the diff between current branch and main:
   ```bash
   git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD
   ```

2. Get the list of commits with their messages:
   ```bash
   git log --oneline --no-merges $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)..HEAD
   ```

3. For each changed file, understand what was modified by reading the relevant portions

### Step 2: Analyze the Changes

For each change, identify:
- **What feature/fix was implemented**: Understand the purpose from commit messages and code
- **User-facing behavior**: What can the user see or interact with?
- **Entry points**: How does the user trigger this functionality?
- **Edge cases**: What boundary conditions exist?
- **Dependencies**: Does this require any setup or prerequisites?

### Step 3: Generate the Verification Guide

Create a markdown document with the following structure (note: ALL items use checkboxes):

```markdown
# Manual Verification Guide

**Branch**: [branch name]
**Date**: [current date]
**Changes Summary**: [brief 1-2 sentence summary]

---

## Prerequisites

- [ ] [Any required setup, environment variables, dependencies, etc.]
- [ ] [Any test data or accounts needed]

---

## Verification Steps

### Feature/Change 1: [Name]

**What changed**: [Brief description of the change]

**Steps to verify**:
- [ ] [Specific action the user should take]
- [ ] [Next action]
- [ ] [Continue...]

**Expected outcome**:
- [ ] [What the user should see/experience]
- [ ] [Any specific values, messages, or behaviors to look for]

**Edge cases to test**:
- [ ] [Edge case 1 and what to expect]
- [ ] [Edge case 2 and what to expect]

---

### Feature/Change 2: [Name]
[Repeat the format above with checkboxes]

---

## Regression Checks

- [ ] [Any existing functionality that might be affected - describe how to verify it still works]

---

## Notes

- [Any additional context, known limitations, or things to watch out for]
```

### Step 4: Save the Verification Guide

**Save the verification guide to `specs/<feature-name>/verification.md`** using the Write tool.

Example:
```
Write:
  file_path: "specs/user-auth/verification.md"
  content: [the generated verification guide]
```

After saving, inform the user:
- Where the file was saved
- How to use it (check off items as they verify)

### Step 5: Output Guidelines

When writing the verification guide:

1. **Use checkboxes everywhere**: Every actionable item should be a checkbox (`- [ ]`) so users can track progress

2. **Be specific**: Don't say "test the login" - say "Enter email 'test@example.com' and password 'test123', then click the Login button"

3. **Include exact expected results**: Don't say "it should work" - say "A green success toast should appear with message 'Logged in successfully' and you should be redirected to /dashboard"

4. **Consider the user's perspective**: Write steps as if the user has never seen the code

5. **Group related changes**: If multiple commits relate to one feature, combine them into one verification section

6. **Prioritize user-facing changes**: Start with the most impactful/visible changes

7. **Include negative tests**: If relevant, include steps to verify error handling (e.g., "Enter an invalid email and verify the error message appears")

8. **Note any test data needed**: If verification requires specific data, mention how to set it up

### Important Notes

- **Always save to a spec folder**: The verification guide must be saved as `specs/<feature-name>/verification.md`
- **Ask if unclear**: If you cannot determine which spec folder to use from context, use AskUserQuestion to ask the user
- Focus on manual verification that complements automated tests
- If changes are purely internal/refactoring with no user-facing impact, note that automated tests should cover it and list what tests to run
- If changes require specific environment setup (API keys, databases, etc.), clearly document it in Prerequisites
- For UI changes, mention specific UI elements, their locations, and expected visual states
