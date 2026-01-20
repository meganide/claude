---
name: implement
description: Execute tasks from a feature spec one at a time, updating living documentation as you go. Use after /interview to implement the planned feature.
---

# Implement - Task Execution

This skill executes tasks from a feature specification, one task at a time, while maintaining living documentation.

## Overview

Use `/implement <path/to/tasks.md>` after running `/interview` to:
1. Work through tasks one at a time
2. Update progress in tasks.md (check boxes)
3. Update specs if implementation deviates from the plan
4. Keep documentation as the source of truth

**Usage:**
```
/implement specs/my-feature/tasks.md          # Interactive mode
/implement specs/my-feature/tasks.md --all    # Autonomous mode (all tasks)
```

**Modes:**
- Default - Interactive: asks after each task
- `--all` - Autonomous: completes all remaining tasks without stopping
- For fully automated execution without human in the loop, run `ralph -f <feature-name> [-n <iterations>]` instead (default: 30 iterations)

## Instructions

### Step 1: Read the Tasks File

The user provides the path to the tasks file as an argument:
```
/implement specs/my-feature/tasks.md
```

1. Read the provided tasks file
2. If you need additional context for a task, look in the same folder for:
   - `spec.md` - the PRD (what and why)
   - `plan.md` - the technical implementation (how)
3. Only read spec.md/plan.md when needed - the task should contain enough context for most cases

**Important:** All three files (`spec.md`, `plan.md`, `tasks.md`) are **living documents** and the **source of truth**. Update them as you implement to reflect the actual state of the feature.

### Step 2: Identify Next Task

Read `tasks.md` and find the first unchecked task (`- [ ]`).

If all tasks are complete, inform the user and ask if there's anything else to do.

### Step 3: Execute ONE Task

**Important: Only work on ONE task at a time.**

For the current task:

1. **Read the context** - Understand what's needed from the task description
2. **Reference the specs** - Check spec.md and plan.md for additional context if needed
3. **Implement** - Write the code AND write tests for the functionality
4. **Run linting** - Run the lint command from plan.md (e.g., `npm run lint`). Fix any issues.
5. **Verify success criteria** - Run the verification command specified in the task (e.g., run tests). The task is NOT complete until success criteria pass.
6. **Update tasks.md** - Only check off the task after linting passes AND verification passes

**Do NOT mark a task complete if:**
- Linting fails
- Tests are failing
- The verification command shows errors
- Success criteria are not met

If verification or linting fails, fix the issue and verify again before marking complete.

### Step 4: Update Documentation

After completing the task:

#### Always do:
- Check off the task: change `- [ ]` to `- [x]`

#### Only if you deviated from the original plan:
- Add a note under the task explaining what you did differently and why
- Update `plan.md` with the actual approach taken
- Update `spec.md` if requirements changed
- Add to "Implementation Notes" section if it's a significant learning

**Don't update docs if you followed the plan as written.**

**Example deviation note:**
```markdown
## Implementation Notes

### Task 3: API endpoint
Changed from REST to GraphQL because [reason]. Updated plan.md accordingly.
```

### Step 5: Confirm and Continue

After completing a task:

1. Briefly summarize what was done
2. Show the updated task status (e.g., "3/7 tasks complete")
3. Provide a concise "How to test" - tell the user how they can manually verify it works (e.g., "Run `npm start` and visit /login to see the new form" or "Call `curl localhost:3000/api/users` to test the endpoint")

**If interactive mode (default):**
Use `AskUserQuestion` tool with:
- Question: "Continue to the next task?"
- Header: "Next"
- Options:
  - Label: "Yes" / Description: "Continue to the next task"
  - Label: "No" / Description: "Stop here, I'll continue later"

**If autonomous mode (`--all`):**
- Briefly report progress
- Immediately continue to the next task
- Only stop if blocked or all tasks complete

### Living Documentation Rules

**The specs folder is the source of truth.** Only update them when you deviate from the original plan.

1. **tasks.md** - Always check boxes as you complete tasks.
   - Only add a note under a task if you did something differently than planned.
2. **plan.md** - Only update if technical approach changed:
   - User requests a different approach
   - You discover a better solution during implementation
   - Original approach doesn't work as expected
3. **spec.md** - Only update if requirements changed:
   - User changes their mind about a feature
   - Scope changes (features added/removed)

**Key principle:** If you followed the plan, just check off the task. If you deviated, update the docs so they reflect reality.

### Task Execution Principles

1. **Self-contained** - Each task should be completable independently
2. **Non-colliding** - Tasks shouldn't conflict with each other
3. **Testable in isolation** - Each task can be verified without completing other tasks
4. **Verify before checking** - Run the verification command and confirm success criteria pass before marking complete
5. **Atomic commits** - Consider committing after each task (if appropriate)

### Handling Issues

**If a task is blocked:**
- Don't check it off
- Add a note explaining the blocker
- Ask user how to proceed

**If a task needs to change:**
- Discuss with user
- Update the task description in tasks.md
- Update related specs if needed

**If you discover new tasks:**
- Add them to tasks.md (unchecked)
- Place them in logical order
- Note why they were added

### Example Session

```
User: /implement specs/user-auth/tasks.md

Agent: [Reads specs/user-auth/tasks.md]
Agent: "Found 5 tasks. Starting with Task 1: Set up auth middleware."
Agent: [Implements the task + writes tests]
Agent: [Runs npm run lint - passes]
Agent: [Runs verification: npm test -- auth.test.ts - passes]
Agent: "Linting and tests pass. Marking Task 1 complete."
Agent: [Updates tasks.md - checks off Task 1]
Agent: "Completed Task 1. (1/5)
        How to test: Run `npm start`, then `curl -H 'Authorization: Bearer <token>' localhost:3000/api/protected` - should return 200."
Agent: [Uses AskUserQuestion: "Continue to the next task?" Yes/No]

User: [Selects "Yes"]

Agent: [Implements Task 2]
Agent: [Needs more context, reads plan.md from same folder]
Agent: [Runs verification - tests fail]
Agent: "Tests failing. Fixing issue..."
Agent: [Fixes the issue]
Agent: [Runs verification again - tests pass]
Agent: "Note: Changed JWT library from plan due to security advisory. Updated plan.md."
Agent: [Updates tasks.md and plan.md]
Agent: "Completed Task 2. (2/5)"
Agent: [Uses AskUserQuestion: "Continue to the next task?" Yes/No]

... continues until all tasks done ...

Agent: "All tasks complete! Feature implementation finished."
```

## Command Variations

- `/implement path/to/tasks.md` - Interactive mode (asks after each task)
- `/implement path/to/tasks.md --all` - Autonomous mode (completes all tasks)
- `ralph -f <feature-name> [-n <iterations>]` - Fully automated (no human in the loop, default: 30 iterations)

Examples:
```
/implement specs/user-auth/tasks.md
/implement specs/shopping-cart/tasks.md --all
ralph -f shopping-cart
ralph -f user-auth -n 15
```

### Interactive Mode (default)
After each task, use `AskUserQuestion` tool:
- Question: "Continue to the next task?"
- Options: "Yes" or "No"

### Autonomous Mode (`--all`)
- Continue through all tasks without asking
- Still update documentation after each task
- Still report progress (briefly) after each task
- Stop if a task fails or is blocked
- At the end, summarize all completed tasks

## Important Notes

- ONE task at a time - no skipping ahead
- Always update documentation as you go
- Specs are living documents - keep them accurate
- If unsure about something, ask the user
- Commit after tasks when appropriate (respect user's git preferences)
