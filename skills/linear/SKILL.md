---
name: linear
description: Linear CLI reference for managing issues, projects, initiatives, teams, documents, and milestones. Use when needing to interact with Linear from the command line.
---

# Linear CLI Reference

Command-line interface for managing Linear issues, projects, initiatives, teams, and more.

---

## DESTRUCTIVE ACTIONS DENIED

**The following commands are NOT allowed and must NEVER be executed:**

- `linear issue delete` - Delete an issue
- `linear team delete` - Delete a team
- `linear label delete` - Delete a label
- `linear document delete` - Delete a document
- `linear initiative delete` - Delete an initiative
- `linear milestone delete` - Delete a milestone

**If the user asks to delete something, refuse and suggest archiving instead (where available).**

---

## Quick Reference

| Task | Command |
|------|---------|
| List my issues | `linear issue list` |
| View an issue | `linear issue view <issue-id>` |
| Create an issue | `linear issue create -t "Title" -d "Description"` |
| Start working on issue | `linear issue start <issue-id>` |
| Update an issue | `linear issue update <issue-id> --state "In Progress"` |
| List projects | `linear project list` |
| List teams | `linear team list` |
| List initiatives | `linear initiative list` |

---

## Issues

### List Issues

```bash
# List your issues (default: unstarted state)
linear issue list

# List all states
linear issue list --all-states

# Filter by state
linear issue list -s started
linear issue list -s backlog
linear issue list -s completed

# Filter by assignee
linear issue list --assignee <username>
linear issue list -A  # All assignees
linear issue list -U  # Unassigned only

# Filter by project
linear issue list --project "Project Name"

# Filter by team
linear issue list --team "Team Name"

# Limit results
linear issue list --limit 100

# Sort by priority
linear issue list --sort priority

# Open in browser
linear issue list -w
```

**State values:** `triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled`

### View Issue

```bash
# View issue details
linear issue view <issue-id>

# View as JSON
linear issue view <issue-id> -j

# Open in browser
linear issue view <issue-id> -w

# Open in Linear app
linear issue view <issue-id> -a

# Without comments
linear issue view <issue-id> --no-comments
```

### Create Issue

```bash
# Basic creation
linear issue create -t "Issue title"

# With description
linear issue create -t "Title" -d "Description here"

# With all options
linear issue create \
  -t "Issue title" \
  -d "Description" \
  -a self \                    # Assign to self
  --team "Team Name" \
  --project "Project Name" \
  --priority 2 \               # 1=Urgent, 2=High, 3=Medium, 4=Low
  --estimate 3 \               # Story points
  --due-date 2026-02-15 \
  -l "bug" \                   # Label (can repeat)
  -l "urgent" \
  -s "In Progress" \           # Initial state
  -p "TEAM-123"                # Parent issue

# Create and start immediately
linear issue create -t "Title" --start
```

### Update Issue

```bash
# Update state
linear issue update <issue-id> -s "In Progress"
linear issue update <issue-id> -s completed

# Update assignee
linear issue update <issue-id> -a self
linear issue update <issue-id> -a "username"

# Update priority
linear issue update <issue-id> --priority 1

# Update title/description
linear issue update <issue-id> -t "New title"
linear issue update <issue-id> -d "New description"

# Add labels
linear issue update <issue-id> -l "bug" -l "urgent"

# Set due date
linear issue update <issue-id> --due-date 2026-02-20

# Move to project
linear issue update <issue-id> --project "Project Name"
```

### Start Issue

Creates a git branch and assigns the issue to you.

```bash
# Start issue (creates branch)
linear issue start <issue-id>

# Start from specific ref
linear issue start <issue-id> -f main

# Custom branch name
linear issue start <issue-id> -b custom-branch-name

# Start unassigned issues
linear issue start -U
```

### Issue Comments

