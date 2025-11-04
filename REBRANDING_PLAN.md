# Knowsee Platform Rebranding - Comprehensive Implementation Guide

## Executive Summary

**Objective:** Complete rebranding of the Onyx platform to Knowsee while maintaining upstream compatibility with the `onyx-foss` repository.

**Approach:** Badge Engineering (Hybrid) - Rebrand all user-facing elements while preserving internal backend structure.

**Scope:** ~300-400 files, ~2,500-3,500 line changes

**Risk Level:** Low-Medium

---

## Background & Context

### Project Details
- **Repository:** `/Users/saahil/Documents/GitHub/knowsee-platform`
- **Current State:** Fork of `https://github.com/onyx-dot-app/onyx-foss.git` (MIT licensed)
- **Upstream Remote:** `onyx-upstream` tracked in git
- **Current Branch:** `main`
- **Git Status:** Clean (as of conversation start)

### Technology Stack
- **Backend:** Python 3.11, FastAPI, SQLAlchemy, Alembic, Celery
- **Frontend:** Next.js 15+, React 18, TypeScript, Tailwind CSS
- **Database:** PostgreSQL with Redis caching
- **Search:** Vespa vector database
- **Infrastructure:** Docker, Kubernetes (Helm), AWS (CloudFormation, Terraform)

### Branding Assets
- **Location:** `/Users/saahil/Downloads/assets` (permission issues - requires manual copy)
- **Contents:** Font and logo variations
- **Brand Color:** #6214D9 (for accents, highlights, glows)

---

## Key Decisions Made

### 1. Rebranding Scope: Badge Engineering (Hybrid Approach)

**Decision:** Use badge engineering approach rather than full structural rename.

**Rationale:**
- Maintains compatibility with upstream MIT OSS project
- Allows merging future upstream features
- 95% of user-facing rebrand effect with 35% of the work
- Much lower risk of breaking imports/dependencies

**What Changes:**
- ✅ All user-facing UI text and components
- ✅ All documentation and README files
- ✅ Docker service names and images
- ✅ Helm charts and deployment templates
- ✅ Environment variable prefixes (ONYX_* → KNOWSEE_*)
- ✅ CloudFormation/Terraform resource names
- ✅ Logos, icons, favicons, branding assets
- ✅ Frontend component names
- ✅ API response messages and error strings

**What Stays Unchanged:**
- ❌ Backend Python package name (`backend/onyx/`)
- ❌ Python imports (`from onyx import ...`)
- ❌ Database table/column names
- ❌ Migration file names
- ❌ Internal backend variable/class names (unless user-facing)
- ❌ Package name in `pyproject.toml`

### 2. Naming Conventions

**Slack Bot:** `onyxbot` → `knowsee-bot` (with hyphens)

**Environment Variables:** `ONYX_*` → `KNOWSEE_*` (complete rename)
- Examples: `ONYX_BOT_NUM_RETRIES` → `KNOWSEE_BOT_NUM_RETRIES`
- `ONYX_VERSION` → `KNOWSEE_VERSION`

**Docker Services:**
- `onyx-postgres` → `knowsee-postgres`
- `onyx-api` → `knowsee-api`
- `onyx-webserver` → `knowsee-webserver`
- etc.

### 3. Database Migrations

**Decision:** Leave migration files completely unchanged (both filenames and content).

**Rationale:**
- Historical records of schema changes
- Modifying them risks breaking database state
- Not user-facing (developers only)
- Essential for upstream compatibility

**Examples of files left unchanged:**
- `15326fcec57e_introduce_onyx_apis.py`
- `54a74a0417fc_danswerbot_onyxbot.py`
- `570282d33c49_track_onyxbot_explicitly.py`
- `dba7f71618f5_onyx_custom_tool_flow.py`

### 4. Documentation Strategy

**Decision:** Keep linking to `https://docs.onyx.app/` for now.

**Rationale:**
- Fast implementation - focus on code rebranding first
- Can set up custom Mintlify docs (docs.knowsee.com) in future phase
- Current repo has no documentation (deleted in commit `de58fe2`)
- 30+ links to upstream docs throughout codebase

**Future Option:** Fork and rebrand Onyx docs repository later.

---

## Scope Analysis - Complete Findings

### Total Impact
- **Files with "onyx" references:** ~1,050-1,100 total
- **Files to modify (hybrid approach):** ~300-400
- **Total occurrences:** 10,000+ across all files

### Breakdown by Category

#### 1. Frontend (TypeScript/JavaScript) - ~118 Files
**Total References:** 406 occurrences

**Component Files to Rename:**
- `/web/src/components/OnyxInitializingLoader.tsx` → `KnowseeInitializingLoader.tsx`
- `/web/src/app/admin/api-key/OnyxApiKeyForm.tsx` → `KnowseeApiKeyForm.tsx`
- `/web/src/app/ee/admin/performance/usage/OnyxBotChart.tsx` → `KnowseeBotChart.tsx`

**Icon/Logo Files:**
- `/web/public/onyx.ico` → `knowsee.ico`
- `/web/src/icons/onyx-logo.tsx` → `knowsee-logo.tsx`
- `/web/src/icons/onyx-octagon.tsx` → `knowsee-octagon.tsx`

