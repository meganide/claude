---
name: gh-cli
description: GitHub CLI reference for working with PRs, issues, commits, and repositories. Use when needing to interact with GitHub from the command line.
---

# GitHub CLI (gh) Reference

Quick reference for common GitHub CLI operations.

## Prerequisites

- GitHub CLI installed: `brew install gh`
- Authenticated: `gh auth login`

## Pull Requests

### List PRs

```bash
# List open PRs in current repo
gh pr list

# List closed PRs
gh pr list --state closed

# List merged PRs
gh pr list --state merged

# List all PRs (open, closed, merged)
gh pr list --state all

# List your PRs
gh pr list --author @me

# List PRs assigned to you
gh pr list --assignee @me

# List PRs with specific label
gh pr list --label "bug"

# List PRs targeting a specific branch
gh pr list --base main

# Limit results
gh pr list --limit 50

# JSON output for scripting
gh pr list --json number,title,author,state
```

### View PR Details

```bash
# View PR in terminal
gh pr view <number>

# View PR in browser
gh pr view <number> --web

# View specific fields
gh pr view <number> --json title,body,commits,files

# View PR diff
gh pr diff <number>

# View PR checks/status
gh pr checks <number>

# View PR comments
gh pr view <number> --comments
```

### Search PRs

```bash
# Search PRs by title/body
gh pr list --search "fix authentication"

# Search PRs by commit SHA
gh pr list --search "<commit-sha>" --state all

# Search across repos
gh search prs "error message" --repo org/repo

# Search with filters
gh search prs "query" --state open --author username
gh search prs "query" --state closed --merged-at ">2024-01-01"
```

### PR Actions

```bash
# Checkout a PR locally
gh pr checkout <number>

# Create a PR
gh pr create --title "Title" --body "Description"

# Create PR with template
gh pr create --fill  # Uses commit messages

# Create draft PR
gh pr create --draft --title "WIP: Feature"
```

## Issues

### List Issues

```bash
# List open issues
gh issue list

# List closed issues
gh issue list --state closed

# List all issues
gh issue list --state all

# List your issues
gh issue list --author @me

# List issues assigned to you
gh issue list --assignee @me

# List issues with label
gh issue list --label "bug"

# List issues in milestone
gh issue list --milestone "v1.0"

# JSON output
gh issue list --json number,title,author,labels
```

### View Issue Details

```bash
# View issue in terminal
gh issue view <number>

# View in browser
gh issue view <number> --web

# View with comments
gh issue view <number> --comments

# View specific fields
gh issue view <number> --json title,body,comments
```

### Search Issues

```bash
# Search issues
gh search issues "error message" --repo org/repo

# Search with state filter
gh search issues "bug" --state open --repo org/repo

# Search by label
gh search issues "label:bug" --repo org/repo

# Search across all repos in org
gh search issues "query" --owner org
```

## Commits and Code

### View Commits

```bash
# List commits on a PR
gh pr view <number> --json commits

# View commit details via API
gh api repos/{owner}/{repo}/commits/<sha>

# Compare commits
gh api repos/{owner}/{repo}/compare/<base>...<head>
```

### Browse Code

```bash
# View file in browser
gh browse path/to/file.ts

# View file at specific line
gh browse path/to/file.ts:42

# View repo in browser
gh browse

# View specific branch
gh browse --branch feature-branch
```

## Repository

### Repo Info

```bash
# View repo info
gh repo view

# View in browser
gh repo view --web

# View specific repo
gh repo view org/repo

# List repos
gh repo list org --limit 100

# Clone repo
gh repo clone org/repo
```

### Releases

```bash
# List releases
gh release list

# View release
gh release view <tag>

# Download release assets
gh release download <tag>
```

## API Access

For anything not covered by built-in commands, use the API directly:

```bash
# GET request
gh api repos/{owner}/{repo}/pulls/<number>

# Get PR comments
gh api repos/{owner}/{repo}/pulls/<number>/comments

# Get PR reviews
gh api repos/{owner}/{repo}/pulls/<number>/reviews

# Get commit details
gh api repos/{owner}/{repo}/commits/<sha>

# With JQ filtering
gh api repos/{owner}/{repo}/pulls --jq '.[].title'

# Paginate results
gh api repos/{owner}/{repo}/issues --paginate
```

## Useful Patterns

### Find PR for a Commit

```bash
# Search for PR containing commit
gh pr list --search "<commit-sha>" --state all

# Or use API
gh api repos/{owner}/{repo}/commits/<sha>/pulls
```

### Get Full PR History

```bash
# All PRs with details
gh pr list --state all --json number,title,author,mergedAt,state --limit 500
```

### Watch PR Checks

```bash
# Watch checks until complete
gh pr checks <number> --watch
```

### Export to JSON for Processing

```bash
# Export PRs to JSON file
gh pr list --state all --json number,title,author,state > prs.json

# Export with custom fields
gh pr list --json number,title,author,createdAt,mergedAt,additions,deletions
```

## Common Flags

| Flag | Description |
|------|-------------|
| `--repo org/repo` | Specify repository |
| `--json fields` | Output as JSON with specified fields |
| `--jq expression` | Filter JSON output |
| `--limit N` | Limit results |
| `--state open/closed/merged/all` | Filter by state |
| `--author username` | Filter by author |
| `--assignee username` | Filter by assignee |
| `--label name` | Filter by label |
| `--web` | Open in browser |

## JSON Fields Reference

### PR Fields
`number`, `title`, `body`, `state`, `author`, `assignees`, `labels`, `milestone`, `headRefName`, `baseRefName`, `commits`, `files`, `additions`, `deletions`, `changedFiles`, `createdAt`, `updatedAt`, `mergedAt`, `closedAt`, `url`

### Issue Fields
`number`, `title`, `body`, `state`, `author`, `assignees`, `labels`, `milestone`, `comments`, `createdAt`, `updatedAt`, `closedAt`, `url`

## Tips

1. **Use `--web` for complex viewing** - When you need full context, open in browser
2. **Use `--json` for scripting** - Easy to parse and filter
3. **Use `@me` for your items** - `--author @me`, `--assignee @me`
4. **Combine with jq** - `gh pr list --json title | jq '.[].title'`
5. **Use API for edge cases** - `gh api` can do anything the GitHub API supports