```bash
# List comments on an issue
linear issue comment list <issue-id>

# Add a comment
linear issue comment add <issue-id>

# Update a comment
linear issue comment update <comment-id>
```

### Other Issue Commands

```bash
# Get issue ID from current git branch
linear issue id

# Get issue title
linear issue title <issue-id>

# Get issue URL
linear issue url <issue-id>

# Get issue title with Linear trailer (for commits)
linear issue describe <issue-id>

# Create PR from issue
linear issue pr <issue-id>
```

---

## Projects

### List Projects

```bash
linear project list
```

### View Project

```bash
linear project view <project-id>
```

### Create Project

```bash
linear project create
```

---

## Project Updates

Status updates for projects.

```bash
# List status updates
linear project-update list <project-id>

# Create status update
linear project-update create <project-id>
```

---

## Milestones

```bash
# List milestones for a project
linear milestone list

# View milestone
linear milestone view <milestone-id>

# Create milestone
linear milestone create

# Update milestone
linear milestone update <milestone-id>
```

---

## Initiatives

```bash
# List initiatives
linear initiative list

# View initiative
linear initiative view <initiative-id>

# Create initiative
linear initiative create

# Update initiative
linear initiative update <initiative-id>

# Archive initiative (preferred over delete)
linear initiative archive <initiative-id>

# Unarchive initiative
linear initiative unarchive <initiative-id>

# Link project to initiative
linear initiative add-project <initiative-id> <project-id>

# Unlink project from initiative
linear initiative remove-project <initiative-id> <project-id>
```

---

## Initiative Updates

Timeline posts for initiatives.

```bash
linear initiative-update --help
```

---

## Teams

```bash
# List teams
linear team list

# Get configured team ID
linear team id

# List team members
linear team members <team-key>

# Create team
linear team create

# Configure GitHub autolinks
linear team autolinks
```

---

## Labels

```bash
# List labels
linear label list

# Create label
linear label create
```

---

## Documents

```bash
# List documents
linear document list

# View document
linear document view <document-id>

# Create document
linear document create

# Update document
linear document update <document-id>
```

---

## Common Workflows

### Start Working on an Issue

```bash
# 1. List your unstarted issues
linear issue list -s unstarted

# 2. Pick one and start it (creates branch, assigns to you)
linear issue start TEAM-123

# 3. Work on the code...

# 4. When done, update state
linear issue update TEAM-123 -s "In Review"
```

### Create Issue and Start Immediately

```bash
linear issue create -t "Fix bug in login" -d "Details..." --start
```

### View Issue from Current Branch

```bash
# Get issue ID from branch name
linear issue id

# View it
linear issue view
```

### Create PR from Issue

```bash
linear issue pr TEAM-123
```

### Quick Status Update

```bash
# Move issue to In Progress
linear issue update TEAM-123 -s "In Progress"

# Mark as completed
linear issue update TEAM-123 -s completed

# Mark as canceled
linear issue update TEAM-123 -s canceled
```

---

## Configuration

```bash
# Interactive configuration
linear config

# Generate shell completions
linear completions
```

---

## Tips

1. **Issue IDs**: Use the format `TEAM-123` (e.g., `POR-456`)

2. **States by type**: Use state types like `started`, `completed` or exact state names like `"In Progress"`

3. **Self assignment**: Use `-a self` to assign to yourself

4. **Labels**: Use `-l` multiple times for multiple labels: `-l bug -l urgent`

5. **JSON output**: Add `-j` or `--json` for machine-readable output

6. **Open in browser**: Add `-w` to open in browser instead of terminal output

7. **Open in app**: Add `-a` to open in Linear desktop app

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `LINEAR_API_KEY` | API key for authentication |
| `LINEAR_ISSUE_SORT` | Default sort order for issue list |

---

## Safety

This skill does NOT allow:
- Deleting issues, teams, labels, documents, initiatives, or milestones
- Any destructive operations

Use `archive` commands where available instead of delete.
