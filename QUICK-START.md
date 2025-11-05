# Onyx Quick Start - Simplified Setup

**One Docker Compose. Three Environments. Zero Headaches.**

---

## 🎯 What You Have Now

I've simplified Onyx from **10 containers** down to **6 essential containers** with ONE docker-compose file that works everywhere.

### **Before (Original Onyx):**
```
docker-compose.yml
docker-compose.dev.yml
docker-compose.prod.yml
docker-compose.prod-no-letsencrypt.yml
docker-compose.prod-cloud.yml
docker-compose.multitenant-dev.yml
docker-compose.resources.yml
... and more
```

### **After (Simplified):**
```
docker-compose.simple.yml  ← ONE file
.env.development           ← Dev config
.env.staging               ← Staging config
.env.production            ← Prod config
```

---

## 🚀 Get Started in 3 Minutes

### **Step 1: Navigate to Docker directory**
```bash
cd deployment/docker_compose
```

### **Step 2: Start Onyx**
```bash
# Development (default)
./start.sh up

# Or specify environment
ENV=staging ./start.sh up
ENV=production ./start.sh up
```

### **Step 3: Access your instance**
```
🌐 Web UI:    http://localhost:3000
🔧 API:       http://localhost:8080
📊 Database:  localhost:5432
```

**That's it!** You're running Onyx.

---

## 📦 What's Running (6 Containers)

| Container | Purpose | Essential? | Can Remove? |
|-----------|---------|------------|-------------|
| **api** | Backend API | ✅ Yes | No |
| **worker** | Background jobs | ✅ Yes | No |
| **web** | Frontend UI | ✅ Yes | No |
| **postgres** | Database | ✅ Yes | No |
| **redis** | Cache/Queue | ✅ Yes | No |
| **vespa** | Vector search | ✅ Yes | Maybe¹ |
| **minio** | Object storage | ⚠️ Maybe | Yes² |

**Notes:**
1. Could use Pinecone/Weaviate instead (requires code changes)
2. Can use real S3 or local filesystem in production

---

## 🎮 Commands

```bash
# Start
./start.sh up

# Stop
./start.sh down

# Restart
./start.sh restart

# View logs
./start.sh logs              # All services
./start.sh logs api          # Specific service

# Check status
./start.sh status

# Rebuild
./start.sh build

# Clean up (deletes data!)
./start.sh clean
```

---

## 🔧 Configuration

### **Environment-Specific Settings**

Edit the appropriate `.env.*` file:

**Development** (`.env.development`):
- Auth disabled
- All ports exposed
- Debug logging
- Local MinIO

**Staging** (`.env.staging`):
- Auth enabled
- Internal ports only
- Info logging
- Can use real S3

**Production** (`.env.production`):
- Auth required
- Secure secrets
- Error logging only
- Real S3/managed Postgres

### **Common Settings to Change**

```bash
# OAuth Credentials (for connectors)
OAUTH_GOOGLE_DRIVE_CLIENT_ID=your-client-id
OAUTH_GOOGLE_DRIVE_CLIENT_SECRET=your-secret

# LLM API (OpenAI)
GEN_AI_API_KEY=sk-...

# Domain (for OAuth callbacks)
WEB_DOMAIN=https://your-domain.com

# Database (production)
POSTGRES_PASSWORD=strong-password-here
```

---

## 🔌 Adding Marketing Connectors with dlthub

### **What's dlthub?**
A Python library with 100+ pre-built connectors for marketing data sources.

### **Quick Example: Google Ads**

**1. Install dlthub:**
```bash
cd backend
source .venv/bin/activate
pip install dlt
```

**2. Use the connector:**
```python
from onyx.connectors.dlt_generic import GoogleAdsConnector

# Configure
connector = GoogleAdsConnector(
    customer_id="1234567890",
    resource_name="campaigns"  # or "ad_groups", "ads", etc.
)

# Load credentials
connector.load_credentials({
    "developer_token": "your-dev-token",
    "client_id": "your-client-id",
    "client_secret": "your-secret",
    "refresh_token": "your-refresh-token",
})

# Fetch and index data
for doc_batch in connector.load_from_state():
    # Onyx automatically indexes these documents
    print(f"Indexed {len(doc_batch)} documents")
```

**3. Register in Onyx:**
```python
# backend/onyx/connectors/registry.py
from onyx.connectors.dlt_generic import GoogleAdsConnector

CONNECTOR_CLASS_MAP[DocumentSource.GOOGLE_ADS] = ConnectorMapping(
    module_path="onyx.connectors.dlt_generic.connector",
    class_name="GoogleAdsConnector",
)
```

### **Available Marketing Sources via dlthub:**

✅ **Advertising:**
- Google Ads
- Facebook Ads
- LinkedIn Ads
- Microsoft Ads (Bing)

✅ **Analytics:**
- Google Analytics 4
- Google Search Console
- Matomo

✅ **CRM:**
- HubSpot
- Salesforce
- Pipedrive

✅ **E-commerce:**
- Shopify
- Stripe
- WooCommerce

✅ **Project Management:**
- Asana
- Monday.com
- Jira

