---
name: portal-ops
description: CLI for common Portal operations at Spotify. Use when the user needs to interact with Portal instances - list instances, get configs, manage secrets, view logs, restart services, etc.
---

# Portal Ops CLI

This skill provides access to the `portal-ops` CLI for managing Portal instances at Spotify.

## Prerequisites

The user must have:
- `portal-ops` installed globally: `npm install -g @spotify-internal/portal-ops`
- Google Cloud authentication: `gcloud auth application-default login`

## Available Commands

### Instance Management

```bash
# List all Portal instances
portal-ops list
portal-ops list customer  # Customer instances only
portal-ops list test      # Test instances only

# Get instance details
portal-ops get <instance>

# Find instances by fuzzy matching
portal-ops lookup <search-term>
```

### Config Management

```bash
# Get config for an instance
portal-ops config get -i <instance>

# View config history
portal-ops config history -i <instance>

# Diff config between versions
portal-ops config diff -i <instance> -v <version>

# Export config to file
portal-ops config export -i <instance> -o <output-file>

```

### Config Search (across multiple instances)

```bash
# Search by key
portal-ops config search --key "integrations.github.token" --customer

# Search by value pattern
portal-ops config search --value "*deprecated*" --test

# Combine key and value filters
portal-ops config search --key "*.token" --value "ghp_*" --customer

# JSONata queries for complex searches
portal-ops config search --query '**[$ ~> /oauth/i]' --customer

# Output as JSON
portal-ops config search --key "database" --customer --json
```

Instance selection options for search:
- `--all` - All instances
- `--customer` - Customer instances
- `--test` - Test instances
- `--parent <id>` - Specific parent folder
- `--instances <ids>` - Comma-separated list

### Secrets Management

```bash
portal-ops secrets list -i <instance>
portal-ops secrets get <secret> -i <instance>
```

### Root User Management

```bash
portal-ops root status -i <instance>
portal-ops root password -i <instance>
```

### Tasks

```bash
portal-ops tasks list <plugin> -i <instance>
```

### Logs

```bash
portal-ops logs view -i <instance>
portal-ops logs follow -i <instance>  # Real-time streaming
```

### Cloud Run Operations

```bash
portal-ops cloudrun list -i <instance>
portal-ops cloudrun revisions -i <instance>
portal-ops cloudrun errors -i <instance>

# Environment variables
portal-ops cloudrun env list -i <instance>
portal-ops cloudrun env get <name> -i <instance>
```

### NPM Registry

```bash
portal-ops npm list -i <instance>
```

## Instructions

**Customer name ≠ Instance name**: Customers have company names (e.g., "Acme Corp") but Portal instances have different technical names (e.g., "spc-acme-prod"). When given a customer/company name, use `portal-ops lookup` to find the actual instance name first.

When the user asks to perform Portal operations:

1. Identify which command is needed based on their request
2. **If given a customer/company name**, use `portal-ops lookup <customer-name>` to find the instance name
3. If an instance is required but not specified, ask which instance they want to target
4. Run the appropriate `portal-ops` command using Bash
5. Parse and present the results clearly

Common patterns:
- "customer Acme needs help" -> `portal-ops lookup acme` (find instance name first)
- "get config for X" -> `portal-ops config get -i X`
- "export config for X" -> `portal-ops config export -i X -o <filename>.json`
- "list instances" -> `portal-ops list`
- "find instance X" -> `portal-ops lookup X`
- "view logs for X" -> `portal-ops logs view -i X`

## Config Export Conventions

When exporting configs:

1. Save to the `tmp/` folder in the current project (create if needed)
2. Use this naming format: `<instance-name>-<YYYY-MM-DD-HHmm>.json`

Example command:
```bash
mkdir -p tmp && portal-ops config export -i <instance> -o "tmp/<instance>-$(date +%Y-%m-%d-%H%M).json"
```

Example output: `tmp/spc-onions-pull-2026-01-13-1245.json`

The `tmp/` folder should be gitignored.
