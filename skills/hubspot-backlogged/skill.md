---
name: hubspot-backlogged
description: Check status of HubSpot tickets in Backlogged and Waiting on Release stages of the Support Pipeline. Determines if fixes have been merged or released and generates a summary report with recommended actions. Can check all tickets or a single ticket by ID.
---

# HubSpot Backlog Status Checker

Automated workflow to check the status of fixes for HubSpot support tickets in the **Support Pipeline** - specifically the "Backlogged" and "Waiting on Release" stages. Generates a summary report for human review.

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

**Arguments:**
| Argument | Description |
|----------|-------------|
| (none) | Check all tickets in Backlogged + Waiting on Release stages |
| `<ticket_id>` | Check a single ticket by its HubSpot ID |
| `backlogged` | Check only tickets in Backlogged stage |
| `release` | Check only tickets in Waiting on Release stage |

---

## Overview

Support engineers have tickets in the HubSpot **Support Pipeline** with two key stages:
- **Backlogged**: Ticket created, waiting for a fix (PR to be merged)
- **Waiting on Release**: Fix merged, waiting for deployment/publication

This skill automates the tedious manual process of checking each ticket to determine:
1. Has the fix been released/deployed?
2. What action should be taken on the ticket?

**Single ticket mode**: When a ticket ID is provided, only that ticket is checked (useful for quick status checks on specific tickets).

**Pipeline**: Support Pipeline (HubSpot ticket pipeline for support issues)

---

## Supported Platforms

### Backstage OSS (Priority)
- Repo: `~/projects/backstage-plugins` (maps to `spotify.ghe.com/backstage-external/backstage-plugins`)
- Fixes published to npm as `@spotify/backstage-plugin-*`
- Once published, customers need to update their dependencies

### Portal (Future Enhancement)
- More complex paths with multiple deployment stages
- Requires checking Renovate PRs and deployment-tracker
- Currently provides basic status but full automation is in progress

---

## HubSpot Custom Fields

These fields are found under "Adopter Context" on tickets:

| Field | Purpose |
|-------|---------|
| **platform** | "Portal" or "OSS" - determines which path to follow |
| **product** | Routes to relevant package folder(s) in backstage-plugins |
| **Linear Ticket Link** | URL to the associated Linear issue (e.g., `https://linear.app/spotify/issue/TOA-283/...`) |

### Product to Package Mapping

| HubSpot Product | Package Folders to Check |
|-----------------|-------------------------|
| Insights | `insights-backend`, `insights-common`, `insights-react`, `insights` |
| RBAC | `rbac-backend`, `rbac-common`, `rbac-node`, `rbac`, `permission-backend-module-rbac` |
| Soundcheck | `soundcheck-backend`, `soundcheck-backend-module-*`, `soundcheck-client`, `soundcheck-common`, `soundcheck-node`, `soundcheck` |
| Search | `search-backend-module-skill-exchange` |
| Skill Exchange | `skill-exchange-backend`, `skill-exchange-backend-module-*`, `skill-exchange-common`, `skill-exchange-node`, `skill-exchange` |
| Pulse | `pulse-backend`, `pulse-common`, `pulse` |
| Catalog | `core-common`, `core-node`, `core` |
| Other/Unknown | Search all relevant folders based on conversation context |

---

## Workflow

### Step 1: Fetch Tickets from HubSpot

**Parse the argument to determine mode:**
- If argument is a number (or starts with `HS-`): Single Ticket Mode
- If argument is `backlogged`: Backlogged Only Mode
- If argument is `release`: Waiting on Release Only Mode
- If no argument: All Tickets Mode

---

**Mode A: Single Ticket (when ticket ID is provided)**

If a ticket ID is provided (e.g., `/hubspot-backlogged 12345678`), fetch only that ticket:

```
# Get single ticket by ID
hubspot-batch-read-objects:
  objectType: tickets
  inputs:
    - id: <ticket_id>
  properties:
    - subject
    - content
    - hs_pipeline_stage
    - platform
    - product
```

Skip to Step 2 with just this one ticket.

---

**Mode B: Backlogged Only (argument = "backlogged")**

Fetch only tickets in Backlogged stage of the Support Pipeline:

```
# Search for tickets in Backlogged stage only (Support Pipeline)
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: <backlogged_stage_id>
```

---

**Mode C: Waiting on Release Only (argument = "release")**

Fetch only tickets in Waiting on Release stage of the Support Pipeline:

