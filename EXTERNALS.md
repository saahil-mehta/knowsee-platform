# EXTERNALS.md

**Purpose**: Comprehensive documentation of all external dependencies, services, and user-facing entities in the Knowsee Platform (formerly Onyx). This document helps you understand what needs to be configured, replaced, or managed when forking and customizing this codebase.

**Status**: Private fork of onyx-foss (MIT licensed)
**Last Updated**: 2025-11-03

---

## Table of Contents

1. [External SaaS & Service Dependencies](#external-saas--service-dependencies)
2. [OAuth & Authentication Providers](#oauth--authentication-providers)
3. [Data Connector Integrations (40+)](#data-connector-integrations)
4. [Docker Registry Dependencies](#docker-registry-dependencies)
5. [Frontend NPM Dependencies](#frontend-npm-dependencies)
6. [Monitoring & Analytics Services](#monitoring--analytics-services)
7. [GitHub Actions & CI/CD](#github-actions--cicd)
8. [Git Upstream Strategy](#git-upstream-strategy)
9. [User-Facing Entities & URLs](#user-facing-entities--urls)
10. [Recommendations for Your Fork](#recommendations-for-your-fork)

---

## External SaaS & Service Dependencies

### Required for Core Functionality

| Service | Purpose | Required? | Can Self-Host? | Notes |
|---------|---------|-----------|----------------|-------|
| **PostgreSQL** | Primary database | ✅ Yes | ✅ Yes | Included in docker-compose |
| **Redis** | Caching & Celery broker | ✅ Yes | ✅ Yes | Included in docker-compose |
| **Vespa** | Vector search engine | ✅ Yes | ✅ Yes | Included in docker-compose |
| **MinIO/S3** | File storage | ✅ Yes | ✅ Yes | MinIO included, or use AWS S3 |
| **OpenAI API** | LLM provider (default) | ⚠️ Conditional | ❌ No | Required for AI features, can swap providers |

### Optional External Services

| Service | Purpose | Required? | Configuration |
|---------|---------|-----------|---------------|
| **Sentry** | Error tracking | ❌ No | `SENTRY_DSN` env var |
| **PostHog** | Product analytics | ❌ No | Frontend integration available |
| **Stripe** | Payment processing | ❌ No | For paid/enterprise features |
| **Exa API** | Internet search | ❌ No | `EXA_API_KEY` env var |
| **SMTP Server** | Email notifications | ❌ No | For user invites & password reset |

**Configuration File**: `deployment/docker_compose/env.template`

---

## OAuth & Authentication Providers

### Supported Auth Backends

The platform supports multiple authentication methods:

```bash
AUTH_TYPE=disabled|basic|google_oauth|oidc|saml
```

### OAuth Provider Configuration

| Provider | Required Env Vars | Use Case |
|----------|------------------|----------|
| **Google OAuth** | `GOOGLE_OAUTH_CLIENT_ID`<br>`GOOGLE_OAUTH_CLIENT_SECRET` | User authentication |
| **Generic OIDC** | `OAUTH_CLIENT_ID`<br>`OAUTH_CLIENT_SECRET`<br>`OPENID_CONFIG_URL` | SSO integration |
| **SAML** | Configuration via UI | Enterprise SSO |

### OAuth Callback URLs

**Critical**: When rebranding, you must update OAuth callback URLs with ALL providers:

- Google OAuth Console
- Microsoft Azure AD
- Slack App Settings
- Linear OAuth Settings
- Jira OAuth Settings
- Confluence OAuth Settings
- GitHub OAuth Apps
- GitLab OAuth Apps
- Notion Integration Settings
- And 30+ other connector OAuth apps

**Default Callback Pattern**:
```
https://your-domain.com/auth/oauth/callback
https://your-domain.com/admin/connectors/[connector]/oauth/callback
https://your-domain.com/oauth-config/callback
https://your-domain.com/federated/oauth/callback
```

**Files to Review**:
- `web/src/app/auth/oauth/callback/route.ts`
- `backend/onyx/server/documents/standard_oauth.py`
- All connector files in `backend/onyx/connectors/*/connector.py`

---

## Data Connector Integrations

The platform includes **40+ pre-built connectors** to external services. Each requires API credentials and (often) OAuth configuration.

### Full Connector List

#### Document Management & Storage
- **Google Drive** (OAuth required)
- **Dropbox** (OAuth required)
- **SharePoint** (OAuth required)
- **OneDrive/Teams** (OAuth required)
- **Notion** (OAuth required)
- **Confluence** (OAuth required)
- **GitBook** (API key)
- **Document360** (API key)
- **Guru** (OAuth required)
- **Slab** (API key)

#### Project Management & Issue Tracking
- **Jira** (OAuth required)
- **Linear** (OAuth required)
- **Asana** (OAuth required)
- **ClickUp** (API key)
- **Productboard** (API key)
- **Loopio** (API key)

#### Code Repositories
- **GitHub** (OAuth required)
- **GitLab** (OAuth required)
- **Bitbucket** (OAuth required)

#### Communication & Collaboration
- **Slack** (OAuth required, Bot token)
- **Discord** (Bot token)
- **Microsoft Teams** (OAuth required)
- **Gmail** (OAuth required)
- **Zulip** (API key)

#### Sales & CRM
- **Salesforce** (OAuth required)
- **HubSpot** (OAuth required)
- **Gong** (API key)
- **Zendesk** (OAuth required)
- **Freshdesk** (API key)

#### Knowledge & Wiki
- **MediaWiki** (API endpoint)
- **Wikipedia** (Public API)
- **Outline** (API key)
- **Bookstack** (API key)

#### Other Specialized
- **Egnyte** (OAuth required)
- **Highspot** (API key)
- **Fireflies** (API key)
- **RequestTracker** (API credentials)
- **Xenforo** (API key)
- **Axero** (API credentials)
- **Airtable** (OAuth required)

#### Generic/Universal
- **Web Scraper** (URL-based, no auth)
- **File Upload** (Local files)
- **IMAP Email** (IMAP credentials)
- **Blob Storage** (S3-compatible)

### Connector Dependencies

**Each connector may require**:
1. OAuth application registration with the external service
2. API keys or tokens
3. Specific permissions/scopes
4. Callback URL configuration
5. Rate limiting considerations

**Location**: `backend/onyx/connectors/`

**Registry**: `backend/onyx/connectors/registry.py`

---

## Docker Registry Dependencies

### Current Image Registry

**Organization**: `onyxdotapp`
**Registry**: Docker Hub (`docker.io`)

**Images Published**:
```yaml
onyxdotapp/onyx-backend:latest
onyxdotapp/onyx-backend:<tag>
onyxdotapp/onyx-web-server:latest
onyxdotapp/onyx-web-server:<tag>
onyxdotapp/onyx-model-server:latest
onyxdotapp/onyx-model-server:<tag>
onyxdotapp/onyx-backend-cloud:<tag>  # Cloud-specific variant
onyxdotapp/onyx-web-server-cloud:<tag>
```

### Third-Party Images Used

```yaml
postgres:15.2-alpine
redis:7.4-alpine
vespaengine/vespa:8.526.15
minio/minio:RELEASE.2025-07-23T15-54-02Z-cpuv1
nginx:1.23.4-alpine
```

**Additional Helm Dependencies**:
```yaml
ghcr.io/cloudnative-pg/cloudnative-pg:1.27.0  # PostgreSQL operator
quay.io/opstree/redis:v7.0.15  # Redis for Helm deployments
```

### GitHub Actions Private Registry

**Note**: Integration tests use a private registry:
```
experimental-registry.blacksmith.sh:5000
```

This requires secrets:
- `PRIVATE_REGISTRY_USERNAME`
- `PRIVATE_REGISTRY_PASSWORD`

**Your fork won't have access to this registry**, so integration test workflows will fail.

---

## Frontend NPM Dependencies

### Key External Dependencies

From `web/package.json`:

#### Monitoring & Analytics
```json
"@sentry/nextjs": "^10.9.0",
"@sentry/tracing": "^7.120.3",
"posthog-js": "^1.176.0"
```

#### Payment Processing
```json
"@stripe/stripe-js": "^4.6.0",
"stripe": "^17.0.0"
```

#### UI Component Libraries (Open Source)
```json
"@headlessui/react": "^2.2.0",
"@radix-ui/*": "^1.x - ^2.x",  // 20+ Radix UI packages
"@phosphor-icons/react": "^2.0.8",
"lucide-react": "^0.454.0",
"react-icons": "^4.8.0"
```

#### Core Framework
```json
"next": "^15.5.2",
"react": "^18.3.1",
"react-dom": "^18.3.1"
```

#### Testing
```json
"@playwright/test": "^1.39.0",
"chromatic": "^11.25.2"
```

**Total Dependencies**: ~100 production packages, ~30 dev dependencies

**Package Manager**: npm (lockfile: `web/package-lock.json`)

---

## Monitoring & Analytics Services

### Sentry (Error Tracking)

**Integration**: Automatic via `@sentry/nextjs`

**Configuration**:
```bash
# Backend
SENTRY_DSN=<your-sentry-dsn>

# Frontend (build-time)
# Set in environment during build
```

**Files**:
- `web/src/instrumentation.ts` - Backend instrumentation
- `web/src/instrumentation-client.ts` - Client-side instrumentation
- `web/src/app/global-error.tsx` - Global error handler

**Status**: Optional, disabled by default

### PostHog (Product Analytics)

**Integration**: Client-side via `posthog-js`

**Files**:
- `web/src/lib/hooks/useCustomAnalyticsEnabled.ts`
- `web/src/app/providers.tsx` - PostHog provider setup
- `web/src/components/user/UserProvider.tsx`

**Status**: Optional, can be enabled via admin settings

### Custom Analytics Toggle

The platform includes a feature flag system for enabling/disabling analytics:

**Admin Setting**: Can be toggled in UI (Enterprise Edition)

---

## GitHub Actions & CI/CD

### Current Status: **MOST WORKFLOWS WILL FAIL IN YOUR FORK**

You have **24 workflow files** that were designed for the upstream Onyx repository. Here's the breakdown:

### Workflows That Will Fail

#### 1. Docker Build & Push (4 workflows)
```
docker-build-push-backend-container-on-tag.yml
docker-build-push-web-container-on-tag.yml
docker-build-push-model-server-container-on-tag.yml
docker-build-push-cloud-web-container-on-tag.yml
```

**Why**: Require Docker Hub credentials for `onyxdotapp` organization
- Need secret: `DOCKERHUB_USERNAME`
- Need secret: `DOCKERHUB_TOKEN`

**Fix**:
- Create your own Docker Hub organization
- Update `REGISTRY_IMAGE` in workflows
- Add your Docker Hub credentials to GitHub secrets

#### 2. Integration Tests
```
pr-integration-tests.yml
pr-mit-integration-tests.yml
pr-playwright-tests.yml
```

**Why**: Require multiple external service credentials:
- `OPENAI_API_KEY` - For LLM testing
- `SLACK_BOT_TOKEN` - For Slack connector tests
- `CONFLUENCE_ACCESS_TOKEN` - For Confluence tests
- `JIRA_API_TOKEN` - For Jira tests
- `PERM_SYNC_SHAREPOINT_CLIENT_ID/PRIVATE_KEY` - For SharePoint tests
- `EXA_API_KEY` - For internet search tests
- `PRIVATE_REGISTRY_USERNAME/PASSWORD` - For custom runner registry

**Fix**:
- Add your own API keys for services you want to test
- Or disable these workflows entirely
- Or mock external services

#### 3. Helm Chart Release
```
helm-chart-releases.yml
```

**Why**: Publishes to GitHub Pages at `onyx-dot-app.github.io`

**Fix**:
- Update to your GitHub organization
- Configure GitHub Pages in your fork

#### 4. Linear Integration
```
pr-linear-check.yml
```

**Why**: Checks for Linear issue references in PRs

**Fix**: Disable or update to your Linear workspace

#### 5. License Scanning
```
nightly-scan-licenses.yml
```

**Why**: May use proprietary license scanning tools

**Fix**: Review and update license scanning tool

#### 6. Sync to FOSS
```
sync_foss.yml
```

**Why**: Syncs changes to a separate FOSS repository

**Fix**: Disable this workflow (not applicable to your fork)

### Workflows That Should Work

#### Safe to Keep:
```
pr-python-checks.yml          # Linting, type checking
pr-python-tests.yml           # Unit tests (no external deps)
pr-jest-tests.yml             # Frontend unit tests
pr-quality-checks.yml         # Code quality checks
check-lazy-imports.yml        # Import validation
pr-labeler.yml                # Auto-labels PRs
nightly-close-stale-issues.yml # Issue cleanup
```

**These require NO external credentials** and should work in your fork.

### Workflow Dependencies Summary

| Workflow Type | Count | Will Fail? | Requires |
|--------------|-------|------------|----------|
| Docker Push | 4 | ✅ Yes | Docker Hub creds |
| Integration Tests | 6 | ✅ Yes | API keys + registry access |
| Helm/K8s | 2 | ✅ Yes | GitHub Pages, K8s cluster |
| Code Quality | 6 | ❌ No | None |
| Automation | 4 | ⚠️ Maybe | Depends on config |

### Recommendation

**Short-term**:
1. Disable all failing workflows
2. Keep code quality checks running
3. Run integration tests locally when needed

**Long-term**:
1. Set up your own Docker Hub organization
2. Create your own test API keys
3. Gradually re-enable workflows with your credentials

**Quick Fix**:
```bash
# Disable all workflows temporarily
mkdir .github/workflows-disabled
mv .github/workflows/*.yml .github/workflows-disabled/
# Move back only the ones you want
mv .github/workflows-disabled/pr-python-checks.yml .github/workflows/
mv .github/workflows-disabled/pr-python-tests.yml .github/workflows/
```

---

## Git Upstream Strategy

### Current Configuration

```bash
$ git remote -v
onyx-upstream  https://github.com/onyx-dot-app/onyx-foss.git (fetch)
onyx-upstream  https://github.com/onyx-dot-app/onyx-foss.git (push)
origin         https://github.com/saahil-mehta/knowsee-platform.git (fetch)
origin         https://github.com/saahil-mehta/knowsee-platform.git (push)
```

### Branch Structure

```
Your Fork (origin):
  - main (diverged from upstream)
  - refact-foss (current branch, ahead of main)

Upstream (onyx-upstream):
  - main (original Onyx FOSS)
```

### The Upstream Dilemma

**You asked**: "Should I be doing a rebase or a sync or something?"

**Answer**: **It depends on your rebranding strategy.**

#### Option 1: Full Fork (Recommended for Rebrand)
**When**: You're rebranding to "Knowsee" and want independence

**Strategy**:
1. **Do NOT sync with upstream** after rebranding
2. Keep `onyx-upstream` remote for **reference only**
3. Accept that you're maintaining an independent fork

**Why**:
- After rebranding (onyx → knowsee), merge conflicts will be **massive**
- Every file you rename creates conflicts
- Upstream changes won't apply cleanly
- You'd spend more time resolving conflicts than benefiting from updates

**How to check upstream changes**:
```bash
# View what's new upstream (but don't merge)
git fetch onyx-upstream
git log onyx-upstream/main ^main --oneline

# Cherry-pick specific commits if needed
git cherry-pick <commit-hash>

# Or manually port features you want
```

#### Option 2: Stay Synchronized (Not Recommended After Rebrand)
**When**: You want to stay close to upstream Onyx

**Strategy**:
1. Keep "onyx" naming throughout
2. Regular rebases: `git pull --rebase onyx-upstream main`
3. Minimize custom changes

**Why NOT recommended**:
- You're already rebranding
- You have custom infrastructure (Terraform, configs)
- You'll want to diverge further

#### Option 3: Hybrid (Complex but Flexible)
**When**: You want occasional upstream features

**Strategy**:
1. Maintain TWO branches:
   - `knowsee-main` - Your rebrand, no upstream syncs
   - `onyx-tracking` - Mirror of upstream, no customizations
2. Manually port features between branches as needed

**Workflow**:
```bash
# Update tracking branch
git checkout onyx-tracking
git pull onyx-upstream main

# Port specific features to your branch
git checkout knowsee-main
git cherry-pick <specific-commit-from-onyx-tracking>
```

### Recommended Approach for You

**Since you're rebranding to Knowsee:**

1. **Keep the upstream remote** for reference:
   ```bash
   git remote rename onyx-upstream upstream-reference
   ```

2. **Treat it as read-only**:
   - Check what features they're adding
   - Manually implement features you want
   - Don't attempt automatic merges

3. **Track interesting changes**:
   ```bash
   # Get notified of upstream releases
   # Watch the repo on GitHub (upstream)

   # Periodically review what's new
   git fetch upstream-reference
   git log upstream-reference/main --since="1 month ago" --oneline
   ```

4. **Cherry-pick carefully**:
   ```bash
   # For bug fixes in untouched code:
   git cherry-pick <commit> --strategy=recursive -X theirs
   ```

### What NOT to Do

❌ **Don't run**: `git merge onyx-upstream/main` after rebranding
❌ **Don't run**: `git pull onyx-upstream main` after rebranding
❌ **Don't try**: Automatic rebases with renamed files/folders

**These will create 1000+ conflicts and waste days of your time.**

### When Upstream is Useful

✅ Bug fixes in isolated modules
✅ New connector implementations
✅ Security patches
✅ Database migration scripts (review carefully)
✅ New features in independent modules

Copy these **manually** rather than merging.

---

## User-Facing Entities & URLs

### External URLs Referenced in Code

**These URLs are hardcoded and reference the original Onyx brand:**

```python
# backend/onyx/configs/constants.py
ONYX_DISCORD_URL = "https://discord.gg/4NA5SbzrWb"
NO_AUTH_USER_EMAIL = "anonymous@onyx.app"

# Documentation references in code/comments:
"https://docs.onyx.app/"
"https://www.onyx.app/"
"https://cloud.onyx.app/"
```

**After rebranding, you'll need:**
- Your own domain (e.g., `knowsee.app`)
- Your own documentation site
- Your own Discord/support channels
- Update all email addresses

### Environment Variables with URLs

```bash
# deployment/docker_compose/env.template
WEB_DOMAIN=http://localhost:3000  # Update for production
DOMAIN=localhost  # Nginx configuration

# OAuth callback base
# Used to construct: ${WEB_DOMAIN}/auth/oauth/callback
```

### Cookie/Session Identifiers

```python
# backend/onyx/configs/constants.py
TENANT_ID_COOKIE_NAME = "onyx_tid"
ANONYMOUS_USER_COOKIE_NAME = "onyx_anonymous_user"
```

**Impact**: All users will be logged out when you rename these

### Metadata Files

```python
ONYX_METADATA_FILENAME = ".onyx_metadata.json"
```

**Impact**: File connector won't find existing metadata files

---

## Recommendations for Your Fork

### Immediate Actions (Before Heavy Development)

1. **Disable Failing CI/CD Workflows**
   - Move non-working workflows to a disabled folder
   - Keep only: python-checks, python-tests, jest-tests

2. **Set Up Your Own Docker Registry**
   - Create Docker Hub account/org: `knowseedotapp`
   - Update all docker-compose files
   - Set up GitHub secrets for automated builds

3. **Document Required API Keys**
   - Create a private `.env.local` file
   - List which connectors you actually need
   - Obtain API keys only for those services

4. **Review Upstream Strategy**
   - Keep remote for reference
   - Don't attempt automatic merges after rebrand
   - Cherry-pick specific commits as needed

5. **Plan OAuth Callback Updates**
   - List all OAuth providers you'll use
   - Prepare to update callback URLs after deployment
   - Consider keeping a compatibility layer temporarily

### Security & Privacy Considerations

1. **Remove Upstream Tracking** (Optional but recommended):
   ```bash
   # If you want complete independence:
   git remote remove onyx-upstream
   ```

2. **Audit Analytics/Monitoring**:
   - Sentry: Disabled by default ✅
   - PostHog: Disabled by default ✅
   - Check no data is sent to Onyx servers ✅

3. **API Key Management**:
   - Never commit `.env` files
   - Use GitHub Secrets for CI/CD
   - Use environment variable injection for production

4. **License Compliance**:
   - Onyx is MIT licensed ✅
   - Keep LICENSE file
   - Attribute original authors
   - Your custom code is yours

### Connector Strategy

**Don't set up all 40+ connectors!**

**Recommended approach**:
1. Identify your top 5-10 required integrations
2. Set up OAuth apps only for those
3. Leave other connectors unconfigured
4. Add more as needed

**Common starting set**:
- Google Drive (document storage)
- Slack (internal comms)
- Confluence/Notion (knowledge base)
- GitHub (code/issues)
- Jira/Linear (project management)

### Development Workflow

1. **Local Development**: Works perfectly as-is
   ```bash
   # All services run locally via docker-compose
   docker compose up
   ```

2. **Testing**: Run manually or locally
   ```bash
   # Unit tests (work without external services)
   pytest backend/tests/unit

   # Integration tests (need API keys)
   pytest backend/tests/integration
   ```

3. **Deployment**:
   - Self-hosted: Full control, no external dependencies
   - Cloud: Requires setting up all credentials

### Cost Considerations

**Free/Self-Hosted**:
- PostgreSQL, Redis, Vespa, MinIO: $0 (self-hosted)
- Basic auth: $0
- Local LLM models: $0 (if you run them)

**Paid/External**:
- OpenAI API: ~$0.002-$0.10 per request
- Cloud hosting: $50-500+/month (depends on scale)
- Managed Postgres: $20-200/month
- OAuth provider enterprise plans: Varies
- Sentry: $26+/month
- PostHog: $0-450+/month

**Recommendation**: Start self-hosted, add paid services as you scale.

---

## Quick Reference: What Works Out of the Box

✅ **Fully Self-Contained** (No external deps):
- Core application
- Basic auth (email/password)
- File upload connector
- Web scraper connector
- Local LLM model server

❌ **Requires External Setup**:
- All OAuth-based connectors (40+)
- OpenAI/Anthropic API (for good LLM performance)
- Production OAuth authentication
- Email notifications (SMTP)
- Docker image builds (CI/CD)

⚠️ **Optional External Services**:
- Sentry (error tracking)
- PostHog (analytics)
- Stripe (payments)
- Exa (internet search)

---

## Summary: Your Independence Level

**High Independence** ✅:
- MIT license allows full customization
- Can self-host everything
- No vendor lock-in
- Can rebrand completely

**Moderate Coupling** ⚠️:
- Docker images reference upstream registry
- 40+ connectors need external OAuth setup
- Some workflows assume Onyx infrastructure
- LLM APIs (OpenAI/etc) are external

**Low Coupling** ✅:
- No telemetry to Onyx servers
- No license callbacks
- No proprietary protocols
- Open source everything

**Your mission**: Replace the "Moderate Coupling" items with your own infrastructure, and you'll have a fully independent platform.

---

## Next Steps

1. **Read this document thoroughly** ✅
2. **Audit workflows**: Disable failing ones
3. **Set up Docker registry**: Create your org
4. **Plan OAuth providers**: List top 5-10 connectors needed
5. **Document your API keys**: Create `.env.local` template
6. **Decide on upstream**: Keep for reference, don't auto-merge
7. **Test locally**: Ensure `docker compose up` works
8. **Plan deployment**: Cloud vs self-hosted
9. **Review rebrand plan**: Your existing `REBRANDING_PLAN_COMPREHENSIVE.md`
10. **Start building**: You're ready!

---

## Getting Help

**Original Onyx Resources** (for technical reference):
- Docs: https://docs.onyx.app/
- GitHub: https://github.com/onyx-dot-app/onyx-foss
- Discord: https://discord.gg/4NA5SbzrWb

**For Your Fork**:
- Create your own docs site
- Set up your own support channels
- Build your own community

**Remember**: You're building **Knowsee**, not Onyx. The codebase is just your starting point. 🚀

---

**Document Version**: 1.0
**Maintainer**: Your team
**License**: MIT (inherited from Onyx)
