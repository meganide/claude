---
name: hubspot-backlogged
description: Check status of HubSpot tickets in Backlogged and Waiting on Release stages of the Support Pipeline. Determines if fixes have been merged or released and generates a summary report with recommended actions. Can check all tickets or a single ticket by ID.
---

# HubSpot Backlog Status Checker (Orchestrator)

Automated workflow to check the status of fixes for HubSpot support tickets in the **Support Pipeline**. Uses parallel sub-agents for efficient triage of multiple tickets.

---

## Usage

```
/hubspot-backlogged                    # Check ALL tickets in both stages
/hubspot-backlogged <ticket_id>        # Check a SINGLE ticket by HubSpot ID
/hubspot-backlogged backlogged         # Check only Backlogged stage
/hubspot-backlogged release            # Check only Waiting on Release stage
```

**Examples:**
```
/hubspot-backlogged                    # All tickets in both stages
/hubspot-backlogged 12345678           # Single ticket by ID
/hubspot-backlogged HS-12345678        # Single ticket (HS- prefix is stripped)
/hubspot-backlogged backlogged         # Only Backlogged stage tickets
/hubspot-backlogged release            # Only Waiting on Release stage tickets
```

---

## Architecture

This skill uses a **parallel orchestration pattern** with shared HTML file:

1. **Phase 1: Fetch Ticket IDs** - Get ticket IDs from HubSpot (lightweight query)
2. **Phase 2: Setup** - Pull latest code, create results folder, create initial HTML playground
3. **Phase 3: Parallel Triage** - Spawn background sub-agents for each ticket ID (each adds their ticket to the shared HTML)
4. **Phase 4: Wait for Completion** - Wait for all sub-agents to finish
5. **Phase 5: Open Report** - Open the completed playground in Chrome

---

## Orchestrator Workflow

### Step 1: Parse Arguments

Determine the mode based on argument:
- **Ticket ID** (number or `HS-<id>`): Single Ticket Mode
- **`backlogged`**: Backlogged Only Mode
- **`release`**: Waiting on Release Only Mode
- **No argument**: All Tickets Mode

### Step 2: Fetch Ticket IDs from HubSpot

**First, get user details to find the portal ID:**
```
hubspot-get-user-details
```

**Then fetch ticket IDs based on mode (minimal properties for ID retrieval):**

**Single Ticket Mode:**
- Pass the ticket ID directly to the sub-agent (skip search)

**All Tickets / Filtered Mode:**
```yaml
# Fetch Backlogged ticket IDs
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline
          operator: EQ
          value: "0"
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: "160253050"
  limit: 100

# Fetch Waiting on Release ticket IDs
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline
          operator: EQ
          value: "0"
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: "66012185"
  limit: 100
```

**Note:** Only ticket IDs are needed here. Each sub-agent will fetch full ticket details.

### Step 3: Pull Latest Code & Create Initial Playground

Before spawning sub-agents:

1. **Pull all repos:**
```bash
~/projects/pull-all.sh
```

2. **Create a timestamped results folder:**
```bash
RESULTS_FOLDER=~/projects/backlog-reports/run-$(date +%Y%m%d-%H%M%S)
mkdir -p $RESULTS_FOLDER
```

3. **Create the initial HTML playground file:**

Read the playground template from:
```
~/.claude/skills/hubspot-backlogged/templates/playground-template.html
```

Copy it to the results folder:
```bash
cp ~/.claude/skills/hubspot-backlogged/templates/playground-template.html $RESULTS_FOLDER/backlog-status-report.html
```

The HTML file path is: `$RESULTS_FOLDER/backlog-status-report.html`

Save these values - you'll pass them to all sub-agents:
- `resultsFolder`: The results folder path
- `playgroundPath`: The HTML file path
- `expectedTicketCount`: Total number of tickets to triage

### Step 4: Spawn Parallel Sub-Agents in Background

**CRITICAL: Use Task tool to spawn sub-agents in PARALLEL in the BACKGROUND.**

For each ticket, spawn a Task tool with:
- `subagent_type`: "general-purpose"
- `description`: "Triage ticket HS-<id>"
- `run_in_background`: true
- `prompt`: Include the ticket ID, playground path, and triage instructions

**Read the sub-agent instructions first:**
```
Read file: ~/.claude/skills/hubspot-backlogged/agents/ticket-triager.md
```

**Spawn pattern (all in one message for parallel background execution):**