**String Replacements Needed In:**
- Chart components (performance analytics)
- Admin forms and configuration pages
- Constants and utility files
- Landing pages and auth pages
- Error messages and user feedback
- All UI text visible to users

#### 2. Configuration & Deployment - ~92 Files
**Total References:** 763 occurrences

**Docker Compose Files:**
- `/deployment/docker_compose/docker-compose.yml`
- `/deployment/docker_compose/docker-compose.prod.yml`
- `/deployment/docker_compose/docker-compose.prod-cloud.yml`
- `/deployment/docker_compose/docker-compose.prod-no-letsencrypt.yml`
- `/deployment/docker_compose/docker-compose.search-testing.yml`
- `/deployment/docker_compose/docker-compose.model-server-test.yml`
- `/deployment/docker_compose/docker-compose.multitenant-dev.yml`
- `/onyx_data/deployment/docker-compose.yml`

**Helm Charts (~50 files):**
- Directory: `/deployment/helm/charts/onyx/`
- `Chart.yaml` - Chart name and description
- `values.yaml` - Service names, labels, annotations
- `/templates/*.yaml` - All deployment templates
- Service names: `onyx-api`, `onyx-webserver`, etc.

**CloudFormation Templates (~40 files):**
- Directory: `/deployment/aws_ecs_fargate/cloudformation/`
- Files to rename:
  - `onyx_acm_template.yaml` → `knowsee_acm_template.yaml`
  - `onyx_cluster_template.yaml` → `knowsee_cluster_template.yaml`
  - `onyx_efs_template.yaml` → `knowsee_efs_template.yaml`
  - `onyx_backend_api_server_service_template.yaml` → `knowsee_backend_api_server_service_template.yaml`
  - And ~36 more template files

**Terraform Modules:**
- `/deployment/terraform/modules/aws/onyx/` → May need directory rename
- Resource names and identifiers throughout

**Environment Templates:**
- `/deployment/docker_compose/env.template`
- `/deployment/docker_compose/env.prod.template`
- `/deployment/docker_compose/env.multilingual.template`
- `/deployment/docker_compose/env.nginx.template`

#### 3. Documentation - ~23 Files
**Major Files:**
- `/README.md` - ~40+ mentions of "Onyx"
- `/CLAUDE.md` - Project overview (appears in Claude Code context)
- `/CONTRIBUTING.md`
- `/CONTRIBUTING_MACOS.md`
- `/CONTRIBUTING_VSCODE.md`
- `/backend/onyx/README.md` (content only, not filename)
- `/backend/onyx/file_store/README.md`
- `/web/README.md`
- `/web/STANDARDS.md`
- `/web/tests/README.md`
- `/deployment/helm/README.md`
- `/deployment/docker_compose/README.md`
- `/deployment/aws_ecs_fargate/cloudformation/README.md`
- `/deployment/terraform/modules/aws/README.md`
- Various connector README files

**Documentation Links (30+ references):**
All currently point to `https://docs.onyx.app/` - will remain unchanged for now

**Key file with doc links:**
- `/web/src/lib/sources.ts` - Connector documentation links

#### 4. GitHub Workflows - 18 Files
**Directory:** `.github/workflows/`

**Files to Update:**
- `docker-build-push-*.yml` - Docker image naming
- `helm-chart-releases.yml` - Chart release workflow
- `pr-*.yml` - PR workflow files
- `tag-nightly.yml`
- `docker-tag-latest.yml`
- `sync_foss.yml`
- Others with workflow names/descriptions

#### 5. Backend Configuration (User-Facing Strings Only)
**NOT changing package structure, only configuration values**

**Files with env var definitions:**
- `/backend/shared_configs/configs.py` - `LOG_FILE_NAME = "onyx"` → `"knowsee"`
- `/backend/onyx/configs/constants.py` - 31+ display constant references
- `/backend/onyx/configs/app_configs.py` - 25+ configuration references
- `/backend/onyx/configs/onyxbot_configs.py` - ONYX_BOT_* env variables

**Environment Variables to Rename:**
- `ONYX_BOT_NUM_RETRIES` → `KNOWSEE_BOT_NUM_RETRIES`
- `ONYX_BOT_NUM_CHANNELS_TO_PROCESS` → `KNOWSEE_BOT_NUM_CHANNELS_TO_PROCESS`
- `ONYX_VERSION` → `KNOWSEE_VERSION`
- `LOG_FILE_NAME = "onyx"` → `LOG_FILE_NAME = "knowsee"`
- All other `ONYX_*` prefixed variables

#### 6. Test Files
**Note:** Only modify user-facing strings and test assertions that check for "Onyx" branding

**Test Data Files:**
- `/backend/tests/integration/tests/indexing/file_connector/test_files/.onyx_metadata.json` → `.knowsee_metadata.json`
- Various test data JSON files with "Onyx" string assertions

**DO NOT modify:**
- Import statements in tests
- Internal test logic that doesn't verify user-facing behavior

---

## Detailed Implementation Plan

### Phase 1: Asset Integration & Preparation

**Objective:** Get branding assets in place before code changes

