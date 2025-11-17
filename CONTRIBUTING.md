# Contributing to Knowsee Platform

Thank you for your interest in contributing to the Knowsee Platform! This guide will help you set up your development environment and understand the contribution workflow.

## Table of Contents

- [Getting Started](#getting-started)
- [GCP Profile Management](#gcp-profile-management)
- [Development Workflow](#development-workflow)
- [Code Quality](#code-quality)
- [Pull Request Process](#pull-request-process)

## Getting Started

### Prerequisites

Ensure you have the following installed:

- **Node.js 24+** (for frontend development)
- **Python 3.11+**
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** (automatically installed by `make install`)
- **Docker & Docker Compose v2**
- **Google Cloud SDK** (see GCP setup below)
- **Terraform ≥ 1.6**
- **Make, curl, bash** (standard on macOS/Linux)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/knowsee-platform.git
   cd knowsee-platform
   ```

2. **Install dependencies**
   ```bash
   make install
   ```

3. **Configure GCP** (see detailed section below)

## GCP Profile Management

The Knowsee Platform integrates with Google Cloud Platform for agent deployment, data ingestion, and infrastructure management. This section covers all scenarios for setting up and managing GCP profiles.

> **👋 New Contributor?** Most contributors should follow **Scenario 1** below to get access to the official Knowsee GCP project. This is the recommended path for contributing to the platform.

### Which Scenario Applies to You?

| Your Situation | Go To |
|----------------|-------|
| I want to contribute to Knowsee Platform | [Scenario 1](#scenario-1-contributing-to-knowsee-platform-recommended) ⭐ |
| I want my own GCP project for testing | [Scenario 2](#scenario-2-first-time-gcp-user-creating-your-own-project) |
| I already have a GCP project | [Scenario 3](#scenario-3-existing-gcp-user-single-project) |
| I work with multiple GCP projects | [Scenario 4](#scenario-4-multiple-gcp-projects-work--personal) |
| I don't need GCP (code-only changes) | [Scenario 5](#scenario-5-contributing-code-only-no-gcp-access-needed) |
| I'm part of another organisation | [Scenario 6](#scenario-6-organisationteam-development-general) |

### Understanding GCP Projects

**Important distinction:**
- **Project Name** - Human-readable name (e.g., `knowsee-development`)
- **Project ID** - Unique identifier used in commands and `.env` (e.g., `knowsee-platform-development`)

Always use the **Project ID** in your configuration, not the project name.

### Scenario 1: Contributing to Knowsee Platform (Recommended)

If you want to contribute to the official Knowsee deployment:

1. **Request access to the Knowsee GCP project**
   - Email: **s.mehta@knowsee.co.uk**
   - Request: Access to the `knowsee-platform-development` project
   - Provide: Your Google account email address
   - You'll be granted appropriate IAM permissions based on your role

2. **Wait for access confirmation**
   - You'll receive an email from Google Cloud when access is granted
   - Accept the invitation

3. **Install gcloud CLI** (if not already installed)
   ```bash
   # macOS
   brew install --cask google-cloud-sdk

   # Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL

   # Windows
   # Download from: https://cloud.google.com/sdk/docs/install
   ```

4. **Set up your Knowsee profile**
   ```bash
   # Create a profile for Knowsee development
   gcloud config configurations create knowsee
   gcloud config set project knowsee-platform-development
   gcloud config set account your-email@domain.com
   ```

5. **Authenticate**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

6. **Activate the Knowsee profile**
   ```bash
   make gcp-switch PROFILE=knowsee
   ```

7. **Verify setup**
   ```bash
   make gcp-status
   # Should show:
   # GCP project (from gcloud): knowsee-platform-development
   # GCP project (from .env): knowsee-platform-development
   ```

You're now ready to contribute to the official Knowsee deployment!

### Scenario 2: First-Time GCP User (Creating Your Own Project)

If you want to create your own separate GCP project for testing:

1. **Create a GCP Account**
   - Visit https://cloud.google.com/
   - Sign up with your Google account
   - You'll get $300 free credits for 90 days

2. **Create Your First Project**
   - Go to https://console.cloud.google.com/
   - Click "Select a project" → "New Project"
   - **Project name:** Enter a descriptive name (e.g., `my-knowsee-dev`)
   - **Project ID:** Note the auto-generated ID (e.g., `my-knowsee-dev-123456`)
     - This ID is what you'll use in commands and `.env`
     - You can customise it before creating the project

3. **Install gcloud CLI**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk

   # Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL

   # Windows
   # Download from: https://cloud.google.com/sdk/docs/install
   ```

4. **Initialize gcloud**
   ```bash
   gcloud init
   ```
   Follow the prompts to:
   - Log in with your Google account
   - Select your project
   - Set default region (e.g., `europe-west2` or `us-central1`)

5. **Authenticate for Application Default Credentials**
   ```bash
   gcloud auth application-default login
   ```

6. **Set up your `.env` file**
   ```bash
   # Use the Project ID, not the project name
   echo "GOOGLE_CLOUD_PROJECT=my-knowsee-dev-123456" > .env
   ```

7. **Verify setup**
   ```bash
   make gcp-status
   ```

You're now ready to develop! Skip to the [Development Workflow](#development-workflow) section.

### Scenario 3: Existing GCP User (Single Project)

If you already use GCP with one project:

1. **Verify gcloud is installed**
   ```bash
   gcloud --version
   ```

2. **Check your current project**
   ```bash
   gcloud config get-value project
   ```

3. **Set up your `.env` file**
   ```bash
   echo "GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)" > .env
   ```

4. **Verify setup**
   ```bash
   make gcp-status
   ```

### Scenario 4: Multiple GCP Projects (Work & Personal)

If you work with multiple GCP projects (e.g., company project + personal project):

1. **List your current configurations**
   ```bash
   gcloud config configurations list
   ```

2. **Create separate profiles for each project**
   ```bash
   # Example: Knowsee official project
   gcloud config configurations create knowsee
   gcloud config set project knowsee-platform-development
   gcloud config set account your-email@domain.com

   # Example: Your personal project
   gcloud config configurations create personal
   gcloud config set project your-personal-project-id
   gcloud config set account your-personal@gmail.com
   ```

3. **Activate the profile you want to use**
   ```bash
   # Use the Knowsee profile
   make gcp-switch PROFILE=knowsee

   # Or use your personal profile
   make gcp-switch PROFILE=personal
   ```

4. **Verify active configuration**
   ```bash
   make gcp-status
   ```

**What happens when you switch:**
- The gcloud CLI switches to the selected profile
- The `.env` file is automatically updated with the correct `GOOGLE_CLOUD_PROJECT`
- All subsequent `make` commands use the selected project

### Scenario 5: Contributing Code Only (No GCP Access Needed)

If you're contributing code changes that don't require GCP:

1. **Skip GCP setup** - You can develop and test locally without GCP credentials

2. **Use Docker for local development**
   ```bash
   make dev-local
   ```

3. **Run tests locally**
   ```bash
   make check
   ```

4. **Mock services** are available in `dev/docker-compose.yml`

### Scenario 6: Organisation/Team Development (General)

If you're part of a different organisation/team sharing GCP projects:

1. **Get project access from your team lead**
   - They should add your Google account to the project with appropriate IAM roles
   - You'll need at least "Viewer" role for read-only access
   - You'll need "Editor" or specific roles for deployment

   **For Knowsee Platform specifically:** Email s.mehta@knowsee.co.uk with your Google account email

2. **Set up your gcloud configuration**
   ```bash
   gcloud config configurations create knowsee-team
   gcloud config set project <team-project-id>
   gcloud config set account <your-team-email>
   ```

3. **Authenticate**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

4. **Activate the team profile**
   ```bash
   make gcp-switch PROFILE=knowsee-team
   ```

### Common GCP Commands

```bash
# List all your profiles
gcloud config configurations list

# Create a new profile
gcloud config configurations create <profile-name>

# Switch between profiles (using our helper)
make gcp-switch PROFILE=<profile-name>

# Check current configuration
make gcp-status

# Get setup help
make gcp-setup

# Manually activate a profile (without .env update)
gcloud config configurations activate <profile-name>

# Set project for current profile
gcloud config set project <project-id>

# Set account for current profile
gcloud config set account <email>

# Delete a profile
gcloud config configurations delete <profile-name>
```

### Troubleshooting GCP Setup

**Error: "gcloud: command not found"**
```bash
# Install gcloud CLI (see Scenario 1)
brew install --cask google-cloud-sdk  # macOS
```

**Error: "You do not have permission to access project"**
```bash
# Contact your project administrator to grant you access
# Or create your own project (see Scenario 1)
```

**Error: "Application Default Credentials not found"**
```bash
gcloud auth application-default login
```

**Error: "PROFILE not specified" when running make gcp-switch**
```bash
# Correct usage:
make gcp-switch PROFILE=your-profile-name

# Not:
make gcp-switch  # This will show an error
```

**Mismatch between gcloud and .env**
```bash
# Always use make gcp-switch to keep them in sync
make gcp-switch PROFILE=<profile-name>

# Check they match:
make gcp-status
```

## Development Workflow

### Backend Development

1. **Start the ADK playground** (for agent development)
   ```bash
   make playground
   # Opens at http://localhost:8501
   ```

2. **Or start the FastAPI backend** (for API development)
   ```bash
   make local-backend
   # Opens at http://localhost:8000
   # Dev UI: http://localhost:8000/dev-ui
   ```

3. **Make your changes**
   - Edit files in `app/` for agent logic
   - Edit files in `data_ingestion/` for pipeline changes

4. **Test your changes**
   ```bash
   make backend-lint   # Check code quality
   make backend-test   # Run test suite
   ```

### Frontend Development (AG-UI + CopilotKit)

```bash
cd frontend
npm run dev
# Opens at http://localhost:3000
```

### Docker Stack Development

For full-stack local development:

```bash
make dev-local      # Start all services
make dev-local-logs # View logs
make dev-local-down # Stop services
```

Or for the Sagent stack:

```bash
make sagent         # Start Sagent (ADK + AG-UI + CopilotKit)
make sagent-logs    # View all logs
make sagent-down    # Stop services
```

### Infrastructure Changes

1. **Make Terraform changes** in `terraform/`

2. **Format and validate**
   ```bash
   make fmt
   make validate
   ```

3. **Test in dev environment first**
   ```bash
   make dev-plan
   make dev-apply
   ```

4. **Then promote to staging/prod**
   ```bash
   make staging-plan
   make staging-apply
   ```

## Code Quality

### Before Committing

Always run the full check suite:

```bash
make check
```

This runs:
1. Backend linting (codespell, ruff, mypy)
2. Backend tests (unit + integration)
3. Frontend type checking
4. Frontend linting
5. Frontend tests
6. Frontend build

### Code Style

**Python:**
- Use [Ruff](https://docs.astral.sh/ruff/) for linting and formatting
- Type hints required (checked by mypy)
- Docstrings for public functions

**TypeScript:**
- Follow the existing ESLint configuration
- Use proper TypeScript types (avoid `any`)

**Terraform:**
- Run `make fmt` before committing
- Variables should have descriptions

### Testing

**Backend:**
```bash
make backend-test        # All tests
pytest tests/unit        # Unit tests only
pytest tests/integration # Integration tests only
```

**Frontend:**
```bash
cd frontend
npm test                 # Run tests
npm run test:watch      # Watch mode
```

## Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation if needed

3. **Run quality checks**
   ```bash
   make check
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `chore:` Maintenance tasks
   - `refactor:` Code refactoring
   - `test:` Test changes

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure all CI checks pass

## Additional Resources

- **Architecture Context:** See `GEMINI.md` for AI assistant context
- **GCP Profile Details:** See `docs/GCP_PROFILE_MANAGEMENT.md`
- **Make Commands:** Run `make help` for full list
- **ADK Documentation:** https://cloud.google.com/agent-development-kit/docs
- **AG-UI Documentation:** https://github.com/google/ag-ui

## Questions?

If you have questions about contributing:
1. Check the documentation in `docs/`
2. Run `make help` for available commands
3. Open an issue for discussion

Thank you for contributing to Knowsee Platform!
