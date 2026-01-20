# First-time setup: Run this command ONCE to authenticate with the volume mount:
#   docker sandbox run --volume ~/.claude:/home/agent/.claude claude
# This creates a sandbox with your settings/skills. Subsequent runs reuse it.

# Graceful shutdown on Ctrl+C - stops container but allows current file writes to finish
trap 'echo ""; echo "Stopping sandbox..."; docker ps --filter "name=sandbox" -q | xargs -r docker stop; exit' INT TERM

# Default values
ITERATIONS=30
FEATURE=""

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--iterations)
      ITERATIONS="$2"
      shift 2
      ;;
    -f|--feature)
      FEATURE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 -f <feature-name> [-n <iterations>]"
      echo ""
      echo "Options:"
      echo "  -f, --feature     Feature name (required) - folder inside specs/"
      echo "  -n, --iterations  Number of iterations (default: 30)"
      echo ""
      echo "Example: $0 -f user-auth -n 5"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage"
      exit 1
      ;;
  esac
done

if [ -z "$FEATURE" ]; then
  echo "Error: Feature name is required"
  echo "Usage: $0 -f <feature-name> [-n <iterations>]"
  exit 1
fi

# For each iteration, run Claude Code with the following prompt.
for ((i=1; i<=$ITERATIONS; i++)); do
  result=$(docker sandbox run --volume ~/.claude:/home/agent/.claude claude -p "Complete exactly ONE task from the feature's tasks file, then stop.

**Feature:** $FEATURE
**File locations:**
- Tasks: specs/$FEATURE/tasks.json
- Spec: specs/$FEATURE/spec.md
- Plan: specs/$FEATURE/plan.md

Follow these steps:

### Step 1: Read context
- Read specs/$FEATURE/tasks.json
- Review completed tasks (passes: true) and read their learnings arrays for context from previous work
- If specs/$FEATURE/spec.md or specs/$FEATURE/plan.md exist, reference them for additional context

### Step 2: Find the next task
- Find the first task where \"passes\": false
- Tasks are ordered by id - pick the lowest id that hasn't passed

### Step 3: Implement the task
- Write the code
- Write tests for the functionality

### Step 4: Check feedback loops
Run type checks and tests to verify your work:
- Run the project's type check command (e.g., npm run typecheck, tsc --noEmit)
- Run the project's test command (e.g., npm test, pytest)
- Run the project's lint command (e.g., npm run lint)
- Fix any issues before proceeding

### Step 5: Update tasks.json
Only after all checks pass, update the task in tasks.json:
- Set \"passes\": true
- Add learnings to the \"learnings\" array (useful discoveries about the codebase for subsequent tasks)

### Step 6: Commit the work
git add -A && git commit -s -m '<task title>: <brief description>'

### Step 7: Check for completion
If ALL tasks now have \"passes\": true:
1. Run /ship to commit, push, and create a PR
2. Output exactly: <promise>COMPLETE</promise>

This signals to the automation script that no more work remains.

### Step 8: Stop
Do not continue to the next task. Exit immediately.

## Important
- Only complete ONE task per invocation
- Do not mark a task as passes: true if tests are failing
- If checks fail, fix and retry before marking complete
- Output <promise>COMPLETE</promise> when all tasks are done" | tee /dev/tty)

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    exit 0
  fi
done