```
# Search for tickets in Waiting on Release stage only (Support Pipeline)
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: <waiting_on_release_stage_id>
```

---

**Mode D: All Tickets (no argument)**

Use HubSpot MCP to get all tickets in both stages of the Support Pipeline:

```
# Search for tickets in Backlogged stage (Support Pipeline)
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: <backlogged_stage_id>

# Search for tickets in Waiting on Release stage (Support Pipeline)
hubspot-search-objects:
  objectType: tickets
  filterGroups:
    - filters:
        - propertyName: hs_pipeline_stage
          operator: EQ
          value: <waiting_on_release_stage_id>
```

**First time setup**: You may need to identify the Support Pipeline stage IDs:
```
# List ticket properties to find pipeline stages
hubspot-list-properties:
  objectType: tickets
```

### Step 2: For Each Ticket, Get Context

For each ticket, gather:

1. **Ticket details** (subject, description, custom fields)
2. **Conversation history** (for understanding the bug/fix)
3. **Platform field** (Portal or OSS)
4. **Product field** (which plugin area)
5. **Linear Ticket Link** (URL to associated Linear issue)

```
# Get ticket with all properties
hubspot-batch-read-objects:
  objectType: tickets
  inputs:
    - id: <ticket_id>
  properties:
    - subject
    - content
    - hs_pipeline_stage
    - platform
    - product
    - linear_ticket_link   # The Linear issue URL
```

### Step 2.5: Check Linear Issue Status (Early Exit Check)

**If the ticket has a Linear Ticket Link**, check the Linear issue status FIRST before checking code.

#### Parse the Linear Issue ID

Extract the issue ID from the URL. The ID comes after `/issue/`:

```
URL: https://linear.app/spotify/issue/TOA-283/soundcheck-pagerduty-integration
Issue ID: TOA-283
```

#### Check Linear Issue Status

```bash
# View the Linear issue
linear issue view TOA-283

# Or get JSON for programmatic parsing
linear issue view TOA-283 -j
```

#### Early Exit Logic

Based on the Linear issue status, determine if further checking is needed:

| Linear Status | Action | Continue Checking? |
|---------------|--------|-------------------|
| **Backlog** | Fix not started | NO - Stay "Backlogged" |
| **Todo** | Fix not started | NO - Stay "Backlogged" |
| **In Progress** | Fix being worked on | NO - Stay "Backlogged" |
| **In Review** | PR under review | NO - Stay "Backlogged" |
| **Blocked** | Fix is blocked | NO - Stay "Backlogged", note blocker |
| **Done / Closed** | PR merged or fix completed | YES - Continue to check release status |
| **Canceled** | Issue was canceled | NO - Investigate why |

**Key insight**: "Closed" in Linear means the fix PR has been merged, but it may not be released yet. Continue checking CHANGELOG, npm, and deployment status.

#### Example Flow

```
1. Get HubSpot ticket HS-12345
2. Extract Linear Ticket Link: https://linear.app/spotify/issue/TOA-283/...
3. Parse issue ID: TOA-283
4. Run: linear issue view TOA-283
5. Check status:
   - If "In Progress" → STOP, report "Fix in progress"
   - If "Closed" → CONTINUE to Step 3 (check if released)
```

---

### Step 3: Check Fix Status (OSS Path)

**Before checking any code, pull latest:**
```bash
~/projects/pull-all.sh
```

#### 3a. Check CHANGELOG.md

For each relevant package folder based on the product field:

```bash
# Navigate to backstage-plugins
cd ~/projects/backstage-plugins

# Read the CHANGELOG for the relevant plugin
cat plugins/<package-folder>/CHANGELOG.md
```

**Analyze the CHANGELOG:**
- Does it mention a fix for this issue?
- What version contains the fix?
- When was it released?

If fix is found in CHANGELOG:
- **Recommendation**: Move to "Confirm Resolution"
- **Action**: Notify customer that version X.Y.Z contains the fix

#### 3b. Check Pending Changesets

If fix is NOT in CHANGELOG, check if it's pending release:

```bash
# Check pending changesets
cd ~/projects/backstage-plugins
ls .changeset/*.md

# Read changesets to find relevant fixes
cat .changeset/*.md | grep -i "<keywords from ticket>"
```

Or use GitHub to search:

```bash
cd ~/projects/backstage-plugins
gh pr list --state open --search "changeset" --limit 20
```

If fix is found in pending changesets:
- **Recommendation**: Stay in "Waiting on Release"
- **Action**: Fix will be in next release

