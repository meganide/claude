---
name: gcp-debug
description: Debug customer GCP instances with read-only operations - view logs, check settings, inspect Cloud Run services, and diagnose issues. Use when investigating customer infrastructure problems.
---

# GCP Debug

Read-only debugging for customer GCP instances. This skill provides safe commands for investigating issues without modifying customer resources.

## Prerequisites

The user must have:
- Google Cloud CLI installed: `gcloud`
- Authenticated: `gcloud auth login` and `gcloud auth application-default login`
- Appropriate IAM permissions for target projects

## Safety Rules

### READ-ONLY ONLY

This skill is **strictly read-only**. The following actions are **FORBIDDEN**:

- Any `gcloud` command with `create`, `delete`, `update`, `set`, `deploy`, `patch`
- Modifying environment variables
- Restarting services
- Rolling back revisions
- Changing IAM policies
- Any destructive or mutating operation

**If the user requests a write operation, refuse and suggest they use a different workflow with proper change management.**

### Safe Commands (READ-ONLY)

Only use these command patterns:
- `gcloud ... list`
- `gcloud ... describe`
- `gcloud ... get-iam-policy` (reading only)
- `gcloud logging read`
- `gcloud monitoring ...` (read operations)
- `gcloud run services describe`
- `gcloud run revisions list`

## Common Debugging Commands

### Project and Authentication

```bash
# List accessible projects
gcloud projects list

# Get current project
gcloud config get-value project

# Set project for queries (safe - only affects local config)
gcloud config set project <project-id>

# Check current authenticated account
gcloud auth list
```

### Cloud Run Services

```bash
# List Cloud Run services
gcloud run services list --project=<project-id>
gcloud run services list --project=<project-id> --region=<region>

# Describe a service (detailed info including env vars, resources, scaling)
gcloud run services describe <service-name> --project=<project-id> --region=<region>
gcloud run services describe <service-name> --project=<project-id> --region=<region> --format=yaml

# List revisions
gcloud run revisions list --service=<service-name> --project=<project-id> --region=<region>

# Describe specific revision
gcloud run revisions describe <revision-name> --project=<project-id> --region=<region>
```

### Logs

```bash
# View recent logs for a Cloud Run service
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=<service-name>" \
  --project=<project-id> \
  --limit=100 \
  --format="table(timestamp,severity,textPayload)"

# View logs with JSON payload
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=<service-name>" \
  --project=<project-id> \
  --limit=50 \
  --format=json

# Filter by severity
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=<service-name> AND severity>=ERROR" \
  --project=<project-id> \
  --limit=100

# Filter by time range (last hour)
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=<service-name> AND timestamp>=\"$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ')\"" \
  --project=<project-id> \
  --limit=100

# Search logs for specific text
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=<service-name> AND textPayload:\"error message\"" \
  --project=<project-id> \
  --limit=100

# All project logs (any resource type)
gcloud logging read "severity>=ERROR" --project=<project-id> --limit=50
```

### Cloud SQL

```bash
# List Cloud SQL instances
gcloud sql instances list --project=<project-id>

# Describe instance
gcloud sql instances describe <instance-name> --project=<project-id>

# List databases
gcloud sql databases list --instance=<instance-name> --project=<project-id>
```

### Secrets Manager

```bash
# List secrets (names only, not values)
gcloud secrets list --project=<project-id>

# Get secret metadata (NOT the value)
gcloud secrets describe <secret-name> --project=<project-id>

# List secret versions
gcloud secrets versions list <secret-name> --project=<project-id>
```

**Note:** Do NOT access secret values unless absolutely necessary and explicitly requested.

### GKE / Kubernetes

```bash
# List GKE clusters
gcloud container clusters list --project=<project-id>

# Describe cluster
gcloud container clusters describe <cluster-name> --project=<project-id> --region=<region>

# Get credentials (to use kubectl)
gcloud container clusters get-credentials <cluster-name> --project=<project-id> --region=<region>

# Then use kubectl for read-only operations
kubectl get pods
kubectl get services
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Compute Engine

```bash
# List VMs
gcloud compute instances list --project=<project-id>