**Steps:**
1. Request user to copy assets from `/Users/saahil/Downloads/assets` to `web/public/assets/` or provide access
2. Identify all asset files:
   - Logo files (SVG, PNG variations)
   - Font files
   - Favicon/icon files
3. Create backup of existing Onyx assets
4. Replace logo files:
   - `web/public/onyx.ico` → `web/public/knowsee.ico`
   - Logo components in `web/src/icons/`
5. Update `tailwind.config.ts` or theme file with brand color #6214D9
6. Update `next.config.js` if it references icon paths

**Files Modified:** ~5-10 files
**Critical:** Favicon, primary logo, icon components

---

### Phase 2: Frontend Rebranding

**Objective:** Rebrand all user-facing UI elements

#### 2.1 Component File Renaming
**Files to rename (move and update imports):**
```
web/src/components/OnyxInitializingLoader.tsx → KnowseeInitializingLoader.tsx
web/src/app/admin/api-key/OnyxApiKeyForm.tsx → KnowseeApiKeyForm.tsx
web/src/app/ee/admin/performance/usage/OnyxBotChart.tsx → KnowseeBotChart.tsx
web/src/icons/onyx-logo.tsx → knowsee-logo.tsx
web/src/icons/onyx-octagon.tsx → knowsee-octagon.tsx
```

**For each renamed component:**
1. Rename the file
2. Update the component name in the file
3. Find all imports of the old component
4. Update import paths and component usage

#### 2.2 String Replacements in TypeScript/JavaScript
**Pattern:** Find "Onyx" (case variations) → Replace with "Knowsee"

**Key files (~118 total):**
- All files in `web/src/app/admin/`
- All files in `web/src/components/`
- Chart and analytics components
- Error message components
- Configuration forms
- Landing pages (`web/src/app/`)
- Authentication pages
- Constants files

**String replacement examples:**
- "Onyx" → "Knowsee"
- "onyx" → "knowsee"
- "ONYX" → "KNOWSEE"
- "Onyx's" → "Knowsee's"
- "an Onyx" → "a Knowsee"

**Watch out for:**
- Template strings
- JSX text content
- Alt text for images
- Aria labels for accessibility
- Error message strings
- Console.log messages that users might see
- Comments in code that explain user-facing features

#### 2.3 Update Icon and Asset References
**Find and replace in all TypeScript files:**
- `import OnyxLogo from '@/icons/onyx-logo'` → `import KnowseeLogo from '@/icons/knowsee-logo'`
- `<OnyxLogo />` → `<KnowseeLogo />`
- `/onyx.ico` → `/knowsee.ico`
- Alt text: `alt="Onyx Logo"` → `alt="Knowsee Logo"`

**Files Modified:** ~118 files
**Tools:** Find/replace with regex, bulk rename for component files

---

### Phase 3: Docker & Container Infrastructure

**Objective:** Rebrand all Docker services, containers, images, and networks

#### 3.1 Docker Compose Files (8 files)
**For each docker-compose*.yml file:**

**Service name changes:**
```yaml
# OLD
services:
  onyx-postgres:
  onyx-redis:
  onyx-api:
  onyx-webserver:
  onyx-background:
  onyx-nginx:
  onyx-vespa:

# NEW
services:
  knowsee-postgres:
  knowsee-redis:
  knowsee-api:
  knowsee-webserver:
  knowsee-background:
  knowsee-nginx:
  knowsee-vespa:
```

**Container name changes:**
```yaml
# OLD
container_name: onyx-relational_db-1

# NEW
container_name: knowsee-relational_db-1
```

**Image name changes (if using custom registry):**
```yaml
# OLD
image: onyxlabs/onyx-backend:latest

# NEW
image: knowsee/knowsee-backend:latest
```

**Volume names:**
```yaml
# OLD
volumes:
  onyx_postgres_data:
  onyx_vespa_data:

# NEW
volumes:
  knowsee_postgres_data:
  knowsee_vespa_data:
```

**Network names:**
```yaml
# OLD
networks:
  onyx-network:

# NEW
networks:
  knowsee-network:
```

**Environment variables in compose:**
- Update any `ONYX_*` → `KNOWSEE_*` in environment sections

**Files to modify:**
- `deployment/docker_compose/docker-compose.yml`
- `deployment/docker_compose/docker-compose.prod.yml`
- `deployment/docker_compose/docker-compose.prod-cloud.yml`
- `deployment/docker_compose/docker-compose.prod-no-letsencrypt.yml`
- `deployment/docker_compose/docker-compose.search-testing.yml`
- `deployment/docker_compose/docker-compose.model-server-test.yml`
- `deployment/docker_compose/docker-compose.multitenant-dev.yml`
- `onyx_data/deployment/docker-compose.yml`

#### 3.2 Dockerfile Updates
**Check all Dockerfile files for:**
- LABEL directives with product name
- ENV variables with ONYX_ prefix
- Any hardcoded "onyx" strings in paths (outside of /backend/onyx/)
- Comments that mention Onyx

**Common Dockerfiles:**
- `backend/Dockerfile`
- `web/Dockerfile`
- Any model server Dockerfiles

**Files Modified:** ~8-10 Dockerfile variations

