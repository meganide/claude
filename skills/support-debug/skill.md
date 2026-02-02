---
name: support-debug
description: Debug Backstage/Portal support issues using internal codebases, documentation, GitHub issues, changelogs, and Portal ops. Use when investigating customer issues, researching plugin bugs, or troubleshooting configurations.
---

# Support Debugger

Specialized debugging workflow for Backstage OSS and Spotify Portal support issues.

---

## ⛔ CRITICAL: READ-ONLY MODE

**This skill is strictly READ-ONLY. You must NEVER:**

- Edit, write, or modify any files
- Run destructive commands (delete, reset, force push, etc.)
- Make changes to customer configs
- Execute commands that modify state
- Create, update, or delete any resources

**You may ONLY:**

- Read files and code
- Search codebases (grep, glob)
- Fetch logs and configs (read-only)
- Search GitHub issues/PRs
- Fetch documentation
- Analyze and diagnose

**Your job is to investigate and document findings, NOT to fix anything.**

---

## Context

You support two product lines:
1. **Backstage OSS + Spotify for Backstage plugins** - Commercial plugins (support license)
2. **Portal** - Spotify's hosted Backstage SaaS

## Resources

### HubSpot MCP (Support Tickets)

Support tickets come through HubSpot. The **HubSpot MCP** is available for:
- Looking up tickets by ID
- Getting full conversation history for context
- Finding associated company/customer info
- Identifying which customer/company to look up Portal instances for

**When given a ticket ID**, use HubSpot MCP to:
1. Get the ticket details (subject, description, status)
2. Get the conversation thread for full context
3. Find the associated company to identify the customer
4. Use company name with `portal-ops lookup` to find Portal instance

### Local Codebases (~/projects/)

**⚠️ CRITICAL: Before reading or searching any code in `~/projects/`, ALWAYS run the pull script first:**

```bash
~/projects/pull-all.sh
```

This ensures you have the latest commits and data from all repositories. **Never skip this step.**

| Codebase | Purpose |
|----------|---------|
| `backstage-oss` | Backstage open source core |
| `backstage-portal` | Portal infrastructure and configs |
| `backstage-plugins` | Spotify's commercial plugins |
| `spotify-for-backstage-docs` | Plugin and Portal documentation |
| `portal-internal-plugins` | Internal debugging tools |

### Documentation URLs

- **Backstage OSS**: https://backstage.io/docs/overview/what-is-backstage
- **Spotify Plugins**: https://backstage.spotify.com/docs/plugins/
- **Portal**: https://backstage.spotify.com/docs/portal/

### External Resources

- **GitHub Issues/PRs (Public)**: https://github.com/backstage/backstage/
  - Check both open AND closed issues
  - Look at recent PRs for regressions
  - Search discussions for similar problems

- **NPM Changelogs**: For any `@spotify/backstage-plugin-*` package:
  1. Go to `https://www.npmjs.com/package/{package-name}?activeTab=code`
  2. Click on `CHANGELOG.md` in the file list

### Private GitHub Enterprise (spotify.ghe.com)

For Spotify internal repos, use the `/gh-cli` skill commands by navigating to the local codebase folder first.

**Important**: The `gh` CLI uses the repo context from the current directory. To search private repos:

```bash
# Navigate to the repo folder first
cd ~/projects/backstage-portal

# Then run gh commands (they will use spotify.ghe.com context)
gh pr list --state all --search "error message"
gh issue list --state all --search "bug description"
gh pr view <number>
```

**Which repo to check based on issue type:**

| Issue Type | Local Folder | What to Search |
|------------|--------------|----------------|
| Portal infrastructure | `~/projects/backstage-portal` | Deployment issues, Cloud Run, configs |
| Plugin bugs | `~/projects/backstage-plugins` | Plugin code, features, regressions |
| Internal tools | `~/projects/portal-internal-plugins` | Debugging tools, internal features |
| Documentation | `~/projects/spotify-for-backstage-docs` | Doc updates, examples |

**Common searches in private repos:**