# Describe VM
gcloud compute instances describe <instance-name> --project=<project-id> --zone=<zone>
```

### IAM and Permissions

```bash
# Get IAM policy for project
gcloud projects get-iam-policy <project-id>

# List service accounts
gcloud iam service-accounts list --project=<project-id>

# Describe service account
gcloud iam service-accounts describe <sa-email> --project=<project-id>
```

### Monitoring and Metrics

```bash
# List available metrics
gcloud monitoring metrics-scopes list --project=<project-id>

# Describe a metric descriptor
gcloud monitoring metrics-descriptors describe <metric-type> --project=<project-id>
```

### Networking

```bash
# List VPC networks
gcloud compute networks list --project=<project-id>

# List firewall rules
gcloud compute firewall-rules list --project=<project-id>

# Describe specific firewall rule
gcloud compute firewall-rules describe <rule-name> --project=<project-id>
```

## Debugging Workflow

### Step 1: Identify the Customer Project

For Portal customers, use `portal-ops` to find the project ID:

```bash
# Look up customer instance by name
portal-ops lookup <customer-name>

# Get instance details including GCP project
portal-ops get <instance-name>
```

The `portal-ops get` output includes the GCP project ID for the customer.

Alternatively, search GCP directly:

```bash
# Search GCP projects by name
gcloud projects list --filter="name~<search-term>"

# Set as active project
gcloud config set project <project-id>
```

### Step 2: Check Service Status

```bash
# List services and their status
gcloud run services list --project=<project-id>

# Get detailed service info
gcloud run services describe <service-name> --project=<project-id> --region=<region>
```

### Step 3: Ask for Timeframe

**Before querying logs, always ask the user:**
- When did the issue start?
- What date/time range should we search?

Use their answer to filter logs appropriately.

### Step 4: Review Logs for Timeframe

```bash
# Start with errors in the specified timeframe
# Replace <start-time> with ISO format like 2024-01-15T10:00:00Z
gcloud logging read "resource.labels.service_name=<service-name> AND severity>=ERROR AND timestamp>=\"<start-time>\"" \
  --project=<project-id> --limit=50

# Or use relative time (last N hours)
gcloud logging read "resource.labels.service_name=<service-name> AND severity>=ERROR AND timestamp>=\"$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ')\"" \
  --project=<project-id> --limit=50

# Expand to warnings if needed
gcloud logging read "resource.labels.service_name=<service-name> AND severity>=WARNING AND timestamp>=\"<start-time>\"" \
  --project=<project-id> --limit=100
```

### Step 5: Check Configuration

```bash
# View service configuration (env vars, resources, scaling)
gcloud run services describe <service-name> --project=<project-id> --region=<region> --format=yaml
```

### Step 6: Review Revision History

```bash
# Check recent deployments/revisions
gcloud run revisions list --service=<service-name> --project=<project-id> --region=<region>
```

## Output Format

When reporting findings, structure as:

```markdown
## GCP Debug Summary

### Target
- Project: <project-id>
- Service: <service-name>
- Region: <region>

### Service Status
- Status: ACTIVE/UNHEALTHY/etc.
- Latest Revision: <revision>
- Traffic: <traffic allocation>

### Issues Found
1. **Issue description**
   - Evidence: <log excerpts, config details>
   - Severity: HIGH/MEDIUM/LOW

### Relevant Logs
<formatted log excerpts>

### Configuration Notes
<any notable config settings>

### Recommendations
<read-only recommendations - suggest what to investigate further>
```

## Instructions

When debugging a customer GCP instance:

1. **Always confirm the project ID** before running commands
2. **Always ask for the date/timeframe** before querying logs - ask the user:
   - When did the issue start?
   - What time range should we search? (e.g., last hour, last 24 hours, specific date)
3. **Use read-only commands only** - never modify anything
4. **Start with high-level status** before diving into logs
5. **Filter logs progressively** - errors first, then expand
6. **Document findings** with specific log entries and timestamps
7. **Provide evidence** - include actual command output in reports

If the user requests any write operation:
- Politely refuse
- Explain this skill is read-only
- Suggest appropriate change management processes