```
For a batch of 5 tickets, send ONE message with 5 Task tool calls:

Task 1:
  subagent_type: general-purpose
  description: Triage ticket HS-12345
  run_in_background: true
  prompt: |
    <ticket-triager-instructions from agents/ticket-triager.md>

    ## Ticket to Triage
    ticketId: 12345
    hubspotPortalId: <portal-id-from-user-details>
    playgroundPath: <HTML file path from Step 3>

Task 2:
  subagent_type: general-purpose
  description: Triage ticket HS-12346
  run_in_background: true
  prompt: |
    <same instructions>

    ## Ticket to Triage
    ticketId: 12346
    hubspotPortalId: <portal-id>
    playgroundPath: <HTML file path>

(etc. for all tickets)
```

**Note:** Each sub-agent fetches ticket data and adds their ticket to the shared HTML playground file.

**Important:**
- All Task tool calls MUST be in a single message for parallel execution
- Use `run_in_background: true` for all sub-agents
- Each sub-agent adds their ticket to the HTML file's data section
- Each Task tool call returns a `task_id` - save these for Step 5

### Step 5: Wait for All Agents to Complete

**CRITICAL: Wait for ALL sub-agents to finish before opening the playground.**

Use `TaskOutput` to wait for each agent:

```
For each task_id from Step 4:

TaskOutput:
  task_id: <task_id>
  block: true
  timeout: 300000  # 5 minutes per agent
```

You can call multiple `TaskOutput` calls in parallel (one message with all calls).

Each agent will confirm when it has added its ticket to the HTML file.

### Step 6: Save results.json

After all agents complete, extract the ticket data from the HTML and save as JSON for programmatic access.

1. **Read the completed HTML file**
2. **Extract the ticketData array** from the JavaScript section
3. **Create results.json** in the same folder with this structure:

```json
{
  "generatedAt": "<ISO timestamp>",
  "reportPath": "<path to HTML file>",
  "summary": {
    "total": <N>,
    "readyToClose": <N>,
    "waitingOnRelease": <N>,
    "stillBacklogged": <N>
  },
  "tickets": [
    // All ticket objects from ticketData
  ]
}
```

Save to: `<resultsFolder>/results.json`

### Step 7: Open in Chrome

Once results.json is saved:

```bash
open -a "Google Chrome" <playgroundPath>
```

Inform the user:
- Report is ready
- Path to the HTML file: `<playgroundPath>`
- Path to JSON data: `<resultsFolder>/results.json`
- Timestamp of report generation
- Summary counts (Ready to Close, Waiting on Release, Still Backlogged)

---

## HubSpot Configuration

### Pipeline & Stage IDs

| Entity | ID |
|--------|-----|
| **Support Pipeline** | `0` |
| **Backlogged Stage** | `160253050` |
| **Waiting on Release Stage** | `66012185` |

### Custom Fields

| Field | Purpose |
|-------|---------|
| **platform** | "Portal" or "OSS" - determines which path to follow |
| **product** | Routes to relevant package folder(s) |
| **Linear Ticket Link** | URL to the associated Linear issue |

---

## Key Dates to Include

The sub-agents will extract and return these dates with links:

| Date Type | Where to Find | Link To |
|-----------|---------------|---------|
| CHANGELOG date | Git history of CHANGELOG.md | GitHub CHANGELOG file |
| npm publish date | npmjs.com package page | npm package page |
| PR merge date | GitHub PR | GitHub PR page |
| Renovate PR merge date | backstage-portal PRs | GitHub Renovate PR |
| Deployment date | portal-ops revisions | N/A (CLI only) |
| Linear close date | Linear issue | Linear issue page |

---

## Safety

This skill is **READ-ONLY**:
- Does not modify codebase files
- Does not update HubSpot tickets
- Does not create, update, or close Linear issues
- Does not push changes to git

The only files written are:
- The HTML playground report (updated by each ticket-triager)
- The results.json file (created by the orchestrator at the end)

All recommendations are for **human review and action**.

---

## Quick Reference

| Task | Command |
|------|---------|
| Pull latest code | `~/projects/pull-all.sh` |
| Check plugin CHANGELOG | `cat ~/projects/backstage-plugins/plugins/<folder>/CHANGELOG.md` |
| List pending changesets | `ls ~/projects/backstage-plugins/.changeset/*.md` |
| Find related PRs | `cd ~/projects/backstage-plugins && gh pr list --state all --search "<query>"` |
| Portal: Find instance | `portal-ops lookup <company-name>` |
| Portal: Check deployment | `portal-ops cloudrun revisions -i <instance>` |

---

## Sub-Agent Files

| Agent | Path | Purpose |
|-------|------|---------|
| Ticket Triager | `~/.claude/skills/hubspot-backlogged/agents/ticket-triager.md` | Analyzes one ticket, adds it to shared HTML playground |

## Template Files

| Template | Path | Purpose |
|----------|------|---------|
| Playground Template | `~/.claude/skills/hubspot-backlogged/templates/playground-template.html` | Initial HTML structure that agents populate |
