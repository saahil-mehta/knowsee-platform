# Knowsee Platform - COMPREHENSIVE Rebranding Plan

**Complete Architecture-Aware Rebranding Strategy**

This document supersedes `REBRANDING_PLAN.md` with a comprehensive plan that incorporates deep architectural analysis from `ARCH.md` and `ARCH-VIZ.md`.

---

## Executive Summary

**Objective:** Complete rebranding of Onyx platform to Knowsee while maintaining upstream compatibility

**Approach:** Badge Engineering (Hybrid) + Critical Infrastructure Updates

**Total Scope:** ~400-500 files (expanded from initial 300-400 after architecture analysis)

**Critical Discovery:** Architecture analysis revealed **HIGH PRIORITY infrastructure elements** that were missing from the initial plan:
- HTTP Headers (`X-Onyx-*`)
- Request ID generation system
- Redis key namespaces and locks
- Telemetry endpoints
- Email domains
- Cookie names
- Vespa index names
- Slack bot messages

---

## Table of Contents

1. [Background & Context](#1-background--context)
2. [Key Decisions](#2-key-decisions)
3. [Critical Infrastructure Updates (NEW)](#3-critical-infrastructure-updates-new)
4. [Complete Scope Analysis](#4-complete-scope-analysis)
5. [Phase-by-Phase Implementation Plan](#5-phase-by-phase-implementation-plan)
6. [Migration Strategies](#6-migration-strategies)
7. [Testing & Verification](#7-testing--verification)
8. [Risk Assessment](#8-risk-assessment)
9. [Rollback Procedures](#9-rollback-procedures)

---

## 1. Background & Context

### Project Details
- **Repository:** `/Users/saahil/Documents/GitHub/knowsee-platform`
- **Current State:** Fork of `https://github.com/onyx-dot-app/onyx-foss.git` (MIT licensed)
- **Upstream Remote:** `onyx-upstream` tracked in git
- **Current Branch:** `main`
- **Architecture Documentation:** `ARCH.md`, `ARCH-VIZ.md`

### Technology Stack
- **Backend:** Python 3.11, FastAPI, SQLAlchemy, Alembic, Celery
- **Frontend:** Next.js 15+, React 18, TypeScript, Tailwind CSS
- **Database:** PostgreSQL with Redis caching
- **Search:** Vespa vector database
- **Infrastructure:** Docker, Kubernetes (Helm), AWS (CloudFormation, Terraform)

### Branding Assets
- **Location:** `/Users/saahil/Downloads/assets` (requires manual copy)
- **Contents:** Font and logo variations
- **Brand Color:** #6214D9 (for accents, highlights, glows)

---

## 2. Key Decisions

### 2.1 Rebranding Scope

**Decision:** Badge Engineering (Hybrid) + Critical Infrastructure Rebrand

**What Changes:**
- ✅ All user-facing UI text and components
- ✅ All documentation and README files
- ✅ Docker service names and images
- ✅ **HTTP Headers (`X-Onyx-*` → `X-Knowsee-*`)** 🔴 NEW
- ✅ **Request ID generation (`onyx_request_id` → `knowsee_request_id`)** 🔴 NEW
- ✅ **Redis key prefixes and locks** 🔴 NEW
- ✅ **Telemetry endpoint (onyx.app → knowsee.com)** 🔴 NEW
- ✅ **Email addresses and domains** 🔴 NEW
- ✅ **Cookie names (`onyx_tid` → `knowsee_tid`)** 🔴 NEW
- ✅ **Slack bot messages and display names** 🔴 NEW
- ✅ Environment variable prefixes (ONYX_* → KNOWSEE_*)
- ✅ Helm charts and deployment templates
- ✅ CloudFormation/Terraform resource names
- ✅ Logos, icons, favicons
- ✅ Frontend component names
- ✅ API response messages

**What Stays Unchanged:**
- ❌ Backend Python package name (`backend/onyx/`)
- ❌ Python imports (`from onyx import ...`)
- ❌ Database table/column names
- ❌ Migration file names
- ❌ Internal backend class names (non-user-facing)
- ❌ Package name in `pyproject.toml`

### 2.2 Naming Conventions

**Slack Bot:** `onyxbot` → `knowsee-bot`

**Environment Variables:** `ONYX_*` → `KNOWSEE_*`

**Docker Services:**
- `onyx-postgres` → `knowsee-postgres`
- `onyx-api` → `knowsee-api`
- `onyx-webserver` → `knowsee-webserver`

**HTTP Headers:**
- `X-Onyx-Tenant-ID` → `X-Knowsee-Tenant-ID`
- `X-Onyx-Request-ID` → `X-Knowsee-Request-ID`
- `X-Onyx-Authorization` → `X-Knowsee-Authorization`

**Redis Keys:**
- `onyx_kv_store:*` → `knowsee_kv_store:*`
- Lock keys remain as `da_lock:*` for now (legacy from DanswER)

**Cookies:**
- `onyx_tid` → `knowsee_tid`
- `onyx_anonymous_user` → `knowsee_anonymous_user`

**Vespa Indices:**
- `danswer_index` → Consider `knowsee_index` (requires reindexing)
- `danswer_chunk_*` → Consider `knowsee_chunk_*` (requires reindexing)

### 2.3 Documentation Strategy

**Decision:** Keep linking to `https://docs.onyx.app/` for now

**Rationale:**
- Fast implementation
- Can set up custom docs later
- Current repo has no documentation

### 2.4 Migration Approach

**Database Migrations:** Leave completely unchanged

**Vespa Indices:** Optional rename (requires full reindex)

**Redis Keys:** Gradual migration with backward compatibility

**HTTP Headers:** Support both old and new during transition period

---

## 3. Critical Infrastructure Updates (NEW)

This section covers infrastructure elements discovered through architecture analysis that MUST be updated for a complete rebrand.

### 3.1 HTTP Headers & API Contracts

**Priority:** 🔴 **CRITICAL** - External API clients depend on these

#### Files to Update

**File:** `backend/onyx/utils/middleware.py`
```python
# OLD
X_ONYX_TENANT_ID = "X-Onyx-Tenant-ID"
X_ONYX_REQUEST_ID = "X-Onyx-Request-ID"

# NEW
X_KNOWSEE_TENANT_ID = "X-Knowsee-Tenant-ID"
X_KNOWSEE_REQUEST_ID = "X-Knowsee-Request-ID"

# TRANSITION: Support both during migration
def add_knowsee_request_id_middleware(app):
    # Check both old and new headers
    request_id = (
        request.headers.get("X-Knowsee-Request-ID") or
        request.headers.get("X-Onyx-Request-ID")  # Backward compat
    )
```

**File:** `backend/onyx/auth/api_key.py`
```python
# OLD
X_ONYX_AUTHORIZATION = "X-Onyx-Authorization"

# NEW
X_KNOWSEE_AUTHORIZATION = "X-Knowsee-Authorization"
```

**File:** `backend/shared_configs/contextvars.py`
```python
# OLD
ONYX_REQUEST_ID_CONTEXTVAR = ContextVar("onyx_request_id")

# NEW
KNOWSEE_REQUEST_ID_CONTEXTVAR = ContextVar("knowsee_request_id")
```

**Impact:**
- All API documentation must update header names
- SDKs and client libraries need updates
- Need deprecation period for external integrations

**Migration Strategy:**
- Support both old and new headers for 3-6 months
- Log warnings when old headers are used
- Eventually deprecate old headers

---

### 3.2 Request ID Generation System

**Priority:** 🔴 **HIGH** - Used in all logs and tracing

#### Files to Update

**File:** `backend/onyx/utils/middleware.py`
```python
# Function names to rename:
make_randomized_onyx_request_id() → make_randomized_knowsee_request_id()
make_structured_onyx_request_id() → make_structured_knowsee_request_id()
_make_onyx_request_id() → _make_knowsee_request_id()
```

**File:** `backend/onyx/utils/logger.py`
```python
# Class names to rename:
OnyxRequestIDFilter → KnowseeRequestIDFilter
OnyxLoggingAdapter → KnowseeLoggingAdapter

# Context var reference:
ONYX_REQUEST_ID_CONTEXTVAR → KNOWSEE_REQUEST_ID_CONTEXTVAR
```

**Files with request ID generation:**
- `backend/onyx/background/indexing/run_docfetching.py:76, 568`
- `backend/onyx/background/celery/tasks/docprocessing/tasks.py:106, 1365`

**Impact:**
- All logs will show `knowsee_request_id` instead of `onyx_request_id`
- Log parsing tools may need updates
- Tracing systems (Sentry, Datadog) may need config updates

---

### 3.3 Redis Keys & Distributed Locks

**Priority:** 🔴 **CRITICAL** - Core infrastructure, requires migration

#### Current Redis Key Patterns

**File:** `backend/onyx/key_value_store/store.py`
```python
# OLD
REDIS_KEY_PREFIX = "onyx_kv_store:"

# NEW
REDIS_KEY_PREFIX = "knowsee_kv_store:"
```

**File:** `backend/onyx/configs/constants.py`
```python
# Classes to update:
class OnyxRedisLocks:  # Line 375-419
    # Contains ~15 lock keys
    # Currently use "da_lock:" prefix (legacy DanswER)
    # Examples:
    # - "da_lock:primary_worker"
    # - "da_lock:connector_deletion"
    # - etc.

class OnyxRedisSignals:
    # Signal keys with "signal:" prefix

class OnyxRedisConstants:
    # General constants
```

**File:** `backend/scripts/debugging/onyx_redis.py`
```python
# Debug script with OnyxRedisCommand enum
# Update all class/enum names
```

**Impact:**
- 🚨 **BREAKING:** All running deployments have data in Redis with old keys
- Redis migration script required
- Potential downtime during migration
- Lock contention between old/new systems

**Migration Strategy:**

```python
# Phase 1: Support both key patterns (transition period)
def get_redis_key(base_key: str) -> str:
    new_key = f"knowsee_kv_store:{base_key}"
    old_key = f"onyx_kv_store:{base_key}"

    # Try new key first
    value = redis.get(new_key)
    if value:
        return value

    # Fallback to old key
    value = redis.get(old_key)
    if value:
        # Copy to new key for migration
        redis.set(new_key, value)
        logger.warning(f"Migrated Redis key: {old_key} → {new_key}")
    return value

# Phase 2: Migration script
def migrate_redis_keys():
    """
    Migrate all onyx_* keys to knowsee_* keys
    Run during maintenance window
    """
    cursor = 0
    while True:
        cursor, keys = redis.scan(cursor, match="onyx_kv_store:*", count=100)
        for old_key in keys:
            new_key = old_key.replace("onyx_kv_store:", "knowsee_kv_store:")
            redis.rename(old_key, new_key)
        if cursor == 0:
            break

# Phase 3: Remove old key support (after migration complete)
```

---

### 3.4 Telemetry & Analytics

**Priority:** 🔴 **HIGH** - Data collection endpoint

**File:** `backend/onyx/utils/telemetry.py`
```python
# OLD
_DANSWER_TELEMETRY_ENDPOINT = "https://telemetry.onyx.app/anonymous_telemetry"

# NEW
_KNOWSEE_TELEMETRY_ENDPOINT = "https://telemetry.knowsee.com/anonymous_telemetry"
```

**Impact:**
- Need to set up new telemetry endpoint at `telemetry.knowsee.com`
- Or redirect old endpoint to new one
- Historical telemetry data at old endpoint

**Action Items:**
1. Set up new domain `telemetry.knowsee.com`
2. Deploy telemetry ingestion service
3. Update endpoint in code
4. Optional: Redirect old endpoint for backward compat

---

### 3.5 Email Infrastructure

**Priority:** 🟡 **MEDIUM** - User-facing but not critical

**File:** `backend/onyx/auth/email_utils.py`
```python
# Line 213, 265
# OLD
from_email = "noreply@onyx.app"
message_id_domain = "onyx.app"

# NEW
from_email = "noreply@knowsee.com"
message_id_domain = "knowsee.com"

# Line 321, 332 - User-facing links
# OLD
pricing_url = "https://www.onyx.app/pricing"

# NEW
pricing_url = "https://www.knowsee.com/pricing"
```

**File:** `backend/onyx/configs/constants.py`
```python
# Line 33, 90
# OLD
NO_AUTH_USER_EMAIL = "anonymous@onyx.app"
DANSWER_API_KEY_DUMMY_EMAIL_DOMAIN = "onyxapikey.ai"

# NEW
NO_AUTH_USER_EMAIL = "anonymous@knowsee.com"
KNOWSEE_API_KEY_DUMMY_EMAIL_DOMAIN = "knowseeapikey.ai"
```

**Impact:**
- Configure email sending domain (SPF, DKIM records)
- Update email templates
- Users will receive emails from new domain

**Action Items:**
1. Register domain: `knowsee.com`
2. Configure DNS (SPF, DKIM, DMARC)
3. Set up email service (SendGrid, AWS SES, etc.)
4. Update all email templates

---

### 3.6 Cookie Names & Session Management

**Priority:** 🟡 **MEDIUM** - Requires session migration

**File:** `backend/onyx/configs/constants.py`
```python
# Line 29-30
# OLD
TENANT_ID_COOKIE_NAME = "onyx_tid"
ANONYMOUS_USER_COOKIE_NAME = "onyx_anonymous_user"

# NEW
TENANT_ID_COOKIE_NAME = "knowsee_tid"
ANONYMOUS_USER_COOKIE_NAME = "knowsee_anonymous_user"
```

**Impact:**
- Users will be logged out during migration (cookies change names)
- Frontend middleware needs to check both old and new cookies during transition
- Session data must migrate

**Migration Strategy:**
```typescript
// web/src/middleware.ts
function getTenantId(request: NextRequest): string | null {
  // Try new cookie first
  let tenantId = request.cookies.get('knowsee_tid')?.value;

  if (!tenantId) {
    // Fallback to old cookie
    tenantId = request.cookies.get('onyx_tid')?.value;

    if (tenantId) {
      // Migrate: set new cookie
      response.cookies.set('knowsee_tid', tenantId);
      logger.info('Migrated tenant cookie');
    }
  }

  return tenantId;
}
```

---

### 3.7 Vespa Index Names

**Priority:** 🟡 **MEDIUM** - Optional, requires reindexing

**File:** `backend/onyx/configs/app_configs.py`
```python
# Line 185
# OLD
DOCUMENT_INDEX_NAME = "danswer_index"

# NEW (optional)
DOCUMENT_INDEX_NAME = "knowsee_index"
```

**File:** `backend/onyx/configs/embedding_configs.py`
```python
# Lines 27-37+ (27 entries)
# OLD
index_name="danswer_chunk_*"

# NEW (optional)
index_name="knowsee_chunk_*"
```

**File:** `backend/onyx/document_index/vespa/app_config/services.xml.jinja`
```xml
<!-- Line 10, 13, 20 -->
<!-- OLD -->
<node hostalias="danswer-node" />
<content id="danswer_index" version="1.0">

<!-- NEW (optional) -->
<node hostalias="knowsee-node" />
<content id="knowsee_index" version="1.0">
```

**Impact:**
- 🚨 **MAJOR:** Renaming Vespa indices requires complete reindexing
- All documents must be re-fetched and re-embedded
- Significant downtime or blue/green deployment required

**Decision:**
- **Recommendation:** Keep `danswer_*` names for now
- Low user visibility (internal infrastructure)
- Can rename in future major version
- OR: Use blue/green deployment strategy

---

### 3.8 Slack Bot Messages

**Priority:** 🔴 **HIGH** - Highly visible to users

#### Files with User-Facing Slack Messages

**File:** `backend/onyx/onyxbot/slack/handlers/handle_regular_answer.py`
```python
# Line 71, 277, 280
# OLD
"Hello! Onyx has some results for you!"
"Onyx is down for maintenance"

# NEW
"Hello! Knowsee has some results for you!"
"Knowsee is down for maintenance"
```

**File:** `backend/onyx/onyxbot/slack/handlers/handle_message.py`
```python
# Line 174, 179, 204
# OLD
"OnyxBot is disabled"
"OnyxBot only responds to tags"
"The OnyxBot slash command"

# NEW
"Knowsee Bot is disabled"
"Knowsee Bot only responds to tags"
"The Knowsee Bot slash command"
```

**File:** `backend/onyx/onyxbot/slack/handlers/handle_buttons.py`
```python
# Line 299
# OLD
"Hello! Onyx has some results for you!"

# NEW
"Hello! Knowsee has some results for you!"
```

**File:** `backend/onyx/onyxbot/slack/blocks.py`
```python
# Line 507
# OLD
"Continue Chat in Onyx!"

# NEW
"Continue Chat in Knowsee!"
```

**File:** `backend/onyx/onyxbot/slack/utils.py`
```python
# Line 136, 238, 618, 676
# OLD
"OnyxBot has reached the message limit"
"There was an error displaying all of the Onyx answers"
"OnyxBot response has no blocks"

# NEW
"Knowsee Bot has reached the message limit"
"There was an error displaying all of the Knowsee answers"
"Knowsee Bot response has no blocks"
```

**Total:** ~15+ user-facing Slack messages to update

---

### 3.9 Application Display Names & Constants

**Priority:** 🟡 **MEDIUM** - User-facing configuration

**File:** `backend/onyx/configs/constants.py`
```python
# Line 8-9
# OLD
ONYX_DEFAULT_APPLICATION_NAME = "Onyx"
ONYX_DISCORD_URL = "https://discord.gg/4NA5SbzrWb"

# NEW
KNOWSEE_DEFAULT_APPLICATION_NAME = "Knowsee"
KNOWSEE_DISCORD_URL = "https://discord.gg/<new-invite>"  # Update if needed

# Line 42
# OLD
ONYX_METADATA_FILENAME = ".onyx_metadata.json"

# NEW
KNOWSEE_METADATA_FILENAME = ".knowsee_metadata.json"

# Line 45-48
# OLD
DISABLED_GEN_AI_MSG = "...Onyx..."

# NEW
DISABLED_GEN_AI_MSG = "...Knowsee..."

# Line 107-111
# OLD
KV_SETTINGS_KEY = "onyx_settings"
KV_ENTERPRISE_SETTINGS_KEY = "onyx_enterprise_settings"

# NEW
KV_SETTINGS_KEY = "knowsee_settings"
KV_ENTERPRISE_SETTINGS_KEY = "knowsee_enterprise_settings"
```

---

### 3.10 Celery & Cloud Task Names

**Priority:** 🟡 **MEDIUM** - Internal infrastructure

**File:** `backend/onyx/configs/constants.py`
```python
# Line 453-456
# OLD
ONYX_CLOUD_CELERY_TASK_PREFIX = "cloud"
ONYX_CLOUD_TENANT_ID = "cloud"
ONYX_CLOUD_REDIS_RUNTIME = "runtime"

# NEW
KNOWSEE_CLOUD_CELERY_TASK_PREFIX = "cloud"
KNOWSEE_CLOUD_TENANT_ID = "cloud"
KNOWSEE_CLOUD_REDIS_RUNTIME = "runtime"

# Line 463-474
class OnyxCeleryTask:  # Rename to KnowseeCeleryTask
    # Task name constants
```

---

### 3.11 Static Assets & GitHub References

**Priority:** 🔵 **LOW** - Can be done later

**File:** `backend/onyx/onyxbot/slack/icons.py`
```python
# Line 7-49 (43 lines of GitHub URLs)
# OLD
https://raw.githubusercontent.com/onyx-dot-app/onyx/main/...

# NEW
https://raw.githubusercontent.com/<your-org>/knowsee-platform/main/...
```

**Impact:**
- Update if GitHub repository is renamed
- Low priority (just icon URLs)

---

### 3.12 FastAPI Application Title

**Priority:** 🟡 **MEDIUM** - Shows in OpenAPI docs

**File:** `backend/onyx/main.py`
```python
# Line 330
# OLD
title="Onyx Backend"

# NEW
title="Knowsee Backend"
```

**Impact:**
- Shows in `/docs` (Swagger UI)
- Shows in `/redoc` (ReDoc)
- Shows in OpenAPI schema

---

## 4. Complete Scope Analysis

### Total Impact Summary

| Category | Files | Priority | Breaking? |
|----------|-------|----------|-----------|
| HTTP Headers | 3 | 🔴 CRITICAL | Yes |
| Request IDs | 5 | 🔴 HIGH | No |
| Redis Keys | 8 | 🔴 CRITICAL | Yes |
| Telemetry | 1 | 🔴 HIGH | Yes |
| Email | 2 | 🟡 MEDIUM | No |
| Cookies | 2 | 🟡 MEDIUM | Yes |
| Slack Messages | 15+ | 🔴 HIGH | No |
| Vespa Indices | 5 | 🟡 MEDIUM | Yes |
| Constants | 10+ | 🟡 MEDIUM | No |
| Frontend (from Phase 2) | 118 | 🔴 HIGH | No |
| Docker/Config | 92 | 🔴 HIGH | Yes |
| Documentation | 23 | 🟡 MEDIUM | No |
| GitHub Workflows | 18 | 🟡 MEDIUM | No |
| **TOTAL** | **~302+** | | |

**Updated Estimate:** ~400-500 files total including all infrastructure updates

---

## 5. Phase-by-Phase Implementation Plan

### Phase 0: Pre-Flight Checklist

**Objective:** Prepare environment and assets

**Steps:**
1. ✅ Create backup branch: `git checkout -b rebranding-knowsee`
2. ✅ Copy assets from `/Users/saahil/Downloads/assets` to repo
3. ✅ Set up new domains:
   - `knowsee.com`
   - `docs.knowsee.com` (future)
   - `telemetry.knowsee.com`
4. ✅ Configure email infrastructure (SPF, DKIM)
5. ✅ Review and approve this plan
6. ✅ Schedule maintenance window for Redis/Cookie migration

**Deliverables:**
- Backup branch created
- Assets in `web/public/assets/knowsee/`
- DNS configured
- Team notified

---

### Phase 1: Critical Infrastructure Updates

**Objective:** Update core infrastructure that requires careful migration

**Priority:** 🔴 **CRITICAL**

#### 1.1 HTTP Headers & Request IDs

**Files to update:**
- `backend/onyx/utils/middleware.py`
- `backend/onyx/auth/api_key.py`
- `backend/shared_configs/contextvars.py`
- `backend/onyx/utils/logger.py`
- `backend/onyx/background/indexing/run_docfetching.py`
- `backend/onyx/background/celery/tasks/docprocessing/tasks.py`

**Strategy:**
- Support both old and new header names
- Add deprecation warnings to logs
- Update internal generation to use new names

**Testing:**
- Test with both `X-Onyx-*` and `X-Knowsee-*` headers
- Verify logs show correct request IDs
- Verify API clients still work

#### 1.2 Redis Key Migration

**Files to update:**
- `backend/onyx/key_value_store/store.py`
- `backend/onyx/configs/constants.py` (OnyxRedisLocks, OnyxRedisSignals, OnyxRedisConstants)

**Strategy:**
1. Add backward compatibility layer (read both old/new keys)
2. Create migration script (`scripts/redis_migration.py`)
3. Run migration during maintenance window
4. Remove old key support after verification

**Migration Script:**
```python
# scripts/redis_migration.py
import redis
from tqdm import tqdm

def migrate_redis_keys(dry_run=True):
    r = redis.Redis(host='localhost', port=6379, db=0)

    # Migrate KV store keys
    cursor = 0
    migrated = 0

    while True:
        cursor, keys = r.scan(cursor, match="onyx_kv_store:*", count=1000)

        for old_key in keys:
            new_key = old_key.decode().replace("onyx_kv_store:", "knowsee_kv_store:")

            if dry_run:
                print(f"Would migrate: {old_key} → {new_key}")
            else:
                r.rename(old_key, new_key)
                migrated += 1

        if cursor == 0:
            break

    print(f"Migrated {migrated} keys")

    # TODO: Migrate lock keys (da_lock:* are legacy, may keep as-is)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--execute", action="store_true", help="Actually run migration")
    args = parser.parse_args()

    migrate_redis_keys(dry_run=not args.execute)
```

**Testing:**
- Test in staging first
- Verify no data loss
- Verify locks still work
- Monitor for errors

#### 1.3 Cookie Migration

**Files to update:**
- `backend/onyx/configs/constants.py`
- `web/src/middleware.ts`

**Strategy:**
- Support both old and new cookie names during transition
- Auto-migrate cookies on next request
- Users may be logged out once during migration

**Testing:**
- Test login flow with new cookies
- Test session persistence
- Test tenant switching

#### 1.4 Telemetry Endpoint

**Files to update:**
- `backend/onyx/utils/telemetry.py`

**Pre-requisites:**
- Set up `telemetry.knowsee.com` endpoint
- Deploy telemetry ingestion service
- Or configure redirect from old endpoint

**Testing:**
- Verify telemetry data reaches new endpoint
- Check for errors in logs

**Estimated Time:** 8-12 hours

---

### Phase 2: Asset Integration & Frontend

**Objective:** Rebrand all user-facing UI elements

**Priority:** 🔴 **HIGH**

*(Same as original plan Phase 2 - see REBRANDING_PLAN.md for details)*

**Files Modified:** ~118 files

**Estimated Time:** 3-4 hours

---

### Phase 3: Slack Bot Messages

**Objective:** Update all Slack bot user-facing messages

**Priority:** 🔴 **HIGH**

**Files to update:**
- `backend/onyx/onyxbot/slack/handlers/handle_regular_answer.py`
- `backend/onyx/onyxbot/slack/handlers/handle_message.py`
- `backend/onyx/onyxbot/slack/handlers/handle_buttons.py`
- `backend/onyx/onyxbot/slack/blocks.py`
- `backend/onyx/onyxbot/slack/utils.py`
- `backend/onyx/onyxbot/slack/listener.py`
- `backend/onyx/configs/onyxbot_configs.py`

**Find/Replace Patterns:**
- "Onyx has some results" → "Knowsee has some results"
- "OnyxBot is" → "Knowsee Bot is"
- "Continue Chat in Onyx" → "Continue Chat in Knowsee"
- All environment variables: `ONYX_BOT_*` → `KNOWSEE_BOT_*`

**Testing:**
- Test Slack bot in dev workspace
- Verify all messages display correctly
- Test all interactive components (buttons, menus)

**Estimated Time:** 2-3 hours

---

### Phase 4: Backend Configuration & Constants

**Objective:** Update all backend configuration values and constants

**Priority:** 🟡 **MEDIUM**

**Files to update:**
- `backend/onyx/configs/constants.py` (complete pass)
- `backend/onyx/configs/app_configs.py`
- `backend/shared_configs/configs.py`
- `backend/onyx/main.py` (FastAPI title)
- `backend/onyx/auth/email_utils.py`

**Changes:**
- Application name constants
- Email addresses and domains
- Metadata filename
- KV store keys
- Error messages
- Support links (Discord URL)

**Testing:**
- Test application startup
- Verify configuration loads correctly
- Test email sending (if configured)

**Estimated Time:** 2-3 hours

---

### Phase 5: Docker & Container Infrastructure

**Objective:** Rebrand all Docker services, containers, images

**Priority:** 🔴 **HIGH**

*(Same as original plan Phase 3 - see REBRANDING_PLAN.md for details)*

**Files Modified:** ~8-10 docker-compose files

**Estimated Time:** 2-3 hours

---

### Phase 6: Environment Variables

**Objective:** Rename all ONYX_* environment variables to KNOWSEE_*

**Priority:** 🔴 **HIGH**

*(Same as original plan Phase 4 - see REBRANDING_PLAN.md for details)*

**Files Modified:** ~15-20 config files

**Estimated Time:** 1-2 hours

---

### Phase 7: Deployment Infrastructure

**Objective:** Rebrand Helm, CloudFormation, Terraform

**Priority:** 🟡 **MEDIUM**

*(Same as original plan Phase 5 - see REBRANDING_PLAN.md for details)*

**Files Modified:** ~100+ files

**Estimated Time:** 4-6 hours

---

### Phase 8: Documentation

**Objective:** Update all documentation to reflect Knowsee branding

**Priority:** 🟡 **MEDIUM**

*(Same as original plan Phase 6 - see REBRANDING_PLAN.md for details)*

**Files Modified:** ~23 documentation files

**Estimated Time:** 2-3 hours

---

### Phase 9: GitHub Workflows & CI/CD

**Objective:** Update workflow names, Docker image builds

**Priority:** 🟡 **MEDIUM**

*(Same as original plan Phase 7 - see REBRANDING_PLAN.md for details)*

**Files Modified:** 18 workflow files

**Estimated Time:** 1-2 hours

---

### Phase 10: Testing & Verification

**Objective:** Comprehensive testing of all changes

**Priority:** 🔴 **CRITICAL**

*(Expanded from original plan Phase 9)*

#### 10.1 Infrastructure Testing

**HTTP Headers:**
```bash
# Test with old header
curl -H "X-Onyx-Authorization: API_KEY__test" http://localhost:8080/api/health
# Should work (backward compat)

# Test with new header
curl -H "X-Knowsee-Authorization: API_KEY__test" http://localhost:8080/api/health
# Should work

# Test request ID in response
curl -v http://localhost:8080/api/health
# Should see X-Knowsee-Request-ID in response headers
```

**Redis Keys:**
```bash
# Connect to Redis
redis-cli

# Check for old keys
SCAN 0 MATCH onyx_kv_store:* COUNT 100
# Should be empty after migration

# Check for new keys
SCAN 0 MATCH knowsee_kv_store:* COUNT 100
# Should show migrated keys
```

**Cookies:**
```javascript
// In browser console
document.cookie
// Should show knowsee_tid instead of onyx_tid
```

**Slack Bot:**
- Test in Slack dev workspace
- Verify all messages say "Knowsee"
- Test slash commands
- Test button interactions

#### 10.2 Full System Testing

*(Same as original plan Phase 9.2-9.4)*

**Estimated Time:** 4-6 hours

---

## 6. Migration Strategies

### 6.1 Zero-Downtime Migration (Recommended)

**Strategy:** Blue/Green deployment with gradual cutover

**Steps:**

1. **Deploy New Version (Green)**
   - Deploy updated code with both old/new support
   - All services support both naming conventions
   - Log which convention is being used

2. **Data Migration (Background)**
   - Run Redis migration script (off-peak hours)
   - Migrate cookies on user requests (auto)
   - Update external API client documentation

3. **Monitor & Verify (1-2 weeks)**
   - Monitor usage of old vs new conventions
   - Check for errors or issues
   - Verify all features work correctly

4. **Remove Old Support (Blue Decommission)**
   - After verification period, remove old naming support
   - Return errors for old API headers
   - Clean up backward compatibility code

### 6.2 Maintenance Window Migration (Faster)

**Strategy:** Scheduled downtime for clean cutover

**Steps:**

1. **Pre-Migration (Day Before)**
   - Announce maintenance window
   - Deploy code update
   - Test in staging

2. **Maintenance Window (2-4 hours)**
   - Stop all services
   - Run Redis migration
   - Update all environment variables
   - Clear old cookies (users logged out)
   - Start services with new configuration

3. **Post-Migration**
   - Verify all services healthy
   - Test critical user flows
   - Monitor for issues

**Recommended:** Use Zero-Downtime for production deployments

---

### 6.3 Per-Component Migration Strategies

#### HTTP Headers
- **Strategy:** Dual-support for 3 months
- **Timeline:** Deploy → Monitor → Deprecate

#### Redis Keys
- **Strategy:** Big-bang migration during maintenance
- **Timeline:** 1 hour downtime

#### Cookies
- **Strategy:** Auto-migration on request
- **Timeline:** Gradual over days/weeks

#### Slack Bot
- **Strategy:** Direct update (no backward compat needed)
- **Timeline:** Immediate

#### Vespa Indices (Optional)
- **Strategy:** Blue/Green with reindexing
- **Timeline:** Days/weeks (depends on data size)

---

## 7. Testing & Verification

### 7.1 Pre-Deployment Testing

**Unit Tests:**
```bash
# Backend
cd backend
source .venv/bin/activate
pytest backend/tests/unit -xv

# Frontend
cd web
npm test
```

**Integration Tests:**
```bash
pytest backend/tests/integration -xv
```

**Build Tests:**
```bash
# Frontend
cd web && npm run build

# Docker
docker-compose build
```

### 7.2 Post-Deployment Verification

**Checklist:**

- [ ] All services start successfully
- [ ] Web UI loads and shows "Knowsee"
- [ ] Login works (new cookies set)
- [ ] API endpoints respond
- [ ] Request IDs in logs show `knowsee_request_id`
- [ ] Redis keys use new prefixes
- [ ] Slack bot sends messages with "Knowsee"
- [ ] Email sends from `noreply@knowsee.com`
- [ ] Telemetry reaches new endpoint
- [ ] API clients work with new headers
- [ ] Old headers still work (if in compat mode)
- [ ] No errors in logs
- [ ] All Celery workers running
- [ ] Search and chat work correctly

### 7.3 Monitoring

**Metrics to Watch:**

- Error rates (should not increase)
- Request latency (should not increase)
- Login success rate
- API call success rate
- Celery queue lengths
- Redis memory usage
- Database connection count

**Logging:**

- Filter logs for "WARN" or "ERROR"
- Check for deprecated header warnings
- Monitor Redis migration progress
- Watch for cookie migration messages

---

## 8. Risk Assessment

### 8.1 Critical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Redis key migration data loss | 🔴 CRITICAL | Low | Test in staging, create backup, use migration script with dry-run |
| API clients break (header changes) | 🔴 HIGH | Medium | Support both headers during transition, document changes |
| User sessions lost (cookie rename) | 🟡 MEDIUM | High | Expected, communicate to users, auto-migrate on next request |
| Vespa reindexing failure | 🔴 HIGH | Low | Optional change, can defer |
| Email delivery issues | 🟡 MEDIUM | Medium | Configure DNS properly, test before deployment |
| Telemetry data loss | 🟡 MEDIUM | Low | Set up new endpoint first, test connectivity |

### 8.2 Risk Mitigation Strategies

**For Redis Migration:**
- Create backup before migration: `redis-cli SAVE`
- Test migration script in staging
- Run with `--dry-run` first
- Monitor during migration
- Have rollback plan ready

**For API Headers:**
- Maintain backward compatibility for 3-6 months
- Document breaking changes
- Provide migration guide for API clients
- Add deprecation warnings

**For Cookies:**
- Accept this as expected behavior
- Communicate to users in advance
- Auto-migrate on next request
- Provide smooth re-login experience

---

## 9. Rollback Procedures

### 9.1 Full Rollback

If major issues discovered:

```bash
# Stop all services
docker-compose down

# Rollback code
git checkout main
git branch -D rebranding-knowsee

# Restore Redis from backup (if migration completed)
redis-cli FLUSHALL
redis-cli --rdb /path/to/backup.rdb

# Restart services
docker-compose up -d
```

### 9.2 Partial Rollback

If specific component fails:

**Redis Only:**
```bash
# Restore Redis from backup
redis-cli FLUSHALL
redis-cli --rdb /backup/dump.rdb
```

**Environment Variables Only:**
```bash
# Revert .env file
git checkout main -- .env
docker-compose restart
```

**Docker Services Only:**
```bash
# Revert docker-compose
git checkout main -- deployment/docker_compose/
docker-compose up -d
```

### 9.3 Data Recovery

**Redis Backup:**
```bash
# Before migration
redis-cli SAVE
cp /var/lib/redis/dump.rdb /backup/dump-pre-migration.rdb

# Restore if needed
redis-cli FLUSHALL
redis-cli --rdb /backup/dump-pre-migration.rdb
```

**Database Rollback:**
Not needed - we're not changing database schema

**Vespa Rollback:**
Not needed unless optional index rename performed

---

## 10. Timeline & Resources

### 10.1 Estimated Timeline

**With Manual Review (Recommended):**

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 0: Pre-Flight | 4 hours | 4 hours |
| Phase 1: Critical Infrastructure | 8-12 hours | 12-16 hours |
| Phase 2: Frontend | 3-4 hours | 15-20 hours |
| Phase 3: Slack Bot | 2-3 hours | 17-23 hours |
| Phase 4: Backend Config | 2-3 hours | 19-26 hours |
| Phase 5: Docker | 2-3 hours | 21-29 hours |
| Phase 6: Environment Variables | 1-2 hours | 22-31 hours |
| Phase 7: Deployment Infra | 4-6 hours | 26-37 hours |
| Phase 8: Documentation | 2-3 hours | 28-40 hours |
| Phase 9: GitHub Workflows | 1-2 hours | 29-42 hours |
| Phase 10: Testing | 4-6 hours | 33-48 hours |

**Total: 33-48 hours (4-6 working days)**

### 10.2 Team Resources

**Required Roles:**

- **Backend Engineer:** Critical infrastructure, Redis migration
- **Frontend Engineer:** UI components, cookies
- **DevOps Engineer:** Docker, Kubernetes, deployment
- **QA Engineer:** Testing and verification
- **Technical Writer:** Documentation updates

**Minimum Team:** 2-3 engineers over 1 week

**Optimal Team:** 4-5 engineers over 3-4 days

---

## 11. Success Criteria

### 11.1 Must-Have (MVP)

- [ ] All services start and run without errors
- [ ] UI shows "Knowsee" everywhere users see text
- [ ] Users can log in and use the application
- [ ] Chat and search work correctly
- [ ] Connectors can index documents
- [ ] Slack bot sends messages (if configured)
- [ ] No data loss in Redis or databases
- [ ] All critical tests pass

### 11.2 Should-Have

- [ ] New email domain configured and working
- [ ] New telemetry endpoint receiving data
- [ ] API clients updated with new headers
- [ ] All documentation updated
- [ ] Monitoring shows healthy metrics
- [ ] No increase in error rates

### 11.3 Nice-to-Have

- [ ] Vespa indices renamed (optional)
- [ ] Custom documentation site (future)
- [ ] All legacy "danswer" references removed
- [ ] GitHub repository renamed

---

## 12. Communication Plan

### 12.1 Internal Communication

**Before Migration:**
- [ ] Share this plan with team
- [ ] Schedule migration date/time
- [ ] Assign responsibilities
- [ ] Set up war room (Slack channel, video call)

**During Migration:**
- [ ] Regular status updates in war room
- [ ] Document any issues encountered
- [ ] Track progress against timeline

**After Migration:**
- [ ] Post-mortem meeting
- [ ] Document lessons learned
- [ ] Update this plan with improvements

### 12.2 External Communication

**API Clients:**
- [ ] Email notification 2 weeks before
- [ ] Documentation of breaking changes
- [ ] Migration guide for updating headers
- [ ] Deprecation timeline

**End Users:**
- [ ] Announce rebranding
- [ ] Explain cookie/session reset
- [ ] Provide new support channels
- [ ] Update help documentation

**Stakeholders:**
- [ ] Executive summary of changes
- [ ] Business impact assessment
- [ ] Timeline and risk mitigation
- [ ] Success metrics

---

## 13. Appendix

### 13.1 Complete File Manifest

See ARCH.md Section 3 for complete repository tree.

### 13.2 Architecture References

- **ARCH.md:** Complete architectural documentation
- **ARCH-VIZ.md:** Visual diagrams and swim lanes
- **REBRANDING_PLAN.md:** Original (simpler) rebranding plan

### 13.3 Key Discoveries from Architecture Analysis

1. **HTTP Headers** - External API contract (breaking change)
2. **Redis Keys** - Critical infrastructure requiring migration
3. **Request IDs** - Logging and observability system
4. **Telemetry** - Requires new endpoint setup
5. **Email Infrastructure** - Requires DNS and service config
6. **Slack Messages** - Highly visible to users
7. **Cookie Names** - Session management impact
8. **Vespa Indices** - Optional but requires reindexing

### 13.4 Tools & Scripts

**Redis Migration:**
- `scripts/redis_migration.py` (create this)

**Key Verification:**
- `scripts/verify_rebranding.py` (create this)

**Environment Check:**
- `scripts/check_env_vars.py` (create this)

---

## 14. Next Steps

1. **Review and Approve Plan**
   - Team review meeting
   - Address questions/concerns
   - Get stakeholder sign-off

2. **Set Up Prerequisites**
   - Copy branding assets
   - Configure domains (knowsee.com, telemetry.knowsee.com)
   - Set up email infrastructure
   - Schedule maintenance window

3. **Create Backup Branch**
   ```bash
   git checkout -b rebranding-knowsee
   git push origin rebranding-knowsee
   ```

4. **Start Phase 1**
   - Begin with critical infrastructure updates
   - Test thoroughly in staging
   - Monitor closely

5. **Execute Plan**
   - Follow phases in order
   - Test after each phase
   - Document issues and resolutions

---

**Document Version:** 2.0 (Comprehensive)
**Last Updated:** 2025-10-31
**Status:** Ready for approval and execution
**Approach:** Badge Engineering + Critical Infrastructure Updates
**Estimated Effort:** 33-48 hours over 4-6 days
**Risk Level:** Medium-High (due to infrastructure changes)
