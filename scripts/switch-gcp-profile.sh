#!/bin/bash
# Switch GCP profile and update .env file
set -euo pipefail

PROFILE="${1:-}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo ""
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║          KNOWSEE · GCP Setup Required                    ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  gcloud CLI is not installed."
    echo ""
    echo "  To get started with GCP:"
    echo "    1. Install gcloud CLI:"
    echo "       https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "    2. Initialize gcloud:"
    echo "       gcloud init"
    echo ""
    echo "    3. Create additional profiles (optional):"
    echo "       gcloud config configurations create <profile-name>"
    echo "       gcloud config set project <project-id>"
    echo "       gcloud config set account <email>"
    echo ""
    exit 1
fi

if [[ -z "$PROFILE" ]]; then
    echo ""
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║          KNOWSEE · GCP Profile Management                ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Usage: ./scripts/switch-gcp-profile.sh <profile-name>"
    echo ""
    echo "  Available profiles:"
    echo ""
    gcloud config configurations list | sed 's/^/    /'
    echo ""
    echo "  To create a new profile:"
    echo "    gcloud config configurations create <profile-name>"
    echo "    gcloud config set project <project-id>"
    echo "    gcloud config set account <email>"
    echo ""
    exit 1
fi

echo ""
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║          KNOWSEE · Switching GCP Profile                 ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo ""

# Activate the gcloud configuration
echo "  → Activating gcloud configuration: $PROFILE"
gcloud config configurations activate "$PROFILE"

# Get the project ID from the active configuration
PROJECT_ID=$(gcloud config get-value project)

echo "  → Active project: $PROJECT_ID"

# Update .env file
if [[ -f .env ]]; then
    # Use sed to update GOOGLE_CLOUD_PROJECT in .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires empty string after -i
        sed -i '' "s/^GOOGLE_CLOUD_PROJECT=.*/GOOGLE_CLOUD_PROJECT=$PROJECT_ID/" .env
    else
        # Linux
        sed -i "s/^GOOGLE_CLOUD_PROJECT=.*/GOOGLE_CLOUD_PROJECT=$PROJECT_ID/" .env
    fi
    echo "  → Updated .env file with GOOGLE_CLOUD_PROJECT=$PROJECT_ID"
else
    echo "  ⚠️  Warning: .env file not found"
fi

echo ""
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║  ✅ Profile switched successfully!                        ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Configuration:"
echo "    gcloud config: $PROFILE"
echo "    GCP project:   $PROJECT_ID"
echo "    .env updated:  ✓"
echo ""