If fix is NOT found anywhere:
- **Recommendation**: Stay in "Backlogged"
- **Action**: Fix is not ready yet

### Step 4: Check Fix Status (Portal Path)

For Portal customers, the path is more complex because fixes must flow through multiple stages before reaching the customer's instance.

#### 4a. Identify the Customer Instance

First, find the customer's Portal instance from the ticket:

```bash
# Get associated company from HubSpot ticket, then look up instance
portal-ops lookup <company-name>
```

If multiple instances exist (prod, staging, dev), focus on the **production instance** unless the ticket specifies otherwise.

#### 4b. Check backstage-plugins CHANGELOG (same as OSS)

Find the fix and note the package version (e.g., `@spotify/backstage-plugin-soundcheck@0.21.1`).

#### 4c. Check if Renovate PR Updated backstage-portal

After a plugin is published to npm, a Renovate PR should update backstage-portal:

```bash
cd ~/projects/backstage-portal
# Search for Renovate PRs containing the package
gh pr list --state all --search "head:renovate-app/ @spotify/backstage-plugin-<name>"

# Or search for the specific version
gh pr list --state all --search "@spotify/backstage-plugin-<name>@<version>"
```

Check if the PR:
- **Exists and is merged**: Fix is in backstage-portal, proceed to deployment check
- **Exists but open**: Fix is pending Renovate merge
- **Does not exist**: Fix hasn't been picked up by Renovate yet

#### 4d. Check if Fix is Deployed to Customer Instance

This is the critical step - verify the fix reached the customer's actual instance:

```bash
# Get the current deployed revision and when it was deployed
portal-ops cloudrun revisions -i <instance>

# Get the instance details including package versions
portal-ops get <instance>
```

**To verify the fix is deployed:**

1. **Check the deployment date**: If the Renovate PR was merged AFTER the last deployment, the fix is NOT deployed yet.

2. **Check package versions** (if available): Some instances expose their package versions. Compare against the fix version.

3. **Check Cloud Run revision history**:
   ```bash
   portal-ops cloudrun revisions -i <instance>
   ```
   Look at when the latest revision was deployed vs when the Renovate PR was merged.

#### Portal Status Determination

| CHANGELOG | Renovate PR | Deployed to Instance | Status |
|-----------|-------------|---------------------|--------|
| Fix found | Merged | Yes (revision after merge) | **Confirm Resolution** |
| Fix found | Merged | No (revision before merge) | **Waiting on Deployment** |
| Fix found | Open/Pending | - | **Waiting on Renovate** |
| Fix found | Not created | - | **Waiting on Renovate PR** |
| Not found | - | - | **Backlogged** (fix not ready) |

#### Portal-Only Products (Special Cases)

Some products live directly in `backstage-portal`, not `backstage-plugins`:
- **AiKA**: Check `~/projects/backstage-portal` directly
- **Confidence**: Check `~/projects/backstage-portal/plugins/`

For these, skip the Renovate step and check deployment directly after finding the fix in the portal repo.

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| **Linear: View issue status** | `linear issue view <issue-id>` |
| **Linear: View as JSON** | `linear issue view <issue-id> -j` |
| **Linear: Open in browser** | `linear issue view <issue-id> -w` |
| Pull latest code | `~/projects/pull-all.sh` |
| Check plugin CHANGELOG | `cat ~/projects/backstage-plugins/plugins/<folder>/CHANGELOG.md` |
| List pending changesets | `ls ~/projects/backstage-plugins/.changeset/*.md` |
| Search changesets | `grep -r "<keyword>" ~/projects/backstage-plugins/.changeset/` |
| Find related PRs | `cd ~/projects/backstage-plugins && gh pr list --state all --search "<query>"` |
| **Portal: Find customer instance** | `portal-ops lookup <company-name>` |
| **Portal: Get instance details** | `portal-ops get <instance>` |
| **Portal: Check Renovate PRs** | `cd ~/projects/backstage-portal && gh pr list --state all --search "renovate @spotify/backstage-plugin-<name>"` |
| **Portal: Check deployment revisions** | `portal-ops cloudrun revisions -i <instance>` |
| Check npm version | WebFetch `https://www.npmjs.com/package/@spotify/backstage-plugin-<name>` |

---

## Output Format

Generate a summary report in this format:

```
================================================================================
TICKET STATUS REPORT - Generated <timestamp>
================================================================================

SUMMARY
-------
Total Tickets Checked: <N>
- Ready to Close: <N>
- Waiting on Release: <N>
- Still Backlogged: <N>

================================================================================

TICKET: HS-<id> - "<subject>"
--------------------------------------------------------------------------------
Customer: <company>
Platform: <Portal/OSS>
Product: <product>
Instance: <instance-name> (Portal only)
Current Status: <Backlogged/Waiting on Release>

LINEAR ISSUE: <issue-id> (e.g., TOA-283)
  Status: <Backlog/Todo/In Progress/In Review/Blocked/Done/Canceled>
  Link: <linear-url>
  Early Exit: <YES - fix not ready / NO - continue checking>

FIX STATUS: (only if Linear status = Done/Closed)
  CHANGELOG: <package>@<version> - RELEASED / NOT FOUND
  Changeset: PENDING / NOT FOUND
  npm: @spotify/<package>@<version> - PUBLISHED <date> / NOT PUBLISHED
  Renovate PR: MERGED <date> / OPEN / NOT FOUND (Portal only)
  Deployed to Instance: YES (revision <X> on <date>) / NO (latest: revision <X> on <date>) / N/A (OSS)

RECOMMENDATION: <action>
  - Move to: <new status>
  - Action: <what to do>
  - Message to customer: <draft message>

Links:
  - HubSpot: <url>
  - npm: <url>
  - PR: <url>

================================================================================
... repeat for each ticket ...
================================================================================
```

---

## Recommendations Logic

### Linear Status (Early Exit)

| Linear Status | Recommendation | Continue Checking? |
|---------------|----------------|-------------------|
| Backlog / Todo | Stay "Backlogged" - fix not started | NO |
| In Progress | Stay "Backlogged" - fix being developed | NO |
| In Review | Stay "Backlogged" - PR under review | NO |
| Blocked | Stay "Backlogged" - note blocker reason | NO |
| Done / Closed | Check release status | YES |
| Canceled | Investigate why canceled | NO |
| No Linear link | Proceed with manual checks | YES |

### Release Status (when Linear = Closed)

| Scenario | Recommendation |
|----------|----------------|
| OSS: Fix in CHANGELOG, published to npm | Move to "Confirm Resolution" - notify customer to upgrade |
| OSS: Fix in changeset, not released | Stay "Waiting on Release" - will be in next release |
| OSS: No fix found | Stay "Backlogged" - fix not ready |
| Portal: Fix deployed to customer | Move to "Confirm Resolution" - verify with customer |
| Portal: Fix published, not deployed | Stay "Waiting on Release" - pending deployment |
| Portal: Fix in changeset | Stay "Waiting on Release" - pending publish + deploy |
| Portal: No fix found | Stay "Backlogged" - fix not ready |

---

## Instructions

When running the backlog status check:

1. **Parse the argument** to determine mode:
   - Ticket ID (number or `HS-<id>`): Fetch only that single ticket
   - `backlogged`: Fetch only tickets in Backlogged stage
   - `release`: Fetch only tickets in Waiting on Release stage
   - No argument: Fetch all tickets in both stages
2. **Fetch tickets** from HubSpot Support Pipeline (include `linear_ticket_link` field)
3. **For each ticket**:
   a. **Check Linear status FIRST** (if Linear Ticket Link exists):
      - Parse issue ID from URL (e.g., `TOA-283` from `https://linear.app/spotify/issue/TOA-283/...`)
      - Run `linear issue view <issue-id>`
      - If status is Backlog/Todo/In Progress/In Review/Blocked → STOP, report status
      - If status is Done/Closed → CONTINUE to code checks
   b. **Pull latest code**: `~/projects/pull-all.sh`
   c. Get the platform and product fields
   d. Check CHANGELOG in relevant package folders
   e. Check pending changesets if not in CHANGELOG
   f. For Portal: also check Renovate PRs and deployment status
4. **Generate the summary report** with recommendations
5. **Create a visual summary playground** (REQUIRED - see below)
6. **Open the playground in Chrome**: `open -a "Google Chrome" <file-path>`

### Finding Support Pipeline Stage IDs

If you don't know the stage IDs for the Support Pipeline stages ("Backlogged" and "Waiting on Release"):

```
# Get the pipeline stages for tickets
hubspot-get-property:
  objectType: tickets
  propertyName: hs_pipeline_stage
```

Or search by stage name within the Support Pipeline:
```
hubspot-search-objects:
  objectType: tickets
  query: "Backlogged"
  limit: 10
```