---

### Phase 4: Environment Variables & Configuration

**Objective:** Rename all ONYX_* environment variables to KNOWSEE_*

#### 4.1 Environment Variable Definitions in Python

**File: `backend/onyx/configs/onyxbot_configs.py`**
```python
# OLD
ONYX_BOT_NUM_RETRIES = os.getenv("ONYX_BOT_NUM_RETRIES", "5")
ONYX_BOT_NUM_CHANNELS_TO_PROCESS = os.getenv("ONYX_BOT_NUM_CHANNELS_TO_PROCESS")

# NEW
KNOWSEE_BOT_NUM_RETRIES = os.getenv("KNOWSEE_BOT_NUM_RETRIES", "5")
KNOWSEE_BOT_NUM_CHANNELS_TO_PROCESS = os.getenv("KNOWSEE_BOT_NUM_CHANNELS_TO_PROCESS")
```

**File: `backend/shared_configs/configs.py`**
```python
# OLD
LOG_FILE_NAME = "onyx"

# NEW
LOG_FILE_NAME = "knowsee"
```

**File: `backend/onyx/__init__.py`**
```python
# OLD
ONYX_VERSION = os.getenv("ONYX_VERSION", "unknown")

# NEW
KNOWSEE_VERSION = os.getenv("KNOWSEE_VERSION", "unknown")
```

**Files to update:**
- `backend/onyx/configs/constants.py` - 31+ references
- `backend/onyx/configs/app_configs.py` - 25+ references
- `backend/onyx/configs/onyxbot_configs.py` - All ONYX_BOT_* variables
- Any other config files with ONYX_ env vars

**Note:** Variable names change, but import statements don't (stays `from onyx.configs import ...`)

#### 4.2 Environment Template Files

**Files to update:**
- `deployment/docker_compose/env.template`
- `deployment/docker_compose/env.prod.template`
- `deployment/docker_compose/env.multilingual.template`
- `deployment/docker_compose/env.nginx.template`

**Example changes:**
```bash
# OLD
ONYX_BOT_NUM_RETRIES=5
ONYX_VERSION=1.0.0

# NEW
KNOWSEE_BOT_NUM_RETRIES=5
KNOWSEE_VERSION=1.0.0
```

#### 4.3 Display Configuration Values

**Files with display strings:**
- Constants files with UI text
- Error message templates
- Log message formats that users see
- API response messages

**Files Modified:** ~15-20 config files

---

### Phase 5: Deployment Infrastructure

**Objective:** Rebrand all deployment templates and infrastructure as code

#### 5.1 Helm Charts (~50 files)

**Directory:** `deployment/helm/charts/onyx/`

**File: Chart.yaml**
```yaml
# OLD
name: onyx
description: Onyx - Open Source Enterprise Search and AI Platform
keywords:
  - onyx
  - search

# NEW
name: knowsee
description: Knowsee - Open Source Enterprise Search and AI Platform
keywords:
  - knowsee
  - search
```

**File: values.yaml**
```yaml
# OLD
nameOverride: "onyx"
fullnameOverride: "onyx"
image:
  repository: onyxlabs/onyx-backend

services:
  api:
    name: onyx-api
  webserver:
    name: onyx-webserver

# NEW
nameOverride: "knowsee"
fullnameOverride: "knowsee"
image:
  repository: knowsee/knowsee-backend

services:
  api:
    name: knowsee-api
  webserver:
    name: knowsee-webserver
```

**Template files (all in `deployment/helm/charts/onyx/templates/`):**
- Update all service selectors
- Update all label values
- Update all annotation values
- Update configmap names
- Update secret names
- Update ingress host patterns
- Update service names

**Example template changes:**
```yaml
# OLD
metadata:
  name: {{ include "onyx.fullname" . }}-api
  labels:
    app: onyx-api

# NEW
metadata:
  name: {{ include "knowsee.fullname" . }}-api
  labels:
    app: knowsee-api
```

**Files to modify:** All ~50 files in helm chart directory

#### 5.2 CloudFormation Templates (~40 files)

**Directory:** `deployment/aws_ecs_fargate/cloudformation/`

**Files to rename:**
```
onyx_acm_template.yaml → knowsee_acm_template.yaml
onyx_cluster_template.yaml → knowsee_cluster_template.yaml
onyx_efs_template.yaml → knowsee_efs_template.yaml
onyx_alb_template.yaml → knowsee_alb_template.yaml
onyx_backend_api_server_service_template.yaml → knowsee_backend_api_server_service_template.yaml
onyx_backend_api_server_task_template.yaml → knowsee_backend_api_server_task_template.yaml
... (and ~34 more files)
```

**Content updates in each template:**
- Stack names and descriptions
- Resource names (ECS services, task definitions, ALB target groups)
- Container names in task definitions
- Image repository names
- Tag values (Name, Project, Component)
- Parameter descriptions
- Output names and descriptions

**Example:**
```yaml
# OLD
Description: "Onyx Backend API Server Service"
Resources:
  OnyxAPIService:
    Type: AWS::ECS::Service
    Properties:
      ServiceName: onyx-api

# NEW
Description: "Knowsee Backend API Server Service"
Resources:
  KnowseeAPIService:
    Type: AWS::ECS::Service
    Properties:
      ServiceName: knowsee-api
```

