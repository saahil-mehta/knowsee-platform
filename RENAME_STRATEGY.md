# Intelligent Rename Strategy: Onyx → Knowsee

**Purpose**: Smart, selective renaming of user-facing and developer-facing elements while avoiding unnecessary changes that break functionality.

**Principle**: Only rename what **users and developers actually see**. Keep internal implementation details unchanged where it doesn't matter.

**Last Updated**: 2025-11-03

---

## Table of Contents

1. [Renaming Categories](#renaming-categories)
2. [Priority 1: User-Facing (MUST RENAME)](#priority-1-user-facing-must-rename)
3. [Priority 2: Developer-Facing (SHOULD RENAME)](#priority-2-developer-facing-should-rename)
4. [Priority 3: Internal (DON'T RENAME)](#priority-3-internal-dont-rename)
5. [Documentation Link Strategy](#documentation-link-strategy)
6. [Execution Plan](#execution-plan)
7. [Testing Checklist](#testing-checklist)

---

## Renaming Categories

### Decision Matrix

```
┌─────────────────────────┬──────────────┬────────────┬───────────────┐
│ Element Type            │ User Sees?   │ Dev Sees?  │ Action        │
├─────────────────────────┼──────────────┼────────────┼───────────────┤
│ UI Text/Labels          │ ✅ Yes       │ ❌ No      │ MUST RENAME   │
│ Error Messages          │ ✅ Yes       │ ❌ No      │ MUST RENAME   │
│ Email Templates         │ ✅ Yes       │ ❌ No      │ MUST RENAME   │
│ Welcome Screens         │ ✅ Yes       │ ❌ No      │ MUST RENAME   │
│ Browser Page Titles     │ ✅ Yes       │ ❌ No      │ MUST RENAME   │
│ Cookie Names (visible)  │ ✅ Yes       │ ⚠️  Maybe  │ MUST RENAME   │
│ Docker Image Names      │ ⚠️  Maybe    │ ✅ Yes     │ SHOULD RENAME │
│ Env Variable Names      │ ❌ No        │ ✅ Yes     │ SHOULD RENAME │
│ Component Names (TSX)   │ ❌ No        │ ✅ Yes     │ SHOULD RENAME │
│ API Endpoint Paths      │ ❌ No        │ ✅ Yes     │ SHOULD RENAME │
│ Config File Names       │ ❌ No        │ ✅ Yes     │ SHOULD RENAME │
│ Database Table Names    │ ❌ No        │ ❌ No      │ DON'T RENAME  │
│ Internal Function Names │ ❌ No        │ ❌ No      │ DON'T RENAME  │
│ Internal Class Names    │ ❌ No        │ ❌ No      │ DON'T RENAME  │
│ Git History             │ ❌ No        │ ❌ No      │ DON'T RENAME  │
└─────────────────────────┴──────────────┴────────────┴───────────────┘
```

---

## Priority 1: User-Facing (MUST RENAME)

These are **visible to end users** in the UI, emails, or browser. Renaming is critical.

### 1.1 UI Text & Welcome Messages

| File | Line | Current Text | New Text |
|------|------|--------------|----------|
| `web/src/components/initialSetup/welcome/WelcomeModal.tsx` | 65 | `"Welcome to Onyx!"` | `"Welcome to Knowsee!"` |
| `web/src/components/initialSetup/welcome/WelcomeModal.tsx` | 70 | `"Onyx brings all your company's knowledge..."` | `"Knowsee brings all your company's knowledge..."` |
| `web/src/components/initialSetup/welcome/WelcomeModal.tsx` | 75 | `"This key allows Onyx to interact..."` | `"This key allows Knowsee to interact..."` |
| `web/src/components/OnyxInitializingLoader.tsx` | 12 | `"Initializing Onyx"` | `"Initializing Knowsee"` |
| `web/src/components/modals/NewTeamModal.tsx` | 182 | `"Try Onyx while waiting"` | `"Try Knowsee while waiting"` |
| `web/src/components/FederatedOAuthModal.tsx` | 147 | `application_name \|\| "Onyx"` | `application_name \|\| "Knowsee"` |

**Action**:
```bash
# Regex replace in frontend
find web/src/components -type f -name "*.tsx" -o -name "*.ts" | \
  xargs sed -i '' 's/Welcome to Onyx/Welcome to Knowsee/g'

find web/src/components -type f -name "*.tsx" -o -name "*.ts" | \
  xargs sed -i '' 's/Onyx brings/Knowsee brings/g'

# etc.
```

### 1.2 Error & Info Messages

| File | Line | Current Message | New Message |
|------|------|-----------------|-------------|
| `backend/onyx/configs/constants.py` | 46 | `"Your System Admin has disabled the Generative AI functionalities of Onyx."` | `"Your System Admin has disabled the Generative AI functionalities of Knowsee."` |
| `backend/onyx/configs/constants.py` | 48 | `"You can still use Onyx as a search engine."` | `"You can still use Knowsee as a search engine."` |
| `web/src/components/errorPages/ErrorPage.tsx` | 14 | `"problem loading your Onyx settings"` | `"problem loading your Knowsee settings"` |
| `web/src/components/errorPages/CloudErrorPage.tsx` | 10 | `"Onyx is currently in a maintenance window"` | `"Knowsee is currently in a maintenance window"` |
| `web/src/components/errorPages/AccessRestrictedPage.tsx` | 95 | `"your access to Onyx has been temporarily"` | `"your access to Knowsee has been temporarily"` |
| `web/src/components/errorPages/AccessRestrictedPage.tsx` | 100 | `"continue benefiting from Onyx's"` | `"continue benefiting from Knowsee's"` |

**Action**:
```python
# In backend/onyx/configs/constants.py
DISABLED_GEN_AI_MSG = (
    "Your System Admin has disabled the Generative AI functionalities of Knowsee.\n"
    "Please contact them if you wish to have this enabled.\n"
    "You can still use Knowsee as a search engine."
)

KNOWSEE_DEFAULT_APPLICATION_NAME = "Knowsee"
```

### 1.3 Access Control Messages

| File | Line | Current Text | New Text |
|------|------|--------------|----------|
| `web/src/components/admin/connectors/AccessTypeForm.tsx` | 81 | `"Everyone with an account on Onyx can access..."` | `"Everyone with an account on Knowsee can access..."` |
| `web/src/components/admin/connectors/AccessTypeForm.tsx` | 92 | `"searchable in Onyx if and only if"` | `"searchable in Knowsee if and only if"` |

### 1.4 Role Descriptions

| File | Line | Current Text | New Text |
|------|------|--------------|----------|
| `web/src/lib/types.ts` | 68 | `"users who only use Onyx via Slack"` | `"users who only use Knowsee via Slack"` |

### 1.5 Default Application Name

| File | Line | Current Constant | New Constant |
|------|------|-----------------|--------------|
| `backend/onyx/configs/constants.py` | 8 | `ONYX_DEFAULT_APPLICATION_NAME = "Onyx"` | `KNOWSEE_DEFAULT_APPLICATION_NAME = "Knowsee"` |

**Impact**: This constant is used throughout the UI as a fallback when no custom application name is set.

### 1.6 Browser Cookie Names (User-Visible in DevTools)

| File | Line | Current Name | New Name | Rename? |
|------|------|--------------|----------|---------|
| `backend/onyx/configs/constants.py` | 29 | `TENANT_ID_COOKIE_NAME = "onyx_tid"` | `"knowsee_tid"` | ✅ Yes |
| `backend/onyx/configs/constants.py` | 30 | `ANONYMOUS_USER_COOKIE_NAME = "onyx_anonymous_user"` | `"knowsee_anonymous_user"` | ✅ Yes |
| `web/src/lib/constants.ts` | 19 | `export const TENANT_ID_COOKIE_NAME = "onyx_tid"` | `"knowsee_tid"` | ✅ Yes |

**Warning**: ⚠️ **This will log out all existing users!**

**Migration Strategy**:
```python
# backend/onyx/auth/cookies.py
def get_tenant_id_from_cookie(request):
    # Try new cookie first
    tenant_id = request.cookies.get("knowsee_tid")
    if tenant_id:
        return tenant_id

    # Fall back to old cookie (backward compatibility)
    tenant_id = request.cookies.get("onyx_tid")
    if tenant_id:
        # Migrate: set new cookie and return
        response.set_cookie("knowsee_tid", tenant_id)
        return tenant_id

    return None
```

**Keep dual-read for 1-2 months**, then remove old cookie support.

### 1.7 Email Addresses

| File | Line | Current Email | New Email |
|------|------|--------------|-----------|
| `backend/onyx/configs/constants.py` | 33 | `NO_AUTH_USER_EMAIL = "anonymous@onyx.app"` | `"anonymous@knowsee.app"` |
| `web/src/components/health/refreshUtils.ts` | 35 | `email: "email@onyx.app"` | `"email@knowsee.app"` |

**Action**: Update after you own `knowsee.app` domain.

### 1.8 Metadata File Names (User Creates These)

| File | Line | Current Name | New Name |
|------|------|--------------|----------|
| `backend/onyx/configs/constants.py` | 42 | `ONYX_METADATA_FILENAME = ".onyx_metadata.json"` | `KNOWSEE_METADATA_FILENAME = ".knowsee_metadata.json"` |

**Impact**: Users who upload files with metadata need to rename their files.

**Migration Strategy**:
```python
# backend/onyx/connectors/file/connector.py
def get_metadata_filename(dir_path):
    # Try new name first
    new_path = os.path.join(dir_path, KNOWSEE_METADATA_FILENAME)
    if os.path.exists(new_path):
        return new_path

    # Fall back to old name
    old_path = os.path.join(dir_path, ONYX_METADATA_FILENAME)
    if os.path.exists(old_path):
        logger.warning(f"Found old metadata file: {old_path}. Consider renaming to {new_path}")
        return old_path

    return None
```

### 1.9 LocalStorage Keys (Visible in Browser DevTools)

| File | Line | Current Key | New Key |
|------|------|-------------|---------|
| `web/src/components/sidebar/ChatSessionMorePopup.tsx` | 32 | `"onyx:hideMoveCustomAgentModal"` | `"knowsee:hideMoveCustomAgentModal"` |

**Search for all localStorage keys**:
```bash
grep -r 'localStorage\|useLocalStorageState' web/src --include="*.ts" --include="*.tsx" | \
  grep -i onyx
```

---

## Priority 2: Developer-Facing (SHOULD RENAME)

These are **visible to developers** setting up or maintaining the application. Rename for consistency.

### 2.1 Docker Image Names

| Current Image | New Image | Who Sees It? |
|--------------|-----------|--------------|
| `onyxdotapp/onyx-backend` | `knowseedotapp/knowsee-backend` | ✅ Developers, DevOps |
| `onyxdotapp/onyx-web-server` | `knowseedotapp/knowsee-web-server` | ✅ Developers, DevOps |
| `onyxdotapp/onyx-model-server` | `knowseedotapp/knowsee-model-server` | ✅ Developers, DevOps |
| `onyxdotapp/onyx-backend-cloud` | `knowseedotapp/knowsee-backend-cloud` | ✅ Developers, DevOps |

**Files to Update**:
- `deployment/docker_compose/docker-compose*.yml` (all variants)
- `.github/workflows/docker-build-push-*.yml` (all 4 workflows)
- `deployment/helm/charts/onyx/values.yaml`

**Action**:
```bash
find deployment -type f \( -name "*.yml" -o -name "*.yaml" \) -exec \
  sed -i '' 's/onyxdotapp\/onyx-/knowseedotapp\/knowsee-/g' {} +
```

### 2.2 Docker Compose Project Name

| File | Line | Current | New |
|------|------|---------|-----|
| `deployment/docker_compose/docker-compose.yml` | 37 | `name: onyx` | `name: knowsee` |

**Impact**: Changes container names from `onyx-api_server-1` to `knowsee-api_server-1`.

**Developer Impact**:
- Existing containers need to be removed and recreated
- Any scripts referencing container names break

**Migration**:
```bash
# Stop old containers
docker compose -p onyx down

# Start with new name
docker compose -p knowsee up -d
```

### 2.3 Environment Variables

**All `ONYX_*` prefixed variables should become `KNOWSEE_*`:**

| Current Variable | New Variable | Files |
|-----------------|--------------|-------|
| `ONYX_BOT_NUM_RETRIES` | `KNOWSEE_BOT_NUM_RETRIES` | `backend/onyx/configs/onyxbot_configs.py` |
| `ONYX_BOT_NUM_DOCS_TO_DISPLAY` | `KNOWSEE_BOT_NUM_DOCS_TO_DISPLAY` | Same |
| `ONYX_BOT_DISABLE_DOCS_ONLY_ANSWER` | `KNOWSEE_BOT_DISABLE_DOCS_ONLY_ANSWER` | Same |
| `ONYX_BOT_REACT_EMOJI` | `KNOWSEE_BOT_REACT_EMOJI` | Same |
| `ONYX_BOT_FOLLOWUP_EMOJI` | `KNOWSEE_BOT_FOLLOWUP_EMOJI` | Same |
| `ONYX_BOT_FEEDBACK_VISIBILITY` | `KNOWSEE_BOT_FEEDBACK_VISIBILITY` | Same |
| `ONYX_BOT_DISPLAY_ERROR_MSGS` | `KNOWSEE_BOT_DISPLAY_ERROR_MSGS` | Same |
| `ONYX_BOT_RESPOND_EVERY_CHANNEL` | `KNOWSEE_BOT_RESPOND_EVERY_CHANNEL` | Same |
| `ONYX_BOT_MAX_QPM` | `KNOWSEE_BOT_MAX_QPM` | Same |
| `ONYX_BOT_MAX_WAIT_TIME` | `KNOWSEE_BOT_MAX_WAIT_TIME` | Same |
| `ONYX_BOT_FEEDBACK_REMINDER` | `KNOWSEE_BOT_FEEDBACK_REMINDER` | Same |
| `ONYX_BOT_REPHRASE_MESSAGE` | `KNOWSEE_BOT_REPHRASE_MESSAGE` | Same |
| `ONYX_QUERY_HISTORY_TYPE` | `KNOWSEE_QUERY_HISTORY_TYPE` | `backend/onyx/configs/app_configs.py` |

**Total**: ~20 environment variables

**Migration Strategy**: Support both old and new names temporarily:
```python
# backend/onyx/configs/onyxbot_configs.py
KNOWSEE_BOT_NUM_RETRIES = int(
    os.environ.get("KNOWSEE_BOT_NUM_RETRIES") or
    os.environ.get("ONYX_BOT_NUM_RETRIES") or  # Backward compat
    "5"
)
```

**Deprecation**: Add warning logs for old env vars:
```python
if os.environ.get("ONYX_BOT_NUM_RETRIES"):
    logger.warning(
        "ONYX_BOT_NUM_RETRIES is deprecated. Use KNOWSEE_BOT_NUM_RETRIES instead."
    )
```

### 2.4 React Component Names

| Current Component | New Component | File |
|------------------|---------------|------|
| `OnyxIcon` | `KnowseeIcon` | `web/src/components/icons/icons.tsx` |
| `OnyxLogoTypeIcon` | `KnowseeLogoTypeIcon` | Same |
| `OnyxSparkleIcon` | `KnowseeSparkleIcon` | Same |
| `OnyxInitializingLoader` | `KnowseeInitializingLoader` | `web/src/components/OnyxInitializingLoader.tsx` |
| `OnyxDocument` (TypeScript interface) | `KnowseeDocument` | `web/src/lib/search/interfaces.ts` |
| `MinimalOnyxDocument` | `MinimalKnowseeDocument` | Same |
| `SearchOnyxDocument` | `SearchKnowseeDocument` | Same |
| `LoadedOnyxDocument` | `LoadedKnowseeDocument` | Same |
| `FilteredOnyxDocument` | `FilteredKnowseeDocument` | Same |

**Impact**: These are **developer-facing** TypeScript/React names. Users never see them.

**Action**:
```bash
# Rename component files
mv web/src/components/OnyxInitializingLoader.tsx \
   web/src/components/KnowseeInitializingLoader.tsx

# Rename SVG icon files
mv web/src/icons/onyx-logo.tsx web/src/icons/knowsee-logo.tsx
mv web/src/icons/onyx-octagon.tsx web/src/icons/knowsee-octagon.tsx

# Replace component names in code
find web/src -type f \( -name "*.tsx" -o -name "*.ts" \) -exec \
  sed -i '' 's/OnyxIcon/KnowseeIcon/g' {} +

find web/src -type f \( -name "*.tsx" -o -name "*.ts" \) -exec \
  sed -i '' 's/OnyxDocument/KnowseeDocument/g' {} +
```

### 2.5 API Endpoint Paths

| File | Line | Current Path | New Path |
|------|------|-------------|----------|
| `backend/onyx/server/onyx_api/ingestion.py` | 40 | `router = APIRouter(prefix="/onyx-api")` | `prefix="/knowsee-api"` |

**Impact**: **ALL API clients break!**

**Migration Strategy**:
1. Support both paths temporarily:
   ```python
   # backend/onyx/main.py
   app.include_router(ingestion_router, prefix="/knowsee-api")  # New
   app.include_router(ingestion_router, prefix="/onyx-api")     # Old (deprecated)
   ```

2. Add deprecation warnings in old endpoints:
   ```python
   @router.get("/onyx-api/doc/update")
   async def old_endpoint():
       logger.warning("Using deprecated /onyx-api path. Use /knowsee-api instead.")
       # ... existing logic
   ```

3. After 2-3 months, remove old paths.

### 2.6 Config File Names

| Current File | New File | Rename? |
|-------------|----------|---------|
| `backend/onyx/configs/onyxbot_configs.py` | `knowseebot_configs.py` | ✅ Yes |
| `backend/onyx/onyxbot/` (directory) | `backend/onyx/knowseebot/` | ✅ Yes |

**Action**:
```bash
mv backend/onyx/configs/onyxbot_configs.py \
   backend/onyx/configs/knowseebot_configs.py

mv backend/onyx/onyxbot backend/onyx/knowseebot

# Update all imports
find backend -type f -name "*.py" -exec \
  sed -i '' 's/from onyx.configs.onyxbot_configs/from onyx.configs.knowseebot_configs/g' {} +

find backend -type f -name "*.py" -exec \
  sed -i '' 's/from onyx.onyxbot/from onyx.knowseebot/g' {} +
```

### 2.7 Helm Chart Names

| Current | New |
|---------|-----|
| `deployment/helm/charts/onyx/` | `deployment/helm/charts/knowsee/` |
| `Chart.yaml: name: onyx` | `name: knowsee` |

**Impact**: Can't upgrade existing Helm releases, must redeploy.

---

## Priority 3: Internal (DON'T RENAME)

These are **internal implementation details**. Renaming adds no value and increases migration complexity.

### 3.1 Database Table Names & Columns

**DON'T RENAME**:
- Table: `chat_session.onyxbot_flow` column
- Any other database column with "onyx" in the name

**Why Not**:
- Requires Alembic migration
- Can break existing deployments during upgrade
- No user/developer sees these names
- High risk, zero benefit

**Exception**: If you're doing a full rebrand and want 100% consistency, create migration:
```python
# alembic/versions/xxx_rebrand_onyxbot_column.py
def upgrade():
    op.alter_column("chat_session", "onyxbot_flow", new_column_name="knowseebot_flow")

def downgrade():
    op.alter_column("chat_session", "knowseebot_flow", new_column_name="onyxbot_flow")
```

### 3.2 Internal Python Class Names

**DON'T RENAME** (unless they're exported in public APIs):
- `class OnyxCeleryQueues` (internal constant)
- `class OnyxRedisLocks` (internal constant)
- `class OnyxRedisSignals` (internal constant)
- `class OnyxRedisConstants` (internal constant)
- `class OnyxCeleryPriority` (internal enum)
- `class OnyxCeleryTask` (internal constant)

**Why Not**:
- These are internal implementation details
- No developer interacts with these directly
- Changes add no value

### 3.3 Internal Function Names

**DON'T RENAME**:
- Any function named `setup_onyx()`, `mark_onyx_flag()`, etc.
- Unless the function name appears in logs/errors shown to users

**Why Not**: Internal only, no external visibility.

### 3.4 Git History & Remote Names

**DON'T RENAME**:
- Git commit messages mentioning "Onyx"
- Git remote name: `onyx-upstream`
- `.git/refs/remotes/onyx-upstream/`

**Why Not**:
- Git history is immutable (and should stay that way)
- Changing remote name doesn't help (remote URL still references onyx)
- Just adds confusion

**Acceptable**:
```bash
# Rename remote for clarity (optional)
git remote rename onyx-upstream upstream-reference
```

### 3.5 Upstream Documentation URLs

**DON'T RENAME** (but handle broken links smartly, see next section):
- References to `https://docs.onyx.app/` in code comments
- References to `https://github.com/onyx-dot-app/onyx-foss`

**Why Not**: These URLs are **external**, you don't control them.

**Handle Broken Links**: See next section.

---

## Documentation Link Strategy

### The Problem

Your code has **100+ references** to Onyx documentation:
```typescript
docs: "https://docs.onyx.app/admin/connectors/official/slack"
docsLink: "https://docs.onyx.app/admin/advanced_configs/search_configs"
explanationLink: "https://docs.onyx.app/admin/agents/overview"
```

**If you replace these with `docs.knowsee.app`, links will be broken** (you don't have those docs yet).

### Smart Strategy

#### Option 1: Keep Links, Add Disclaimer (Quickest)

**Keep all `docs.onyx.app` links unchanged**, but add a UI banner:

```typescript
// web/src/components/admin/DocLinkWarning.tsx
export function DocLinkWarning() {
  return (
    <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
      <div className="flex">
        <div className="ml-3">
          <p className="text-sm text-yellow-700">
            <strong>Note:</strong> Documentation links reference the original Onyx project.
            Most concepts apply to Knowsee, but some specifics may differ.
            {' '}
            <a href="/docs" className="underline">View Knowsee-specific docs</a>
          </p>
        </div>
      </div>
    </div>
  );
}
```

**Show this banner** on any page with external doc links.

#### Option 2: Proxy Links Through Your Domain (Medium Effort)

Create a **redirect proxy** that rewrites Onyx URLs:

```typescript
// web/src/lib/sources.ts
const DOC_BASE = "https://knowsee.app/external-docs"

docs: `${DOC_BASE}/admin/connectors/official/slack`
// Actual URL: https://knowsee.app/external-docs/admin/connectors/official/slack
```

**Backend Proxy**:
```python
# backend/onyx/server/external_docs.py
@router.get("/external-docs/{path:path}")
async def proxy_docs(path: str):
    # Fetch from upstream Onyx docs
    upstream_url = f"https://docs.onyx.app/{path}"
    response = requests.get(upstream_url)

    # Inject banner into HTML
    html = response.text
    html = html.replace(
        "<body>",
        "<body><div class='knowsee-banner'>You're viewing Onyx docs. <a href='/docs'>View Knowsee docs</a></div>"
    )

    return HTMLResponse(html)
```

**Benefits**:
- ✅ You control the links
- ✅ Can inject warnings/branding
- ✅ Can gradually replace with your own docs
- ⚠️ Medium maintenance overhead

#### Option 3: Create Your Own Docs (High Effort)

1. **Clone Onyx docs** (if open source)
2. **Rebrand to Knowsee**
3. **Host at `docs.knowsee.app`**
4. **Update all links** in code

**Timeline**: 2-4 weeks of work

**Benefits**:
- ✅ Full control
- ✅ No broken links
- ✅ Professional appearance

#### Recommended: **Start with Option 1, move to Option 3 over time**

---

## Execution Plan

### Phase 1: User-Facing Renames (Week 1)

**Goal**: Change what users see immediately

```bash
# 1. UI text and messages
find web/src/components -type f \( -name "*.tsx" -o -name "*.ts" \) | \
  xargs sed -i '' 's/Welcome to Onyx/Welcome to Knowsee/g'

find web/src/components -type f \( -name "*.tsx" -o -name "*.ts" \) | \
  xargs sed -i '' 's/Onyx brings/Knowsee brings/g'

# ... repeat for all Priority 1 items

# 2. Backend constants
# Manually edit: backend/onyx/configs/constants.py
# - ONYX_DEFAULT_APPLICATION_NAME → KNOWSEE_DEFAULT_APPLICATION_NAME
# - Update DISABLED_GEN_AI_MSG
# - Update NO_AUTH_USER_EMAIL (after owning knowsee.app domain)

# 3. Test in browser
npm run dev
# Check welcome screen, error messages, etc.
```

### Phase 2: Developer-Facing Renames (Week 2)

**Goal**: Update what developers see

```bash
# 1. Docker image names
find deployment -type f \( -name "*.yml" -o -name "*.yaml" \) -exec \
  sed -i '' 's/onyxdotapp\/onyx-/knowseedotapp\/knowsee-/g' {} +

# 2. Docker compose project name
sed -i '' 's/^name: onyx$/name: knowsee/' \
  deployment/docker_compose/docker-compose.yml

# 3. Environment variables
# Manually edit: backend/onyx/configs/onyxbot_configs.py
# Add backward compatibility for ONYX_* → KNOWSEE_*

# 4. React component renames
mv web/src/components/OnyxInitializingLoader.tsx \
   web/src/components/KnowseeInitializingLoader.tsx

find web/src -type f \( -name "*.tsx" -o -name "*.ts" \) -exec \
  sed -i '' 's/OnyxIcon/KnowseeIcon/g' {} +

# 5. Rebuild and test
docker compose -p knowsee build
docker compose -p knowsee up -d
```

### Phase 3: Cookie & Storage Migration (Week 3)

**Goal**: Migrate browser storage without logging users out

```python
# Implement dual-read for cookies
# See section 1.6 above

# Deploy to staging
# Test cookie migration
# Monitor for issues
# Deploy to production
```

### Phase 4: API Endpoint Migration (Week 4)

**Goal**: Support both old and new API paths

```python
# Add both routes in backend/onyx/main.py
app.include_router(ingestion_router, prefix="/knowsee-api")
app.include_router(ingestion_router, prefix="/onyx-api")  # Deprecated

# Add deprecation warnings
# Update frontend to use new paths
# Monitor usage of old paths
# Remove old paths after 2-3 months
```

### Phase 5: Documentation Strategy (Week 5)

**Goal**: Handle external doc links

```typescript
// Add DocLinkWarning component
// Show on pages with external links
// Plan for creating your own docs (3-6 month timeline)
```

### Phase 6: Cleanup (Week 6+)

**Goal**: Remove backward compatibility code

- Remove old cookie name support
- Remove old API paths
- Remove old environment variable fallbacks
- Update any remaining references

---

## Testing Checklist

### User-Facing Tests

- [ ] Load application → should show "Welcome to Knowsee" not "Welcome to Onyx"
- [ ] Trigger error → error message says "Knowsee" not "Onyx"
- [ ] Check browser cookies → should see `knowsee_tid` not `onyx_tid` (after migration)
- [ ] Check page title → should say "Knowsee" not "Onyx"
- [ ] Access restricted page → message says "Knowsee" not "Onyx"
- [ ] Create file connector with metadata → can use both `.knowsee_metadata.json` and `.onyx_metadata.json`

### Developer-Facing Tests

- [ ] `docker compose up` → containers named `knowsee-*` not `onyx-*`
- [ ] Check environment variables → `KNOWSEE_BOT_*` work, `ONYX_BOT_*` still work (with warning)
- [ ] API calls to `/knowsee-api/*` → work correctly
- [ ] API calls to `/onyx-api/*` → work but log deprecation warning
- [ ] Pull Docker images → `knowseedotapp/knowsee-backend` works
- [ ] React DevTools → components named `Knowsee*` not `Onyx*`

### Regression Tests

- [ ] Existing users can still log in (cookie migration works)
- [ ] Existing API clients still work (dual path support)
- [ ] Existing connectors still function
- [ ] Database queries still work (no table rename issues)
- [ ] Slack bot still responds (environment variables work)

---

## Automated Rename Script

Create a script for automated renaming:

```bash
#!/bin/bash
# scripts/intelligent_rename.sh

set -e

echo "🔄 Starting intelligent Onyx → Knowsee rename..."

# Phase 1: User-facing UI text
echo "📝 Phase 1: Renaming user-facing text..."
find web/src/components web/src/app -type f \( -name "*.tsx" -o -name "*.ts" \) \
  -exec sed -i '' \
  -e 's/Welcome to Onyx/Welcome to Knowsee/g' \
  -e 's/Onyx brings/Knowsee brings/g' \
  -e 's/continue using Onyx/continue using Knowsee/g' \
  -e 's/access to Onyx/access to Knowsee/g' \
  -e 's/Try Onyx/Try Knowsee/g' \
  {} +

# Phase 2: Backend constants
echo "📝 Phase 2: Updating backend constants..."
sed -i '' \
  -e 's/ONYX_DEFAULT_APPLICATION_NAME = "Onyx"/KNOWSEE_DEFAULT_APPLICATION_NAME = "Knowsee"/' \
  -e 's/functionalities of Onyx/functionalities of Knowsee/' \
  -e 's/use Onyx as/use Knowsee as/' \
  backend/onyx/configs/constants.py

# Phase 3: Docker image names
echo "🐳 Phase 3: Updating Docker image references..."
find deployment -type f \( -name "*.yml" -o -name "*.yaml" \) \
  -exec sed -i '' 's/onyxdotapp\/onyx-/knowseedotapp\/knowsee-/g' {} +

# Phase 4: Component names
echo "⚛️  Phase 4: Renaming React components..."
mv web/src/components/OnyxInitializingLoader.tsx \
   web/src/components/KnowseeInitializingLoader.tsx 2>/dev/null || true

find web/src -type f \( -name "*.tsx" -o -name "*.ts" \) \
  -exec sed -i '' \
  -e 's/OnyxIcon/KnowseeIcon/g' \
  -e 's/OnyxLogoTypeIcon/KnowseeLogoTypeIcon/g' \
  -e 's/OnyxInitializingLoader/KnowseeInitializingLoader/g' \
  -e 's/OnyxDocument/KnowseeDocument/g' \
  {} +

echo "✅ Intelligent rename complete!"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test locally: docker compose up"
echo "3. Run tests: npm test && pytest"
echo "4. Commit: git commit -am 'rebrand: Onyx → Knowsee (user-facing)'"
```

Run it:
```bash
chmod +x scripts/intelligent_rename.sh
./scripts/intelligent_rename.sh
```

---

## Summary: What to Rename vs Not

### ✅ DO RENAME (High Value)
- UI text users see
- Error messages
- Email addresses (after owning domain)
- Docker image names
- Environment variables (with backward compat)
- Component names (developer-facing)
- Cookie names (with migration strategy)

### ⚠️ RENAME WITH CARE (Medium Value, High Risk)
- API endpoint paths (support both)
- Database columns (not worth it usually)
- Configuration file names

### ❌ DON'T RENAME (Low/No Value)
- Internal class names (not exported)
- Internal function names
- Database table names (unless full rebrand)
- Git history
- External documentation URLs (handle smartly instead)

---

**Questions? Need help with specific renames? Let me know!**