**Note**: The Support Pipeline is the HubSpot pipeline used for support tickets. Stage IDs are specific to this pipeline.

---

## Example Run

```
> /hubspot-backlogged

Fetching tickets from Support Pipeline...
Found 12 tickets in Backlogged stage
Found 5 tickets in Waiting on Release stage

Pulling latest code...
Running ~/projects/pull-all.sh

Checking ticket 1 of 17: HS-12345 "Soundcheck widget crashes on Safari"
- Platform: OSS
- Product: Soundcheck
- Checking plugins/soundcheck/CHANGELOG.md...
- Found fix in v0.21.1: "Fixed Safari rendering issue"
- Checking npm... @spotify/backstage-plugin-soundcheck@0.21.1 published 2026-01-25
- RECOMMENDATION: Move to "Confirm Resolution"

Checking ticket 2 of 17: HS-12346 "RBAC policy not syncing"
- Platform: Portal
- Product: RBAC
- Checking plugins/rbac-backend/CHANGELOG.md...
- Found fix in v0.8.5
- Checking Renovate PRs... PR #4567 merged 2026-01-26
- Checking deployment... Deployed to cohort 1, pending cohort 2
- RECOMMENDATION: Stay "Waiting on Release" - partial deployment

...

================================================================================
REPORT COMPLETE
================================================================================
```

---

## Edge Cases

### Multiple Products
If a ticket spans multiple products, check all relevant package folders.

### Unknown Product
If product field is empty or "Other", analyze the conversation to identify affected components.

### No Linear Ticket
Some tickets may not have associated Linear tickets. Check based on conversation context alone.

### Portal-Only Products
Some products (like AiKA) live directly in backstage-portal, not backstage-plugins. Check the appropriate repo.

### Very Old Tickets
For old tickets, the fix may have been released long ago. Check if customer has been notified.

---

## Final Step: Visual Summary Playground (REQUIRED)

**ALWAYS create a visual summary playground after completing the status check.** This is mandatory, not optional.

**Save all playground HTML files to:** `~/projects/backlog-reports/`

**Filename format:** `backlog-status-<date>.html` or `ticket-<id>-status-<date>.html` for single tickets

Example: `backlog-status-2026-02-02.html` or `ticket-12345678-status-2026-02-02.html`

**After saving, open the file in Chrome:**
```bash
open -a "Google Chrome" ~/projects/backlog-reports/<filename>.html
```

### What to Include in the Playground

The playground should visualize the status report with:

1. **Summary Dashboard**
   - Total tickets checked
   - Breakdown by recommendation (Ready to Close, Waiting, Backlogged)
   - Color-coded status indicators

2. **Ticket Cards**
   - Each ticket as an expandable card
   - Status timeline showing fix progression
   - Recommendation with reasoning
   - Links to HubSpot, npm, PRs

3. **Interactive Features**
   - Filter by status/recommendation
   - Search by ticket ID or keywords
   - Collapsible details for each ticket
   - Copy buttons for customer messages

4. **Visual Elements**
   - Progress bars for fix status
   - Color coding (green=ready, yellow=waiting, red=backlogged)
   - Timeline showing fix → release → deployment progression
   - Clear action items

### Playground Template

When creating the playground, include:

```
Create a visual status report dashboard for HubSpot backlog tickets.

## Report Details
- Date: <timestamp>
- Mode: <All Tickets / Single Ticket>
- Total Checked: <N>

## Tickets
<for each ticket>
- ID: <ticket_id>
- Subject: <subject>
- Customer: <company>
- Platform: <Portal/OSS>
- Product: <product>
- Current Status: <status>
- Fix Status: <changelog/changeset/npm/deployment findings>
- Recommendation: <action>
- Customer Message: <draft message>
</for each ticket>

Create an interactive HTML page with:
1. Summary cards with counts and percentages
2. Filterable/searchable ticket list
3. Expandable ticket details
4. Color-coded status indicators
5. Timeline visualization for fix progression
6. Copy-to-clipboard for customer messages
7. Links to HubSpot, npm, GitHub
8. Professional, clean design
```

---

## Safety

This skill is **READ-ONLY**. It does not:
- Modify any files
- Update HubSpot tickets automatically
- Push any changes
- Make any destructive operations

All recommendations are for **human review and action**.

---

**REMINDER: No backlog status check is complete without creating the visual summary playground and opening it in Chrome. Always do both.**