**Files to modify:** All ~40 CloudFormation template files

#### 5.3 Terraform Modules

**Directory:** `deployment/terraform/modules/aws/onyx/`

**Considerations:**
- Module directory name: May rename to `knowsee/`
- Resource names and identifiers throughout modules
- Variable descriptions
- Output descriptions
- Tags and naming conventions

**Example:**
```hcl
# OLD
resource "aws_ecs_service" "onyx_api" {
  name = "onyx-api"

  tags = {
    Name    = "onyx-api"
    Project = "onyx"
  }
}

# NEW
resource "aws_ecs_service" "knowsee_api" {
  name = "knowsee-api"

  tags = {
    Name    = "knowsee-api"
    Project = "knowsee"
  }
}
```

**Files Modified:** All Terraform files in module directory

---

### Phase 6: Documentation & Markdown Files

**Objective:** Update all documentation to reflect Knowsee branding

#### 6.1 Main README.md

**File:** `/README.md` (~40+ mentions of "Onyx")

**Updates needed:**
- Title: "# Onyx" → "# Knowsee"
- Project description
- All feature descriptions
- Installation instructions (if they mention "onyx")
- Links and references
- Badges if any
- Contributor acknowledgments
- License section (if it mentions project name)

**Example:**
```markdown
# OLD
# Onyx

Onyx is an open-source enterprise search and AI platform...

# NEW
# Knowsee

Knowsee is an open-source enterprise search and AI platform...
```

#### 6.2 CLAUDE.md

**File:** `/CLAUDE.md`

**Updates needed:**
- Project overview section
- Background section: "**Onyx** (formerly Danswer)" → "**Knowsee** (forked from Onyx)"
- All references in examples and descriptions
- Architecture overview

**Important:** This file is read by Claude Code as project context

#### 6.3 Contributing Guides

**Files:**
- `/CONTRIBUTING.md`
- `/CONTRIBUTING_MACOS.md`
- `/CONTRIBUTING_VSCODE.md`

**Updates:**
- Project name throughout
- Example commands if they reference "onyx"
- Development setup instructions
- Testing instructions

#### 6.4 Component and Module READMEs

**Files (content only, not filenames):**
- `/backend/onyx/README.md` - Stays in same location, update content
- `/backend/onyx/file_store/README.md` - Update content
- `/web/README.md`
- `/web/STANDARDS.md`
- `/web/tests/README.md`
- `/deployment/helm/README.md`
- `/deployment/docker_compose/README.md`
- `/deployment/aws_ecs_fargate/cloudformation/README.md`
- `/deployment/terraform/modules/aws/README.md`
- Connector-specific READMEs if they exist

**Updates:**
- Replace "Onyx" with "Knowsee" in descriptive text
- Update any command examples if needed
- Keep technical details (imports, etc.) unchanged since we're preserving backend structure

#### 6.5 Documentation Links

**Current state:** 30+ links to `https://docs.onyx.app/` throughout codebase

**Decision:** Leave unchanged for now (keeping upstream docs)

**Future consideration:** Note in README that docs are from upstream project

**Files Modified:** ~23 documentation files

---

### Phase 7: GitHub Workflows & CI/CD

**Objective:** Update workflow names, Docker image builds, and release processes

**Directory:** `.github/workflows/`

#### 7.1 Docker Build/Push Workflows

**Files:** `docker-build-push-*.yml`

**Updates needed:**
- Workflow name
- Image repository names
- Image tags
- Docker build arguments if they reference ONYX_*
- Step names and descriptions

**Example:**
```yaml
# OLD
name: Build and Push Onyx Images
jobs:
  build:
    steps:
      - name: Build Onyx Backend Image
        run: docker build -t onyxlabs/onyx-backend:${{ github.sha }} .

# NEW
name: Build and Push Knowsee Images
jobs:
  build:
    steps:
      - name: Build Knowsee Backend Image
        run: docker build -t knowsee/knowsee-backend:${{ github.sha }} .
```

#### 7.2 Helm Chart Releases

**File:** `helm-chart-releases.yml`

**Updates:**
- Workflow name
- Chart repository references
- Release names
- Chart path if directory renamed
- Descriptions

#### 7.3 Other Workflows

**Files:** `pr-*.yml`, `tag-nightly.yml`, `docker-tag-latest.yml`, `sync_foss.yml`

**Updates:**
- Workflow names
- Job names
- Step descriptions
- Any output messages
- Notification messages if they mention "Onyx"

**Files Modified:** All 18 workflow files

---

### Phase 8: Bot & Integration Naming

**Objective:** Rebrand Slack bot and connector integrations

#### 8.1 Slack Bot (onyxbot → knowsee-bot)

**User-facing changes only:**

**Files to update:**
- `backend/onyx/configs/onyxbot_configs.py` - Display name strings, env var values
- Slack bot registration/setup documentation
- Any API endpoints that return bot information
- Frontend components showing bot status
- Error messages mentioning the bot

