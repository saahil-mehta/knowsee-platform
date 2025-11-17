# GCP Profile Management Guide

## Overview

This repository uses two different mechanisms for GCP project configuration:

1. **gcloud CLI configuration** - Used by direct `gcloud` commands in Make targets like `make deploy` and `make data-ingestion`
2. **.env file** - Used by Docker Compose workflows like `make sagent`

To work seamlessly across multiple GCP projects, this toolkit automatically synchronises both mechanisms.

## Getting Started with GCP

### First-Time Setup

If you haven't used GCP before:

1. **Install gcloud CLI**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk

   # Or download from:
   # https://cloud.google.com/sdk/docs/install
   ```

2. **Initialise gcloud**
   ```bash
   gcloud init
   ```

3. **Authenticate**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

### Managing Multiple Projects

If you work with multiple GCP projects (e.g., work and personal):

1. **Create named configurations**
   ```bash
   # Create a profile for Knowsee project
   gcloud config configurations create knowsee
   gcloud config set project knowsee-platform-development
   gcloud config set account your-email@domain.com

   # Create a profile for your personal project
   gcloud config configurations create personal
   gcloud config set project your-personal-project-id
   gcloud config set account your-personal@email.com
   ```

2. **List all profiles**
   ```bash
   gcloud config configurations list
   ```

## Seamless Switching

### Quick Commands

```bash
# Switch to any profile
make gcp-switch PROFILE=knowsee
make gcp-switch PROFILE=personal
make gcp-switch PROFILE=<any-profile-name>

# Check current status
make gcp-status

# Get setup help
make gcp-setup
```

### What Happens When You Switch

The switch script automatically:
1. Activates the gcloud configuration
2. Updates the `.env` file with the correct `GOOGLE_CLOUD_PROJECT`
3. Ensures both gcloud CLI and Docker workflows use the same project

## Workflow Examples

### Switching Between Projects

```bash
# Switch to Knowsee project
make gcp-switch PROFILE=knowsee

# Verify configuration
make gcp-status

# Now all commands use the Knowsee project (knowsee-platform-development):
make sagent           # Docker-based development
make deploy           # Deploy to Cloud Run
make data-ingestion   # Submit RAG pipeline

# Switch to personal project
make gcp-switch PROFILE=personal

# Now all commands use your personal project
make sagent
```

## Manual Switching (Advanced)

If you prefer to switch manually without the helper script:

```bash
# Activate gcloud configuration
gcloud config configurations activate <profile-name>

# Manually update .env file
# Edit GOOGLE_CLOUD_PROJECT=<project-id> in .env
```

## Quick Reference

### Common Commands

```bash
# List all profiles
gcloud config configurations list

# Create a new profile
gcloud config configurations create <name>

# Set project for current profile
gcloud config set project <project-id>

# Set account for current profile
gcloud config set account <email>

# Delete a profile
gcloud config configurations delete <name>
```

## Troubleshooting

### Error: "GCP project not set"

Run `make gcp-status` to verify both gcloud and .env are configured correctly.

### .env file not updating

Ensure the switch script is executable:
```bash
chmod +x scripts/switch-gcp-profile.sh
```

### Docker containers using wrong project

After switching profiles, restart Docker containers:
```bash
make sagent-down
make sagent
```

## How It Works

### Make Targets That Use gcloud Config

These targets use `gcloud config get-value project`:
- `make deploy` (Makefile:93)
- `make data-ingestion` (Makefile:109)

### Make Targets That Use .env File

These targets source `.env` before running:
- `make sagent` (Makefile:160)

The switch script ensures both mechanisms stay in sync.
