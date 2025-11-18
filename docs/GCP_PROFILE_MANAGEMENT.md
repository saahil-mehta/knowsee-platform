# GCP Profile Management Guide

## Overview

This repository uses multiple GCP authentication mechanisms:

1. **gcloud CLI configuration** - Used by `gcloud` commands in Make targets
2. **Application Default Credentials (ADC)** - Used by Python SDK and application code
3. **.env file** - Used by Docker Compose workflows

To work seamlessly across multiple GCP projects, this toolkit synchronises all three mechanisms.

## Understanding GCP Authentication

### Two Types of Credentials

| Type | Purpose | Command | Persistence |
|------|---------|---------|-------------|
| **gcloud CLI** | Terminal commands (`gcloud`, `gsutil`, etc.) | `gcloud auth login` | Per-account, survives config switches |
| **ADC** | Application code (Python SDK, etc.) | `gcloud auth application-default login` | Global, does NOT auto-switch |

**Key insight**: When you switch gcloud configurations, ADC doesn't automatically update. Your app might still use the old account's credentials.

### ADC Quota Project

API calls are billed to a "quota project". This must be set explicitly:
```bash
gcloud auth application-default set-quota-project PROJECT_ID
```

## Quick Start

### First-Time Setup

1. **Install gcloud CLI**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk

   # Or download from:
   # https://cloud.google.com/sdk/docs/install
   ```

2. **Create a profile and authenticate**
   ```bash
   # Create profile
   gcloud config configurations create knowsee
   gcloud config set project knowsee-platform-development
   gcloud config set account your-email@domain.com

   # Full authentication
   make gcp-login
   ```

### Managing Multiple Projects

```bash
# Create profiles for each project
gcloud config configurations create knowsee
gcloud config set project knowsee-platform-development
gcloud config set account your-email@knowsee.co.uk

gcloud config configurations create work
gcloud config set project work-project-id
gcloud config set account your-email@work.com
```

## Make Commands

### Core Commands

| Command | Description | When to Use |
|---------|-------------|-------------|
| `make gcp-switch PROFILE=x` | Switch profile, update .env, set ADC quota project | Switching between projects |
| `make gcp-login` | Full re-authentication (CLI + ADC + quota) | After switching accounts, or when creds expire |
| `make gcp-status` | Show current configuration and auth status | Debugging, verification |
| `make gcp-setup` | Show setup help | First-time setup |

### When to Use Each Command

**Scenario 1: Switching projects with same account**
```bash
# Just switch - quota project auto-updates
make gcp-switch PROFILE=knowsee-dev
make gcp-switch PROFILE=knowsee-staging
```

**Scenario 2: Switching to different account**
```bash
# Switch profile first
make gcp-switch PROFILE=work

# Then re-authenticate (different account needs new ADC)
make gcp-login
```

**Scenario 3: Credentials expired**
```bash
# Re-authenticate current profile
make gcp-login
```

## What Each Command Does

### `make gcp-switch PROFILE=x`

1. Activates the gcloud configuration
2. Updates `.env` file with `GOOGLE_CLOUD_PROJECT`
3. Sets ADC quota project to the new project
4. Warns if ADC credentials are missing

### `make gcp-login`

1. Authenticates gcloud CLI (`gcloud auth login`)
2. Authenticates ADC (`gcloud auth application-default login`)
3. Sets ADC quota project from current gcloud config

### `make gcp-status`

Displays:
- Active gcloud profile
- Current GCP project (from gcloud and .env)
- Authenticated accounts

## Workflow Examples

### Daily Development

```bash
# Start of day - check status
make gcp-status

# Switch to dev environment
make gcp-switch PROFILE=knowsee-dev

# Work on features...
make playground
make deploy

# Switch to staging for testing
make gcp-switch PROFILE=knowsee-staging
make deploy
```

### Working with Multiple Organisations

```bash
# Morning: Knowsee work
make gcp-switch PROFILE=knowsee
make gcp-login  # Different account needs ADC refresh

# Afternoon: Client work
make gcp-switch PROFILE=client-project
make gcp-login  # Different account again
```

## Troubleshooting

### Error: "Could not set ADC quota project"

ADC credentials don't exist yet. Run:
```bash
make gcp-login
```

### Error: "Permission denied" in Python code

Your ADC is authenticated with a different account than your gcloud config. Run:
```bash
make gcp-login
```

### Error: "GCP project not set"

Run `make gcp-status` to check configuration, then:
```bash
make gcp-switch PROFILE=<your-profile>
```

### Docker containers using wrong project

After switching profiles, restart containers:
```bash
make sagent-down
make sagent
```

### Checking current ADC credentials

```bash
# Show ADC token info
gcloud auth application-default print-access-token

# Show quota project
cat ~/.config/gcloud/application_default_credentials.json | grep quota_project
```

## Technical Details

### File Locations

| File | Purpose |
|------|---------|
| `~/.config/gcloud/configurations/` | gcloud CLI configurations |
| `~/.config/gcloud/application_default_credentials.json` | ADC credentials |
| `.env` | Project-specific environment variables |

### Make Targets That Use gcloud Config

- `make deploy`
- `make data-ingestion`
- Terraform commands

### Make Targets That Use .env File

- `make sagent`
- Docker Compose workflows

### Make Targets That Use ADC

- `make playground` (Python SDK calls)
- Any Python code using `google-cloud-*` libraries

## Quick Reference

### Profile Management

```bash
# List all profiles
gcloud config configurations list

# Create new profile
gcloud config configurations create <name>
gcloud config set project <project-id>
gcloud config set account <email>

# Delete profile
gcloud config configurations delete <name>
```

### Auth Commands

```bash
# CLI auth (per-account)
gcloud auth login

# ADC auth (global)
gcloud auth application-default login

# Set ADC quota project
gcloud auth application-default set-quota-project <project-id>

# List authenticated accounts
gcloud auth list

# Revoke credentials
gcloud auth revoke <account>
gcloud auth application-default revoke
```