**Example:**
```python
# Configuration display strings
BOT_DISPLAY_NAME = "Knowsee Bot"  # User-facing
BOT_USERNAME = "knowsee-bot"      # Slack username

# Keep internal code structure
# File stays at: backend/onyx/configs/onyxbot_configs.py
# Imports stay: from onyx.configs.onyxbot_configs import ...
```

#### 8.2 Connector Display Names

**Files with connector branding:**
- `backend/onyx/connectors/confluence/onyx_confluence.py` - Display strings only
- `backend/onyx/connectors/salesforce/onyx_salesforce.py` - Display strings only
- `backend/onyx/connectors/slack/onyx_slack_web_client.py` - Display strings only
- `backend/onyx/connectors/slack/onyx_retry_handler.py` - Display strings only

**Keep unchanged:**
- File paths and names (stay in `backend/onyx/connectors/`)
- Class names (internal backend)
- Import statements

**Update:**
- User-facing error messages
- Log messages shown to users
- API response strings
- Documentation strings

**Files Modified:** ~10-15 bot and integration files

---

### Phase 9: Testing & Verification

**Objective:** Ensure all changes work correctly before deployment

#### 9.1 Build Verification

**Frontend Build:**
```bash
cd web
npm install
npm run build
# Verify no import errors
# Check output for "Onyx" in bundle (should be minimal/none)
```

**Backend Verification:**
```bash
cd backend
source .venv/bin/activate
python -c "from onyx.configs import constants"  # Should still work
# Verify imports still function with unchanged package name
```

**Docker Compose Build:**
```bash
cd deployment/docker_compose
docker-compose -f docker-compose.yml build
# Verify all services build successfully with new names
```

#### 9.2 Visual Verification

**Start services:**
```bash
docker-compose up
```

**Check:**
- [ ] UI displays "Knowsee" not "Onyx"
- [ ] Logos appear correctly (new Knowsee logos)
- [ ] Favicon shows in browser tab
- [ ] Error messages say "Knowsee"
- [ ] About/version page shows "Knowsee"
- [ ] Login page branding
- [ ] Admin dashboard branding
- [ ] Bot messages in Slack say "knowsee-bot"

#### 9.3 Configuration Verification

**Environment variables:**
```bash
# Check that services read new env vars
docker-compose exec knowsee-api env | grep KNOWSEE
# Should show KNOWSEE_* variables
```

**Service discovery:**
```bash
# Verify services can find each other with new names
docker-compose exec knowsee-api ping knowsee-postgres
docker-compose exec knowsee-api ping knowsee-redis
```

**Logs:**
```bash
# Check that logging works
tail -f backend/log/knowsee_debug.log
# Should see "knowsee" in log file name and content
```

#### 9.4 Testing Checklist

