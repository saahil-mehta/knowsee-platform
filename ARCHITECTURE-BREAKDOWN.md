# Onyx Architecture Breakdown: What's Essential vs Over-Engineered

## 🎯 For Your Marketing Agency Use Case

---

## 📊 Container Architecture

### **Essential Services (MUST HAVE)**

| Service | Purpose | Why Essential | Resource Usage |
|---------|---------|---------------|----------------|
| **api_server** | Backend API | Core business logic, connector management, search APIs | Medium |
| **web_server** | Next.js Frontend | User interface | Low |
| **relational_db** (Postgres) | Primary database | Stores users, credentials, connectors, chat history | Medium |
| **cache** (Redis) | Caching & queues | Celery task queue, session caching, OAuth state | Low |
| **index** (Vespa) | Vector search engine | Semantic search, document embeddings | High |

**Total Essential:** 5 containers
**Memory:** ~8-12GB

---

### **Important But Could Be Simplified**

| Service | Purpose | Alternative | Trade-off |
|---------|---------|-------------|-----------|
| **background** | Celery workers | Could use simpler task queue | Celery is robust but complex |
| **inference_model_server** | Embedding model for queries | Use OpenAI API instead | Saves memory, costs API calls |
| **indexing_model_server** | Embedding model for documents | Use OpenAI API instead | Saves memory, costs API calls |
| **minio** | S3-compatible storage | Use real S3 or local filesystem | MinIO adds complexity |

**If simplified:** Could reduce to 5-6 containers instead of 9

---

### **Over-Engineered (Questionable Value)**

| Service | Purpose | Over-Engineering Issue | Recommendation |
|---------|---------|------------------------|----------------|
| **nginx** | Reverse proxy | Not needed for local dev | Remove for local testing |
| **certbot** (in prod) | SSL certificates | Only for production | Skip for local/testing |
| **Separate model servers** | Dedicated embedding services | Could use single server or API | Consolidate or externalize |

---

## 🧩 Backend Architecture

### **Essential Components**

```python
backend/
├── onyx/
│   ├── auth/              # ✅ ESSENTIAL: User authentication
│   ├── chat/              # ✅ ESSENTIAL: Chat/Q&A functionality
│   ├── connectors/        # ✅ ESSENTIAL: Data source integrations
│   ├── db/                # ✅ ESSENTIAL: Database models
│   ├── document_index/    # ✅ ESSENTIAL: Vespa integration
│   ├── llm/               # ✅ ESSENTIAL: LLM provider integrations
│   └── server/            # ✅ ESSENTIAL: FastAPI endpoints
```

### **Over-Engineered Components**

```python
backend/
├── onyx/
│   ├── background/celery/          # ⚠️ COMPLEX: 9 different worker types
│   │   ├── tasks/                  #    Could simplify to 2-3 workers
│   │   ├── beat/                   #    Beat scheduler adds complexity
│   │   └── monitoring/             #    Monitoring worker - really needed?
│   │
│   ├── dask/                       # ❌ OVERKILL: Dask for parallelization
│   │                               #    Most deployments don't need this
│   │
│   ├── file_store/                 # ⚠️ ABSTRACTION: S3/MinIO/Azure/GCS
│   │                               #    Just pick one for your use case
│   │
│   ├── federated_connectors/       # ❌ ENTERPRISE: External search APIs
│   │                               #    (Bing, Kendra, Glean, etc.)
│   │                               #    Probably don't need this
│   │
│   └── secondary_llm_flows/        # ⚠️ COMPLEX: Multi-step LLM pipelines
│                                   #    Could simplify to basic chat
```

---

## 🤔 What's Actually Needed for Marketing Agency?

### **Minimal Viable Architecture**

```
User Flow:
1. User logs in (Auth) ✅
2. Connects Google Drive (Per-user OAuth) ✅
3. System indexes their accessible docs (Background job) ✅
4. User searches/chats (LLM + Vector search) ✅
5. Results filtered by user permissions ✅
```

### **Simplified Container Setup**

```yaml
services:
  # Core API
  api_server:           # FastAPI backend

  # Frontend
  web_server:           # Next.js UI

  # Storage
  postgres:             # Primary database
  redis:                # Task queue + cache
  vespa:                # Vector search

  # Background Processing
  worker:               # Single consolidated worker

  # Optional: Self-hosted embeddings
  model_server:         # (OR use OpenAI API)
```

**Result:** 6-7 containers instead of 9-10

---

## 📝 Specific Over-Engineering Examples

### **1. Celery Worker Explosion**

**Current:** 9 different worker types
```python
# deployment/docker_compose/docker-compose.prod.yml
- primary worker
- docfetching worker
- docprocessing worker
- light worker
- heavy worker
- kg_processing worker
- monitoring worker
- user_file_processing worker
- beat scheduler
```

**Reality Check:** Most deployments use `USE_LIGHTWEIGHT_BACKGROUND_WORKER=true` which runs ONE worker that does everything.

**Recommendation:** Start with lightweight mode. Only split workers if you have >100,000 documents.

---

### **2. Multiple Model Servers**

**Current:**
```yaml
inference_model_server:      # For query embeddings
indexing_model_server:       # For document embeddings
```

**Why Two?** Different concurrency/memory settings. But adds 4GB+ RAM overhead.

**Alternative:**
```bash
# Just use OpenAI API
GEN_AI_API_KEY=sk-...
# And set:
DISABLE_MODEL_SERVER=true
```

**Trade-off:** ~$0.0001 per embedding vs 4GB RAM

---

### **3. Multi-Tenant Complexity**