```bash
# In backstage-portal - find deployment PRs
cd ~/projects/backstage-portal
gh pr list --state merged --search "deploy" --limit 20

# In backstage-plugins - find fix for an error
cd ~/projects/backstage-plugins
gh pr list --state all --search "<error-message>"
gh issue list --state all --search "<bug-description>"

# Find PR that introduced a change
gh pr list --search "<commit-sha>" --state all

# View recent merged PRs
gh pr list --state merged --limit 20 --json number,title,mergedAt
```

**Always check both public AND private repos** when investigating issues - the fix might be in either place.

See `/gh-cli` skill for full command reference.

### Portal Operations

Use `/portal-ops` skill to:
- Get customer configs: `portal-ops config get -i <instance>`
- View logs: `portal-ops logs view -i <instance>`
- Search configs: `portal-ops config search --key "..." --customer`

### GCP Backend Debugging

Use `/gcp-debug` skill for Portal customers to investigate backend/server issues:
- View Cloud Run service logs directly in GCP
- Check service status and configuration
- Review revision history and deployments
- Filter logs by severity, time, or error messages

To find the GCP project for a Portal customer:
```bash
portal-ops lookup <customer-name>  # Find instance name
portal-ops get <instance-name>      # Get GCP project ID
```

Then use `/gcp-debug` with the project ID for deeper log analysis.

## Debugging Workflow

### Step 0: Start from Ticket (if provided)

If given a **HubSpot ticket ID**, use the HubSpot MCP to:
1. Get the ticket details and conversation history
2. Find the associated company
3. Use company name with `portal-ops lookup` to find the Portal instance
4. Proceed with full context

### Step 1: Gather Information

Ask or determine:
- [ ] Product: Portal or Backstage OSS with plugins?
- [ ] Which plugin(s) involved?
- [ ] Error message or symptoms?
- [ ] When did it start? (upgrade? config change?)
- [ ] What versions are running?

### Step 2: Get Customer Config (Portal) - ALWAYS DO THIS FIRST

**For Portal customers, ALWAYS get their config first** - this is mandatory before any other investigation.

#### Finding the Instance Name

If given a company/customer name instead of an instance name, use lookup first:

```bash
portal-ops lookup <company-name>
```

**IMPORTANT: Multiple instances exist for most customers!**

Most customers have multiple instances (e.g., prod, staging, dev). If the lookup returns multiple instances:

1. **STOP and ask the user** which instance they want to investigate
2. Use the `AskUserQuestion` tool to clarify: "I found multiple instances for [customer]: [list]. Which one should I investigate?"
3. **Never assume** - always confirm before proceeding

Example lookup output:
```
spc-acme-prod      (production)
spc-acme-staging   (staging)
```

**Always ask**: "Which instance - prod or staging?"

#### Get the Config

Once you have the correct instance name:

```bash
portal-ops config get -i <instance>       # Full config (YAML format)
```

**Why config first?** The majority of Portal issues are caused by misconfigurations. Getting the config immediately:
- Reveals obvious issues (typos, wrong structure, missing fields)
- Provides context for understanding logs and errors
- Often identifies the root cause without further investigation

**After getting the config, review it for:**
- [ ] Correct YAML syntax (indentation, colons, quotes)
- [ ] Required fields present for enabled plugins
- [ ] Valid values (URLs, tokens, enum values)
- [ ] No deprecated or renamed config keys
- [ ] Integrations configured correctly (GitHub, auth providers, etc.)

**Then get additional context:**
```bash
portal-ops logs view -i <instance>         # Recent logs
portal-ops cloudrun errors -i <instance>   # Cloud Run errors
```

**Config validation is critical** - Always:
1. Get the customer's current config FIRST
2. Find the correct config format from docs or working examples in codebases
3. Compare against expected structure to identify misconfigurations
4. Look for common mistakes: wrong indentation, missing required fields, invalid values

### Step 3: Search for Known Issues

Search GitHub for similar problems:
```bash
# Use gh CLI or web search
gh search issues "error message" --repo backstage/backstage
gh search prs "fix for feature" --repo backstage/backstage --state all
```

Check both:
- Open issues (ongoing problems)
- Closed issues (solved problems - solution may apply)
- Recent PRs (may have introduced regressions)

### Step 4: Check Changelogs