**See all sources:** https://dlthub.com/docs/dlt-ecosystem/verified-sources

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                     User                            │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│                  Web (Next.js)                      │
│              http://localhost:3000                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│              API (FastAPI)                          │
│          http://localhost:8080                      │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │  Connectors  │  │     Chat     │               │
│  │   (OAuth)    │  │   (LLM AI)   │               │
│  └──────────────┘  └──────────────┘               │
└──────┬───────┬──────────┬──────────────────────────┘
       │       │          │
       ▼       ▼          ▼
  ┌────────┐ ┌────────┐ ┌────────┐
  │Postgres│ │ Redis  │ │ Vespa  │
  │  Data  │ │ Queue  │ │Search  │
  └────────┘ └────────┘ └────────┘
                   ▲
                   │
        ┌──────────┴──────────┐
        │  Background Worker  │
        │  (Celery - Unified) │
        └─────────────────────┘
```

---

## 🤔 FAQ

### **Q: Why not use the original docker-compose.prod.yml?**
**A:** It's over-engineered with:
- 9 separate worker containers (you need 1)
- Multiple model servers (you can use OpenAI API)
- Multi-tenant complexity (you don't need it)
- Nginx/Certbot (not needed for local/staging)

### **Q: What's different from the original?**
**A:**
- ✅ ONE docker-compose file (not 7)
- ✅ 6 containers (not 10)
- ✅ Unified worker (not 9 workers)
- ✅ Environment-based config (not file duplication)
- ✅ Clear documentation (not scattered across files)

### **Q: Can I use this in production?**
**A:** Yes, but add:
- SSL/TLS (nginx + Let's Encrypt)
- Managed Postgres (AWS RDS, Google Cloud SQL)
- Real S3 (not MinIO)
- Strong secrets in `.env.production`
- Monitoring (Sentry, Datadog, etc.)

### **Q: How do I add a new connector?**
**A:** Two ways:

**Easy way (dlthub):**
```python
from onyx.connectors.dlt_generic import DltGenericConnector

connector = DltGenericConnector(
    source_name="hubspot",  # or any dlthub source
    credentials={"api_key": "..."}
)
```

**Custom way:**
1. Create file in `backend/onyx/connectors/my_source/`
2. Extend `LoadConnector` or `PollConnector`
3. Implement `load_from_state()` method
4. Register in `registry.py`

See `backend/onyx/connectors/linear/` for example.

### **Q: Does this work on Mac/Windows/Linux?**
**A:** Yes! Docker handles cross-platform.

Requirements:
- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 8GB+ RAM
- 10GB+ disk space

---

## 🎯 Next Steps

### **1. Get Comfortable (Today)**
```bash
# Start it up
./start.sh up

# Watch the logs
./start.sh logs

# Access http://localhost:3000
# Create a user, explore the UI
```

### **2. Add OAuth Connector (This Week)**
```bash
# Edit .env.development
OAUTH_GOOGLE_DRIVE_CLIENT_ID=xxx
OAUTH_GOOGLE_DRIVE_CLIENT_SECRET=yyy

# Restart
./start.sh restart

# Connect your Google Drive in UI
```

### **3. Add Marketing Connector (Next Week)**
```bash
# Install dlt
pip install dlt

# Use DltGenericConnector for Google Ads/Facebook Ads
# See example above
```

### **4. Customize UI (Ongoing)**
- Remove enterprise features you don't need
- Add marketing-specific dashboards
- Build custom connectors

---

## 📚 Key Files You Created

| File | Purpose |
|------|---------|
| `docker-compose.simple.yml` | ONE file for all environments |
| `.env.development` | Dev settings |
| `.env.staging` | Staging settings |
| `.env.production` | Production settings |
| `start.sh` | Universal startup script |
| `backend/onyx/connectors/dlt_generic/` | dlthub connector wrapper |
| `DECISION-FRAMEWORK.md` | Should you stay or start fresh? |
| `ARCHITECTURE-BREAKDOWN.md` | What's essential vs over-engineered |

---

## 💪 You've Got This!

You now have:

✅ **Simplified Docker setup** (6 containers, not 10)
✅ **Environment-based config** (one docker-compose)
✅ **dlthub integration** (100+ marketing connectors)
✅ **Decision framework** (stay vs start fresh)
✅ **Architecture knowledge** (what's worth keeping)

**The learning curve is real, but you're past the steepest part.**

### **Two Paths Forward:**

**Path A: Build on Onyx** (Recommended)
- You have simplified setup
- dlthub makes connectors easy
- Focus on marketing features

**Path B: Start Fresh**
- You know what you need
- Build only essentials
- See `DECISION-FRAMEWORK.md`

**Either way, you're in a strong position.**

---

## 🆘 Getting Unstuck

**When Docker confuses you:**
```bash
# See what's running
docker ps

# See logs
./start.sh logs

# Nuclear option (fresh start)
./start.sh clean
./start.sh up
```

**When connectors confuse you:**
- Look at `backend/onyx/connectors/linear/` (simplest example)
- Use `DltGenericConnector` (handles most complexity)
- Ask yourself: "Do I really need Onyx's connector framework?"

**When you're overwhelmed:**
- Take a break
- Re-read `DECISION-FRAMEWORK.md`
- Remember: **Simplifying complexity is progress**

---

**You're doing great. Keep going.** 🚀