**What you DON'T need** (unless you're SaaS):
```python
# backend/onyx/configs/app_configs.py
MULTI_TENANT=false  # Set this!

# Ignore all this:
- schema_private (separate DB schemas per tenant)
- tenant-aware middleware
- per-tenant Redis namespaces
- DynamicTenantScheduler
```

**For single-organization deployment:** Just use `MULTI_TENANT=false`

---

### **4. Permission Sync Complexity**

**Enterprise Feature:** Google Workspace Admin API integration
```python
# For permission sync, you need:
- Google Workspace Admin
- Domain-wide delegation
- Service Account
- Directory API access
- Regular sync jobs
```

**Your Marketing Agency Reality:**
- Clients won't give you admin access
- Each user connects their own drive
- Permissions are implicit (they only see their docs)

**Recommendation:** Don't use `AccessType.SYNC` for now. Use per-user connectors.

---

## ✅ Recommended Simplifications

### **Phase 1: Get It Running (Now)**

```bash
# Use this minimal setup:
1. docker-compose.prod.yml + docker-compose.dev.yml
2. Set USE_LIGHTWEIGHT_BACKGROUND_WORKER=true
3. Set AUTH_TYPE=disabled (for testing)
4. Use OpenAI API (DISABLE_MODEL_SERVER=true)
5. Skip nginx, certbot, monitoring

Result: 6 containers, ~6GB RAM, fast startup
```

### **Phase 2: Add OAuth Connectors**

```bash
# Add per-user Google Drive:
1. Create OAuth app in Google Cloud Console
2. Add test users to consent screen
3. Set OAUTH_GOOGLE_DRIVE_CLIENT_ID/SECRET
4. Modify UI to allow non-admin auth (OR use generic OAuth endpoint)

Result: Users can connect their own drives
```

### **Phase 3: Add Marketing-Specific Connectors**

```python
# What marketing agencies actually need:
- Google Drive (personal + shared drives)
- Google Sheets (campaign data)
- Google Ads API (campaign performance)
- Facebook Ads API (ad performance)
- HubSpot/Salesforce (CRM data)
- Slack (team communication)
- Monday.com / Asana (project management)

# Most of these don't exist in Onyx yet
# You'll need to build them using the connector pattern I showed earlier
```

### **Phase 4: Simplify Deployment**

```yaml
# Create your own docker-compose.simple.yml
services:
  app:              # Combine api_server + background into one
  web:              # Next.js
  db:               # Postgres
  cache:            # Redis
  search:           # Vespa

# Run with:
docker compose -f docker-compose.simple.yml up
```

---

## 🎯 Final Recommendations

### **What to KEEP from Onyx:**

✅ **Connector framework** - Save months building integrations
✅ **Vespa integration** - Vector search is hard
✅ **Document chunking** - Smart text splitting
✅ **LLM chat interface** - Clean chat UI
✅ **User management** - Auth system works
✅ **Credential encryption** - Security done right

### **What to REMOVE/SIMPLIFY:**

❌ **Multi-tenant features** - You're single-org
❌ **Enterprise SSO** - OAuth is enough
❌ **Federated search** - Don't need Bing/Kendra
❌ **Permission sync** - Can't get client admin access
❌ **9 Celery workers** - Use lightweight mode
❌ **Dask parallelization** - Overkill for your scale
❌ **Separate model servers** - Use OpenAI API

### **What to BUILD for Marketing:**

🔨 **Marketing-specific connectors:**
- Google Ads API connector
- Facebook Ads API connector
- LinkedIn Ads API connector
- HubSpot connector (enhance existing)
- Google Sheets connector (with formulas)

🔨 **Marketing-specific features:**
- Campaign performance dashboards
- Client report generation
- Competitive analysis tools
- ROI calculators

🔨 **Per-user connector model:**
- Remove admin-only restrictions
- Allow users to connect their own services
- Hybrid: Company shared + personal sources

---

## 🚀 Quick Start Commands

```bash
# 1. Navigate to docker directory
cd /home/user/knowsee-platform/deployment/docker_compose

# 2. Create .env file
cp .env.local-testing .env

# 3. Edit .env and add:
#    - OAUTH_GOOGLE_DRIVE_CLIENT_ID
#    - OAUTH_GOOGLE_DRIVE_CLIENT_SECRET
#    - GEN_AI_API_KEY (OpenAI)

# 4. Run the startup script
./run-local-prod.sh

# 5. Access at http://localhost:3000

# 6. View logs
docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml logs -f

# 7. Stop everything
docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml down
```

---

## 💡 Next Steps

1. **Test basic setup** - Get it running with minimal config
2. **Connect test user** - Use Linear connector first (simpler OAuth)
3. **Understand data flow** - Watch logs, see how indexing works
4. **Modify Google Drive** - Remove admin restriction
5. **Build custom connectors** - Add marketing-specific integrations
6. **Simplify deployment** - Create your own minimal docker-compose

---

## 📚 Key Files to Understand

```
# Essential files to read:
backend/onyx/connectors/interfaces.py          # How connectors work
backend/onyx/server/documents/standard_oauth.py # OAuth flow
backend/onyx/db/models.py                      # Database schema
web/src/app/admin/connectors/                  # Connector UI

# Over-engineered files you can ignore:
backend/onyx/background/celery/                # Too complex, use lightweight mode
backend/ee/                                    # Enterprise Edition (paid features)
deployment/kubernetes/                         # K8s deployment (overkill)
```

---

**Bottom Line:** Onyx has great bones (connector framework, vector search, LLM integration), but is over-engineered for single-org deployments. Start minimal, add complexity only when needed.