For version-related issues, check NPM changelogs:
- `@spotify/backstage-plugin-soundcheck`
- `@spotify/backstage-plugin-soundcheck-backend`
- `@spotify/backstage-plugin-soundcheck-common`
- `@spotify/backstage-plugin-rbac`
- `@backstage/core-plugin-api`
- etc.

Look for:
- Breaking changes between versions
- Migration guides
- Deprecated features

### Step 5: Understand the Implementation

Don't just search - **read and understand the code** to determine:
- Is this an actual bug in the codebase?
- Is this intended behavior that the customer misunderstands?
- Why is it occurring? (understand the code flow)
- What's the expected vs actual behavior?

**First, pull latest changes:**
```bash
~/projects/pull-all.sh
```

Then search and dive deep into relevant codebases:

```bash
# Search in backstage-plugins for plugin code
grep -r "error message" ~/projects/backstage-plugins/

# Search in portal code for infrastructure issues
grep -r "config key" ~/projects/backstage-portal/

# Check internal plugins for debugging tools
ls ~/projects/portal-internal-plugins/
```

**After finding relevant code:**
1. Read the implementation thoroughly
2. Trace the code path that leads to the error
3. Check if there are tests that document expected behavior
4. Look at config validation logic to understand required formats
5. Determine if it's a bug, misconfiguration, or intended limitation

### Step 6: Cross-Reference Documentation

Verify customer setup matches documented requirements:
- Correct config structure
- Required fields present
- Known limitations documented

## Common Plugin Packages

| Plugin | Packages |
|--------|----------|
| Soundcheck | `@spotify/backstage-plugin-soundcheck`, `@spotify/backstage-plugin-soundcheck-backend`, `@spotify/backstage-plugin-soundcheck-common` |
| RBAC | `@spotify/backstage-plugin-rbac`, `@spotify/backstage-plugin-rbac-backend` |
| Insights | `@spotify/backstage-plugin-insights`, `@spotify/backstage-plugin-insights-backend` |

## Output Format

Structure findings as:

```markdown
## Issue Summary
Brief description of the problem

## Product/Plugin
- Product: Portal / Backstage OSS
- Plugin: <plugin name>
- Version: <version if known>

## Root Cause
What's causing the issue (if identified)

## Classification
- [ ] Bug in codebase
- [ ] Customer misconfiguration
- [ ] Intended behavior / limitation
- [ ] Needs more investigation

## Evidence
- Relevant logs, configs, or code snippets
- Links to related GitHub issues/PRs
- Changelog entries if version-related

## Resolution
Step-by-step fix or workaround

## Prevention
How to avoid this in the future (if applicable)

## Customer Response
Draft message to send to the customer:
- Clear explanation of the issue
- Step-by-step resolution instructions
- Links to relevant documentation
- Professional and helpful tone
```

## Quick Actions

| Task | Command/Action |
|------|----------------|
| Get ticket details | HubSpot MCP - get ticket by ID |
| Get ticket conversation | HubSpot MCP - get conversation history |
| Find customer company | HubSpot MCP - get associated company |
| Get Portal config | `/portal-ops` then `config get -i <instance>` |
| Search GitHub | `gh search issues "query" --repo backstage/backstage` |
| Check changelog | WebFetch `npmjs.com/package/@spotify/...?activeTab=code` |
| Search plugin code | Grep in `~/projects/backstage-plugins/` |
| Check docs | WebFetch Backstage/Portal documentation |

## Instructions

When investigating an issue:

1. **Start from ticket (if provided)** - Use HubSpot MCP to get ticket details, conversation, and associated company
2. **Understand the problem** - Get all relevant details first
3. **Get customer config (Portal)** - ALWAYS get config first with `portal-ops config get -i <instance>` - most issues are misconfigurations
4. **Check if known** - Search GitHub, changelogs, and docs
5. **Use GCP debugging** - For backend issues, use `/gcp-debug` to analyze server logs
6. **Dive into code** - Search codebases for relevant implementation
7. **Document findings** - Use the output format above
8. **Propose solution** - Clear steps the customer can follow
9. **Draft customer response** - Always include a ready-to-send message
10. **Create visual summary (REQUIRED)** - ALWAYS create a playground with an interactive debug summary. This is mandatory for every investigation.