**Frontend:**
- [ ] All pages load without errors
- [ ] No console errors about missing components
- [ ] All icons and images display
- [ ] Text says "Knowsee" throughout
- [ ] Brand color (#6214D9) appears correctly

**Backend:**
- [ ] API responds correctly
- [ ] Database connections work
- [ ] Redis connections work
- [ ] Vespa connections work
- [ ] Environment variables read correctly
- [ ] Logs write to correct location

**Docker:**
- [ ] All containers start successfully
- [ ] Container names correct (knowsee-*)
- [ ] Networks functional
- [ ] Volumes mount correctly
- [ ] Service discovery works

**Integration:**
- [ ] Can log in
- [ ] Can create connector
- [ ] Can run search
- [ ] Bot responds in Slack (if configured)
- [ ] File uploads work

#### 9.5 Search for Remaining "Onyx" References

**Final sweep:**
```bash
# Search for remaining case-sensitive "Onyx" in user-facing files
grep -r "Onyx" web/src/ --exclude-dir=node_modules | grep -v ".next"
grep -r "ONYX_" deployment/ | grep -v ".git"
grep -r "onyx-" deployment/docker_compose/

# Should find minimal results (only in backend/onyx/ paths which we're keeping)
```

---

## Files Explicitly NOT Modified

### Critical - Do Not Touch

**1. Python Package Structure:**
- `/backend/onyx/` - Directory name stays
- All Python imports: `from onyx import ...` - No changes
- `backend/pyproject.toml` - Package name stays "onyx"
- All module names in `backend/onyx/*`

**2. Database:**
- `/backend/alembic/versions/*.py` - All migration files unchanged
- Table names in database (historical data)
- Column names with "onyx" prefix
- Database schema references

**3. Internal Backend Code:**
- Class names (unless user-facing)
- Function names (unless user-facing)
- Internal variable names
- Backend module structure

### Example of What Stays vs What Changes

**File: `backend/onyx/configs/onyxbot_configs.py`**

```python
# STAYS UNCHANGED
from onyx.configs.constants import ...  # Import path

# CHANGES (env var name and value)
KNOWSEE_BOT_NUM_RETRIES = os.getenv("KNOWSEE_BOT_NUM_RETRIES", "5")

# CHANGES (user-facing display string)
BOT_DISPLAY_NAME = "Knowsee Bot"
```

**File: `web/src/app/admin/page.tsx`**

```tsx
// CHANGES (user-facing component name and display)
import { KnowseeInitializingLoader } from '@/components/KnowseeInitializingLoader';

return (
  <div>
    <h1>Welcome to Knowsee</h1>  {/* User-facing text */}
    <KnowseeInitializingLoader />
  </div>
);
```

---

## Critical Considerations & Gotchas

### 1. Service Discovery in Docker

**Issue:** Docker Compose uses service names for DNS resolution.

**Impact:** Changing `onyx-postgres` → `knowsee-postgres` means all connection strings must update.

**Files to check:**
- Environment files with database connection URLs
- Backend configuration with Redis/Postgres hosts
- docker-compose service dependencies

**Example:**
```yaml
# In docker-compose.yml
depends_on:
  - knowsee-postgres  # Must match new service name

environment:
  POSTGRES_HOST: knowsee-postgres  # Must match new service name
```

### 2. Volume Persistence

**Issue:** Renaming volumes creates new empty volumes.

**Solution:**
- Option A: Update volume names in compose and migrate data manually
- Option B: Keep volume names unchanged (just rename services/containers)
- **Recommendation:** Keep volume names to preserve data

### 3. Environment Variable Backwards Compatibility

**Issue:** Existing deployments may have `ONYX_*` env vars set.

**Solution:**
- Update config code to check both old and new names during transition
- Add deprecation warnings for old variable names

**Example:**
```python
KNOWSEE_VERSION = os.getenv("KNOWSEE_VERSION") or os.getenv("ONYX_VERSION", "unknown")
if os.getenv("ONYX_VERSION") and not os.getenv("KNOWSEE_VERSION"):
    logger.warning("ONYX_VERSION is deprecated, use KNOWSEE_VERSION")
```

### 4. Image Registry and Tags

**Issue:** If using private registry, need to push images to new repository.

**Considerations:**
- Update CI/CD to push to new registry path
- Update Kubernetes/ECS to pull from new path
- Keep old images for rollback capability

### 5. Kubernetes Label Selectors

**Issue:** Changing labels in Helm charts can orphan running pods.

**Solution:**
- Use Helm's upgrade mechanism
- Consider blue/green deployment for production
- Test in staging environment first

### 6. External Integrations

**Issue:** Webhooks, OAuth callbacks, Slack integrations may reference old names.

**Check:**
- Slack app configuration (bot name, webhooks)
- OAuth provider redirect URIs
- External monitoring/alerting (service names)
- Log aggregation (log file paths)

### 7. Case Sensitivity

**Issue:** "Onyx", "onyx", "ONYX" all appear in codebase.

**Strategy:**
- "Onyx" → "Knowsee" (title case, user-facing)
- "onyx" → "knowsee" (lowercase, technical)
- "ONYX" → "KNOWSEE" (uppercase, env vars/constants)
- Keep "onyx" in file paths (backend structure preserved)

### 8. Search and Replace Precision

**Avoid:**
- Replacing "onyx" in URLs to external sites
- Replacing in commented-out code that references upstream
- Replacing in git commit messages or changelog
- Replacing in package-lock.json or dependency names

**Use targeted find/replace:**
- Specify file patterns explicitly
- Review each change in large files
- Test after each phase of changes

---

## Risk Assessment

### Low Risk (Safe Changes)
- ✅ Documentation string replacements
- ✅ Frontend component renaming (with updated imports)
- ✅ Logo/icon file replacements
- ✅ Display string changes in UI
- ✅ CloudFormation template renaming (not yet deployed)

### Medium Risk (Test Thoroughly)
- ⚠️ Docker service name changes (affects networking)
- ⚠️ Environment variable renaming (affects configuration)
- ⚠️ Helm chart updates (affects Kubernetes deployments)
- ⚠️ GitHub workflow changes (affects CI/CD)

### High Risk (Proceed with Caution)
- 🚨 Volume naming changes (data migration)
- 🚨 Database-related changes (we're avoiding these)
- 🚨 Changes to running production systems

### Not Doing (Preserved for Safety)
- ❌ Backend Python package renaming
- ❌ Database migration file changes
- ❌ Table/column name changes
- ❌ Core import path changes

---

## Rollback Strategy

### Immediate Rollback (During Development)
```bash
# If issues discovered during implementation
git reset --hard HEAD
git clean -fd
```

### Partial Rollback (After Partial Implementation)
```bash
# Rollback specific files
git checkout HEAD -- <file_path>

# Or rollback entire phase
git checkout HEAD -- web/src/components/
```

### Docker Rollback
```bash
# Keep old images tagged
docker tag knowsee-api:latest knowsee-api:pre-rebrand
docker tag onyx-api:latest onyx-api:backup

# Rollback compose
git checkout HEAD -- deployment/docker_compose/docker-compose.yml
docker-compose up -d
```

### Production Rollback Plan
1. Keep old Helm release available
2. Maintain old CloudFormation stacks until verified
3. Keep old Docker images in registry
4. Document rollback procedure for each component

---

## Post-Implementation Checklist

### Immediate (Day 1)
- [ ] All builds successful (frontend, backend, Docker)
- [ ] Local development environment works
- [ ] Documentation updated
- [ ] README shows "Knowsee"
- [ ] GitHub repo description updated

### Short-term (Week 1)
- [ ] Staging environment deployed successfully
- [ ] All integration tests pass
- [ ] UI verified in multiple browsers
- [ ] Mobile responsive design checked
- [ ] Accessibility verified (screen readers say "Knowsee")

### Medium-term (Month 1)
- [ ] Production deployment successful
- [ ] Monitoring shows healthy services
- [ ] No "onyx" references in user-facing logs
- [ ] Analytics tracking updated brand name
- [ ] Customer documentation updated

### Long-term (Quarter 1)
- [ ] Consider setting up docs.knowsee.com
- [ ] Evaluate if deeper backend rename needed
- [ ] Review upstream merge strategy
- [ ] Update any external integrations

---

## Tools & Commands Reference

### Search for References
```bash
# Case-sensitive search for "Onyx"
grep -r "Onyx" . --exclude-dir={node_modules,.next,.git,dist,build}

# Case-insensitive search
grep -ri "onyx" . --exclude-dir={node_modules,.next,.git,dist,build}

# Search for env variables
grep -r "ONYX_" backend/ deployment/

# Search in specific file types
find . -name "*.tsx" -exec grep -l "Onyx" {} \;
find . -name "*.py" -exec grep -l "ONYX_" {} \;
```

### Bulk Renaming
```bash
# Rename files in directory
for file in web/src/icons/onyx-*.tsx; do
  mv "$file" "${file/onyx-/knowsee-}"
done

# Rename with confirmation
rename 's/onyx/knowsee/' *.yaml
```

### Find and Replace
```bash
# Using sed (macOS: install gsed)
find deployment/docker_compose -name "*.yml" -exec sed -i 's/onyx-/knowsee-/g' {} \;

# Using grep + sed for specific replacements
grep -rl "ONYX_BOT" backend/onyx/configs/ | xargs sed -i 's/ONYX_BOT/KNOWSEE_BOT/g'
```

### Verification Commands
```bash
# Check Docker services
docker-compose ps
docker-compose logs knowsee-api

# Check environment
docker-compose exec knowsee-api env | grep KNOWSEE

# Check connectivity
docker-compose exec knowsee-api ping knowsee-postgres

# Check logs
tail -f backend/log/knowsee_debug.log
```

---

## Timeline Estimate

### With Manual Review (Recommended)
- **Phase 1 (Assets):** 30 minutes
- **Phase 2 (Frontend):** 3-4 hours
- **Phase 3 (Docker):** 2-3 hours
- **Phase 4 (Environment):** 1-2 hours
- **Phase 5 (Deployment):** 4-6 hours
- **Phase 6 (Documentation):** 2-3 hours
- **Phase 7 (CI/CD):** 1-2 hours
- **Phase 8 (Bot/Integration):** 1-2 hours
- **Phase 9 (Testing):** 3-4 hours

**Total: 18-27 hours (2-3 working days)**

### With Automated Scripts (Faster but Higher Risk)
- **Script development:** 2-3 hours
- **Execution:** 30 minutes
- **Review:** 2-3 hours
- **Testing:** 3-4 hours

**Total: 8-11 hours (1-1.5 working days)**

---

## Summary Statistics

| Category | Files | Changes | Priority | Risk |
|----------|-------|---------|----------|------|
| Frontend Components | 118 | 406+ | HIGH | LOW |
| Docker/Compose | 8 | 200+ | HIGH | MEDIUM |
| Environment Configs | 15 | 150+ | HIGH | MEDIUM |
| Helm Charts | 50 | 500+ | MEDIUM | MEDIUM |
| CloudFormation | 40 | 400+ | MEDIUM | LOW |
| Documentation | 23 | 300+ | MEDIUM | LOW |
| GitHub Workflows | 18 | 100+ | MEDIUM | MEDIUM |
| Terraform | 10 | 100+ | LOW | MEDIUM |
| Bot/Integration | 15 | 80+ | MEDIUM | LOW |
| **TOTAL** | **~297** | **~2,236+** | | |

---

## Next Steps

When you're ready to execute this plan:

1. **Backup everything:**
   ```bash
   git checkout -b rebranding-knowsee
   git push origin rebranding-knowsee
   ```

2. **Copy assets:**
   - Get access to `/Users/saahil/Downloads/assets`
   - Copy to `web/public/assets/knowsee/`

3. **Start with Phase 1** (lowest risk)

4. **Test after each phase** before moving to next

5. **Commit frequently:**
   ```bash
   git add .
   git commit -m "Phase X: [description]"
   ```

6. **Create PR when complete** for final review before merging to main

---

## Questions to Confirm Before Starting

1. ✅ Assets accessible? Need to copy from `/Users/saahil/Downloads/assets`
2. ✅ Backup branch created?
3. ✅ Docker development environment running?
4. ✅ Time allocated (2-3 days)?
5. ✅ Staging environment available for testing?
6. ✅ Rollback plan understood?
7. ✅ Team notified of upcoming changes?

---

**Last Updated:** 2025-10-31
**Status:** Planning complete, awaiting execution approval
**Approach:** Badge Engineering (Hybrid)
**Estimated Effort:** 18-27 hours over 2-3 days