Always:
- **Run `~/projects/pull-all.sh` before reading any code in ~/projects/** - ensures latest commits
- **NEVER modify files, run destructive commands, or make any changes - READ ONLY**
- Check both open AND closed GitHub issues
- Check BOTH public (github.com) AND private (spotify.ghe.com) repos - navigate to local folders and use `gh` commands
- Look at changelogs for breaking changes
- Compare customer config against working examples in docs/tests
- Consider if the issue is version-specific

## CRITICAL: Ground All Findings in Evidence

**NEVER make assumptions or speculate.** Every claim must be backed by concrete evidence.

### Required Evidence Types

For every finding, provide at least one of:
- **File reference**: `path/to/file.ts:123` with the exact line number
- **GitHub link**: Issue URL, PR URL, or commit SHA
- **Documentation link**: URL to official docs
- **Log excerpt**: Actual log output with timestamps
- **Config snippet**: Exact config from customer or codebase
- **Changelog entry**: Version and exact changelog text

### CRITICAL: Make All References Actionable

**Every reference MUST include a direct link or exact instructions to find it.**

❌ **BAD** - Vague reference:
> "The reasoning_effort error was fixed in commit 6c6d2eff4 and deployed to McLaren on Jan 28 (revision 00070)"

✅ **GOOD** - Actionable reference with links:
> "The reasoning_effort error was fixed in commit 6c6d2eff4:
> - **PR**: https://github.com/backstage/backstage-plugins/pull/1234
> - **Commit**: https://github.com/backstage/backstage-plugins/commit/6c6d2eff4
> - **Deployed**: Revision 00070 on Jan 28 - verify with `portal-ops cloudrun revisions -i mclaren`"

### How to Find and Link References

| Reference Type | How to Find | Link Format |
|----------------|-------------|-------------|
| **Commit** | `git log --oneline` or GitHub search | `https://github.com/<org>/<repo>/commit/<sha>` |
| **PR** | `gh pr list --search "<query>"` or commit message | `https://github.com/<org>/<repo>/pull/<number>` |
| **Issue** | `gh search issues "<query>"` | `https://github.com/<org>/<repo>/issues/<number>` |
| **Deployment** | `portal-ops cloudrun revisions -i <instance>` | Include command to verify |
| **Config version** | `portal-ops config history -i <instance>` | Include version number and timestamp |
| **NPM package** | npmjs.com | `https://www.npmjs.com/package/<package>/v/<version>` |
| **Changelog** | NPM code tab | `https://www.npmjs.com/package/<package>?activeTab=code` → CHANGELOG.md |
| **Documentation** | Official docs sites | Direct URL to specific section |
| **Code file** | Local path or GitHub | `https://github.com/<org>/<repo>/blob/main/<path>#L<line>` |

### Reference Template

When citing a fix or change, always include:

```markdown
**[Brief description of what was fixed]**
- **Issue**: https://github.com/org/repo/issues/123 (if applicable)
- **PR**: https://github.com/org/repo/pull/456
- **Commit**: https://github.com/org/repo/commit/abc123
- **Released in**: v1.2.3 ([changelog](https://npmjs.com/package/@spotify/plugin?activeTab=code))
- **Deployed to customer**: [date] - verify with `portal-ops cloudrun revisions -i <instance>`
```

### Commands to Find References

```bash
# Find PR for a commit
gh pr list --search "<commit-sha>" --state all --repo <org>/<repo>

# Find commit by message
git log --all --oneline --grep="<search-term>"

# Find when a fix was deployed
portal-ops cloudrun revisions -i <instance>

# Find config change history
portal-ops config history -i <instance>

# Search GitHub for related issues
gh search issues "<error message>" --repo backstage/backstage
```

### Before Making Any Claim

Ask yourself:
1. "Where did I see this?" → Cite the source
2. "Can I prove this?" → If not, say "needs verification"
3. "Am I inferring or did I read it?" → Only state what you actually found

### Evidence Format

Always include references inline:

```markdown
## Root Cause
The error occurs because `validateConfig()` throws when `allowedKinds` is empty.
- **Source**: `backstage-plugins/plugins/soundcheck/src/config.ts:87`
- **Related issue**: https://github.com/backstage/backstage/issues/12345

## Resolution
Update config to include at least one kind (per docs requirement).
- **Documentation**: https://backstage.spotify.com/docs/plugins/soundcheck/configuration#allowed-kinds
```

### What NOT to Do

❌ "This is probably caused by..."
❌ "I think the issue might be..."
❌ "This typically happens when..."
❌ "Based on my understanding..."

### What TO Do

✅ "The error originates at `src/api/client.ts:45` where..."
✅ "According to https://backstage.io/docs/... this requires..."
✅ "GitHub issue #12345 describes the same symptoms..."
✅ "The changelog for v1.2.3 states: '...'"
✅ "I could not find definitive evidence - needs further investigation"

### When Evidence Is Missing

If you cannot find concrete evidence:
1. State explicitly: "I could not verify this"
2. List what you checked and where
3. Suggest next steps to gather evidence
4. Do NOT present speculation as fact

## Final Step: Visual Debug Summary (REQUIRED)

**ALWAYS create a visual debug summary after completing any investigation.** This is mandatory, not optional. Every support debugging session must end with an interactive visual summary.

To create it, simply prompt: "Create a playground about this debugging session" or include the details inline.

### Why This Is Required

- Makes complex investigations easy to review and share
- Provides a permanent record of the debugging journey
- Helps the team learn from past issues
- Creates professional documentation for customers

### What to Include

The playground should visualize:

1. **Issue Overview**
   - Problem statement in plain language
   - Affected components (visual diagram)
   - Timeline of when issue started

2. **Debugging Journey**
   - Steps taken during investigation
   - What was checked and what was found
   - Key log excerpts with highlights
   - Config comparisons (expected vs actual)

3. **Root Cause Analysis**
   - Visual diagram showing the failure point
   - Chain of events leading to the issue
   - Why this happened (technical explanation made simple)

4. **Solution**
   - Step-by-step fix instructions
   - Before/after comparison
   - Verification steps

5. **Customer Response**
   - Ready-to-send message
   - Professional, clear, and helpful tone
   - Links to relevant documentation

6. **Conversation Log**
   - Summary of our back-and-forth discussion
   - Key decisions made
   - Questions asked and answers given
   - Reference for future similar issues

### Visual Elements to Use

Be creative with visualizations:
- **Flow diagrams** - Show request/response flows, error propagation
- **Timeline charts** - When things happened, deployment history
- **Diff views** - Config changes, before/after
- **Architecture diagrams** - Which components are involved
- **Severity indicators** - Color-coded sections (red for errors, green for solutions)
- **Collapsible sections** - For detailed logs and technical deep-dives
- **Copy buttons** - For customer response, commands, config snippets

### Prompt Template for Playground

When creating the playground, use this structure:

```
Create a visual debugging summary for a support issue investigation.

## Issue Details
- Customer: <customer/instance name>
- Product: Portal / Backstage OSS
- Plugin: <affected plugin>
- Reported Problem: <what the customer reported>

## Investigation Summary
<summary of what we found>

## Key Evidence
- Logs: <relevant log excerpts>
- Config: <relevant config snippets>
- Code: <relevant code references>

## Root Cause
<explanation of what caused the issue>

## Solution
<how to fix it>

## Conversation History
<summary of our debugging conversation>

## Customer Response
<draft message to send>

Create an interactive HTML page with:
1. Clean, professional design
2. Visual diagrams showing the issue flow
3. Collapsible sections for details
4. Timeline of events
5. Side-by-side comparisons where relevant
6. Copy-to-clipboard buttons for the customer response
7. Clear sections for each part of the investigation
8. Color coding (red for problems, green for solutions, yellow for warnings)
```

### Example Flow

1. Complete investigation using the debugging workflow
2. Gather all findings, logs, configs, and evidence
3. Draft customer response
4. Create a playground with the summary (e.g., "Create a playground about this debugging session...")
5. Review the generated visualization
6. Share with team or use for documentation

---

**⚠️ REMINDER: No support debugging session is complete without creating the visual summary playground. Always create it.**
