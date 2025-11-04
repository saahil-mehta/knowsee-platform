# ARCHITECTURE VISUALIZATION

**Visual Textual Diagrams for Knowsee Platform Architecture**

This document provides swim-lane style visual diagrams that complement ARCH.md, making it easier to understand the system's runtime behavior, data flows, and component interactions at a glance.

---

## Table of Contents

1. [System-Level Architecture](#1-system-level-architecture)
2. [Request Flow Diagrams](#2-request-flow-diagrams)
3. [Data Flow Diagrams](#3-data-flow-diagrams)
4. [Component Interaction Maps](#4-component-interaction-maps)
5. [Deployment Topologies](#5-deployment-topologies)
6. [Multi-Tenant Architecture](#6-multi-tenant-architecture)
7. [Security & Auth Flows](#7-security--auth-flows)

---

## 1. System-Level Architecture

### 1.1 High-Level Component Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          KNOWSEE PLATFORM ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT TIER                                     │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                  │
│  │  Web Browser   │  │  Mobile App    │  │  API Clients   │                  │
│  │  (Next.js UI)  │  │  (Future)      │  │  (SDK/cURL)    │                  │
│  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘                  │
│           │                   │                   │                          │
│           └───────────────────┴───────────────────┘                          │
│                               │                                              │
│                               │ HTTPS/REST/SSE                               │
└───────────────────────────────┼──────────────────────────────────────────────┘
                                │
┌───────────────────────────────┼──────────────────────────────────────────────┐
│                              API GATEWAY TIER                                │
│                               │                                              │
│  ┌─────────────────────────────▼──────────────────────────────┐              │
│  │           Next.js Middleware (web/src/middleware.ts)        │             │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │                │
│  │  │ Auth Guard  │  │ Rate Limit  │  │ Tenant ID   │       │                │
│  │  │ (Cookies)   │  │ Middleware  │  │ Injection   │       │                │
│  │  └─────────────┘  └─────────────┘  └─────────────┘       │                │
│  └──────────────────────────┬──────────────────────────────────┘             │
│                             │                                                │
│  ┌──────────────────────────▼──────────────────────────────┐                 │
│  │         FastAPI Application (backend/onyx/main.py)      │                 │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │                 │
│  │  │ CORS     │  │ Request  │  │ Latency  │  │ Auth     │ │                 │
│  │  │ Middleware│  │ ID      │  │ Logging  │  │ Rate     │ │                 │
│  │  │          │  │ Injection│  │          │  │ Limiting │ │                 │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │                 │
│  │                                                         │                 │
│  │  ┌──────────────────────────────────────────────────┐   │                 │
│  │  │            API Routers                           │   │                 │
│  │  │  /chat | /manage | /query | /admin | /auth       │   │                 │
│  │  └──────────────────────────────────────────────────┘   │                 │
│  └─────────────────────────────────────────────────────────┘                 │
│                             │                                                │
└─────────────────────────────┼────────────────────────────────────────────────┘
                              │
                  ┌───────────┴────────────┐
                  │                        │
┌─────────────────▼───────┐   ┌───────────▼────────────┐
│   PERSISTENCE TIER      │   │  PROCESSING TIER       │
│                         │   │                        │
│  ┌──────────────────┐  │   │  ┌──────────────────┐  │
│  │   PostgreSQL     │  │   │  │  Celery Workers  │  │
│  │   (Metadata,     │  │   │  │  ┌────────────┐  │  │
│  │    Users,        │  │   │  │  │ Primary    │  │  │
│  │    Configs)      │  │   │  │  ├────────────┤  │  │
│  └──────────────────┘  │   │  │  │Docfetching │  │  │
│                        │   │  │  ├────────────┤  │  │
│  ┌──────────────────┐  │   │  │  │Docprocessing│ │  │
│  │   Redis          │  │   │  │  ├────────────┤  │  │
│  │   (Cache,        │  │   │  │  │ Light      │  │  │
│  │    Queues,       │  │   │  │  ├────────────┤  │  │
│  │    Fences)       │  │   │  │  │ Heavy      │  │  │
│  └──────────────────┘  │   │  │  ├────────────┤  │  │
│                        │   │  │  │ KG Proc    │  │  │
│  ┌──────────────────┐  │   │  │  ├────────────┤  │  │
│  │   Vespa          │  │   │  │  │ Monitoring │  │  │
│  │   (Vector DB,    │  │   │  │  ├────────────┤  │  │
│  │    Search)       │  │   │  │  │User Files  │  │  │
│  └──────────────────┘  │   │  │  ├────────────┤  │  │
│                        │   │  │  │ Beat       │  │  │
│  ┌──────────────────┐  │   │  │  └────────────┘  │  │
│  │ S3/MinIO/Local   │  │   │  └──────────────────┘  │
│  │ (File Store)     │  │   │                        │
│  └──────────────────┘  │   └────────────────────────┘
│                        │
└────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES TIER                          │
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ LLM Providers│  │  Connectors  │  │ Observability│           │
│  │              │  │              │  │              │           │
│  │ • OpenAI    │  │ • Google     │  │ • Sentry     │           │
│  │ • Anthropic │  │ • Slack      │  │ • Prometheus │           │
│  │ • Azure     │  │ • GitHub     │  │ • Braintrust │           │
│  │ • Ollama    │  │ • Confluence │  │ • Langfuse   │           │
│  │ • Custom    │  │ • SharePoint │  │              │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. Request Flow Diagrams

### 2.1 User Authentication Flow (OAuth)

```
┌─────────┐         ┌──────────┐        ┌──────────┐        ┌──────────┐
│ Browser │         │ Next.js  │        │ FastAPI  │        │  OAuth   │
│         │         │Middleware│        │  Auth    │        │ Provider │
└────┬────┘         └────┬─────┘        └────┬─────┘        └────┬─────┘
     │                   │                   │                   │
     │ 1. GET /auth/login│                   │                   │
     ├──────────────────►│                   │                   │
     │                   │                   │                   │
     │                   │ 2. Redirect to    │                   │
     │                   │    OAuth provider │                   │
     │                   ├──────────────────────────────────────►│
     │                   │                   │                   │
     │                   │                   │ 3. User consents  │
     │                   │                   │◄──────────────────┤
     │                   │                   │                   │
     │                   │ 4. OAuth callback │                   │
     │                   │   with auth code  │                   │
     │◄──────────────────┴───────────────────┤                   │
     │                                       │                   │
     │ 5. POST /api/auth/callback            │                   │
     ├──────────────────────────────────────►│                   │
     │                                       │                   │
     │                                       │ 6. Exchange code  │
     │                                       │   for tokens      │
     │                                       ├──────────────────►│
     │                                       │                   │
     │                                       │ 7. Access token   │
     │                                       │◄──────────────────┤
     │                                       │                   │
     │                                       │ 8. Store user in  │
     │                                       │    Postgres       │
     │                                       ├───┐               │
     │                                       │   │               │
     │                                       │◄──┘               │
     │                                       │                   │
     │ 9. Set session cookie (onyx_tid)      │                   │
     │◄──────────────────────────────────────┤                   │
     │                                       │                   │
     │ 10. Redirect to /chat                 │                   │
     │◄──────────────────────────────────────┤                   │
     │                                       │                   │
```

### 2.2 Chat Message Flow (Streaming Response)

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Browser │    │ Next.js  │    │ FastAPI  │    │Retrieval │    │   LLM    │    │  Vespa   │
│  Chat   │    │  API     │    │  Chat    │    │  Engine  │    │ Provider │    │  Index   │
│  UI     │    │ Proxy    │    │ Backend  │    │          │    │          │    │          │
└────┬────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │              │               │               │               │               │
     │ 1. User types message        │               │               │               │
     ├─────────────►│               │               │               │               │
     │              │               │               │               │               │
     │              │ 2. POST /chat/create-chat-message             │               │
     │              ├──────────────►│               │               │               │
     │              │               │               │               │               │
     │              │               │ 3. Persist message            │               │
     │              │               ├───┐           │               │               │
     │              │               │   │ Postgres  │               │               │
     │              │               │◄──┘           │               │               │
     │              │               │               │               │               │
     │              │               │ 4. Query for relevant docs    │               │
     │              │               ├──────────────►│               │               │
     │              │               │               │               │               │
     │              │               │               │ 5. Semantic search            │
     │              │               │               ├──────────────────────────────►│
     │              │               │               │               │               │
     │              │               │               │ 6. Results (chunks + scores)  │
     │              │               │               │◄──────────────────────────────┤
     │              │               │               │               │               │
     │              │               │ 7. Retrieved docs             │               │
     │              │               │◄──────────────┤               │               │
     │              │               │               │               │               │
     │              │               │ 8. Build prompt with context  │               │
     │              │               ├───┐           │               │               │
     │              │               │◄──┘           │               │               │
     │              │               │               │               │               │
     │              │               │ 9. Stream LLM request         │               │
     │              │               ├───────────────────────────────►│               │
     │              │               │               │               │               │
     │              │               │ 10. Stream response (SSE)     │               │
     │◄─────────────┴───────────────┼───────────────────────────────┤               │
     │                              │               │               │               │
     │ 11. UI updates in real-time  │               │               │               │
     │    (token by token)          │               │               │               │
     │                              │               │               │               │
     │                              │ 12. Mark complete, save       │               │
     │                              ├───┐           │               │               │
     │                              │   │ Postgres  │               │               │
     │                              │◄──┘           │               │               │
     │                              │               │               │               │
```

### 2.3 Connector Indexing Flow (Full Lifecycle)

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Admin UI │  │ FastAPI  │  │  Celery  │  │Connector │  │Embedding │  │  Vespa   │
│          │  │ Manage   │  │  Beat    │  │  Worker  │  │  Worker  │  │  Index   │
└────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │             │             │             │
     │ 1. Create connector        │             │             │             │
     ├────────────►│             │             │             │             │
     │             │             │             │             │             │
     │             │ 2. Save to DB             │             │             │
     │             ├───┐         │             │             │             │
     │             │   │Postgres │             │             │             │
     │             │◄──┘         │             │             │             │
     │             │             │             │             │             │
     │             │ 3. Trigger index task     │             │             │
     │             ├────────────►│             │             │             │
     │             │             │             │             │             │
     │             │             │ 4. Schedule docfetching   │             │
     │             │             ├────────────►│             │             │
     │             │             │             │             │             │
     │             │             │             │ 5. Fetch documents        │
     │             │             │             │    from source│            │
     │             │             │             ├───┐         │             │
     │             │             │             │   │ External│             │
     │             │             │             │◄──┘ API     │             │
     │             │             │             │             │             │
     │             │             │             │ 6. Batch documents        │
     │             │             │             │    & trigger processing   │
     │             │             │             ├────────────►│             │
     │             │             │             │             │             │
     │             │             │             │             │ 7. Chunk docs
     │             │             │             │             ├───┐         │
     │             │             │             │             │◄──┘         │
     │             │             │             │             │             │
     │             │             │             │             │ 8. Embed chunks
     │             │             │             │             ├───┐         │
     │             │             │             │             │   │ Model   │
     │             │             │             │             │◄──┘ Server  │
     │             │             │             │             │             │
     │             │             │             │             │ 9. Write to Vespa
     │             │             │             │             ├────────────►│
     │             │             │             │             │             │
     │             │             │             │             │ 10. Confirm │
     │             │             │             │             │◄────────────┤
     │             │             │             │             │             │
     │             │             │             │ 11. Update attempt status │
     │             │             │             │◄────────────┤             │
     │             │             │             │             │             │
     │             │             │             ├───┐         │             │
     │             │             │             │   │Postgres │             │
     │             │             │             │◄──┘         │             │
     │             │             │             │             │             │
     │ 12. Poll /indexing-status │             │             │             │
     ├────────────►│             │             │             │             │
     │             │             │             │             │             │
     │             │ 13. Return progress       │             │             │
     │◄────────────┤             │             │             │             │
     │             │             │             │             │             │
```

---

## 3. Data Flow Diagrams

### 3.1 Document Processing Pipeline

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      DOCUMENT PROCESSING PIPELINE                         │
└──────────────────────────────────────────────────────────────────────────┘

External Source                     Connector Worker
┌──────────────┐                   ┌─────────────────┐
│ Google Drive │                   │ 1. Fetch Docs   │
│   Slack      │──────────────────►│    - API calls  │
│   SharePoint │                   │    - OAuth flow │
│   GitHub     │                   │    - Rate limit │
└──────────────┘                   └────────┬────────┘
                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │ 2. Extract      │
                                   │    - Title      │
                                   │    - Content    │
                                   │    - Metadata   │
                                   │    - Permissions│
                                   └────────┬────────┘
                                            │
                                            ▼
                          ┌─────────────────┴─────────────────┐
                          │                                   │
                          ▼                                   ▼
                 ┌─────────────────┐               ┌─────────────────┐
                 │ 3a. Upsert to   │               │ 3b. Store Files │
                 │     Postgres    │               │     in S3/MinIO │
                 │  - Documents    │               │  - Binaries     │
                 │  - Metadata     │               │  - Large content│
                 │  - Permissions  │               │                 │
                 └─────────┬───────┘               └─────────┬───────┘
                           │                                 │
                           └─────────────┬───────────────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ 4. Chunking     │
                                │   - Split docs  │
                                │   - Context     │
                                │   - Overlaps    │
                                └────────┬────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ 5. Classification│
                                │   - ICC Model   │
                                │   - Boost scores│
                                │   - Importance  │
                                └────────┬────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ 6. Embedding    │
                                │   - Model Server│
                                │   - Cloud API   │
                                │   - Batching    │
                                └────────┬────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ 7. Write to     │
                                │    Vespa        │
                                │  - Vectors      │
                                │  - Metadata     │
                                │  - ACLs         │
                                └────────┬────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ 8. Update Status│
                                │    in Postgres  │
                                │  - Attempt      │
                                │  - Stats        │
                                └─────────────────┘
```

### 3.2 Multi-Tenant Data Isolation

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         MULTI-TENANT ARCHITECTURE                         │
└──────────────────────────────────────────────────────────────────────────┘

Incoming Request
       │
       ▼
┌─────────────────┐
│ Extract Tenant  │
│  - Cookie       │──── onyx_tid cookie
│  - Header       │──── X-Onyx-Tenant-ID header
│  - JWT claim    │──── tenant_id in token
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Set Context Var │
│ CURRENT_TENANT  │
│   _ID_CONTEXTVAR│
└────────┬────────┘
         │
         ├─────────────────────────────────────────────────────────┐
         │                                                         │
         ▼                                                         ▼
┌─────────────────────┐                              ┌─────────────────────┐
│ Postgres Session    │                              │ Redis Namespace     │
│ with Schema Map     │                              │   Isolation         │
│                     │                              │                     │
│ schema_translate_map│                              │ Key prefix:         │
│   {None: "tenant_a"}│                              │ "tenant_a:..."      │
│                     │                              │                     │
│ Tables appear in    │                              │ Locks, queues,      │
│ tenant_a schema:    │                              │ cache scoped        │
│  - tenant_a.user    │                              │ per tenant          │
│  - tenant_a.document│                              │                     │
└─────────────────────┘                              └─────────────────────┘
         │                                                         │
         └─────────────────────┬───────────────────────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │ Vespa Filtering │
                      │                 │
                      │ tenant_id field │
                      │ in all queries  │
                      │                 │
                      │ WHERE tenant_id │
                      │   = "tenant_a"  │
                      └─────────────────┘
```

### 3.3 Search & Retrieval Data Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      SEARCH & RETRIEVAL PIPELINE                          │
└──────────────────────────────────────────────────────────────────────────┘

User Query: "How do I deploy Kubernetes?"
       │
       ▼
┌─────────────────┐
│ Query Parser    │
│  - Intent       │
│  - Filters      │
│  - Persona ctx  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Build Search    │
│  Parameters     │
│  - Embedding    │
│  - BM25 query   │
│  - Filters (ACL)│
│  - Date range   │
└────────┬────────┘
         │
         ├─────────────────┬─────────────────┬─────────────────┐
         │                 │                 │                 │
         ▼                 ▼                 ▼                 ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Embed Query │  │ BM25 Query  │  │ KG Expansion│  │ Apply ACLs  │
│ (Async)     │  │ (Async)     │  │ (Async)     │  │             │
│             │  │             │  │             │  │ Filter by:  │
│ Model Server│  │ Vespa Text  │  │ Entity/     │  │ - user_id   │
│ or Cloud API│  │ Match       │  │ Relations   │  │ - groups    │
└─────┬───────┘  └─────┬───────┘  └─────┬───────┘  └─────┬───────┘
      │                │                │                │
      └────────────────┴────────────────┴────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Vespa Query     │
              │                 │
              │ YQL:            │
              │ select * from   │
              │ danswer_chunk   │
              │ where           │
              │  (semantic OR   │
              │   bm25 OR kg)   │
              │  AND acl        │
              │  AND filters    │
              │                 │
              │ Ranking:        │
              │  - Hybrid score │
              │  - Time decay   │
              │  - Boost factor │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Top-K Results   │
              │                 │
              │ 1. Doc A, ch 1  │
              │    score: 0.92  │
              │ 2. Doc B, ch 3  │
              │    score: 0.87  │
              │ 3. Doc A, ch 2  │
              │    score: 0.85  │
              │ ...             │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Optional        │
              │ Re-ranking      │
              │                 │
              │ Cross-encoder   │
              │ or LLM-based    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Fetch Full      │
              │ Metadata        │
              │                 │
              │ - Postgres      │
              │ - File store    │
              │ - Build context │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Return to LLM   │
              │ as Context      │
              └─────────────────┘
```

---

## 4. Component Interaction Maps

### 4.1 Celery Worker Topology

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          CELERY WORKER TOPOLOGY                           │
└──────────────────────────────────────────────────────────────────────────┘

                          Redis Broker
                       ┌─────────────────┐
                       │   Task Queues   │
                       │                 │
                       │ - celery        │
                       │ - celery_high   │
                       │ - celery_medium │
                       │ - celery_low    │
                       └────────┬────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  Beat Worker    │   │ Primary Worker  │   │ Light Worker    │
│                 │   │                 │   │                 │
│ Schedules:      │   │ Coordinates:    │   │ Handles:        │
│ - Indexing      │   │ - Conn delete   │   │ - Vespa ops     │
│ - Pruning       │   │ - Vespa sync    │   │ - Permissions   │
│ - KG updates    │   │ - Pruning coord │   │ - Fast tasks    │
│ - Monitoring    │   │ - Model updates │   │                 │
│                 │   │                 │   │ Concurrency: 20 │
│ Every 15-60s    │   │ Concurrency: 4  │   │                 │
└─────────────────┘   └─────────────────┘   └─────────────────┘

         ▼                      ▼                      ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ Docfetching     │   │ Docprocessing   │   │  Heavy Worker   │
│  Worker         │   │   Worker        │   │                 │
│                 │   │                 │   │ Handles:        │
│ Fetches docs    │   │ Processes docs  │   │ - Pruning ops   │
│ from sources:   │   │ Pipeline:       │   │ - Bulk deletes  │
│ - Google Drive  │   │ - Chunk         │   │ - Long tasks    │
│ - Slack         │   │ - Embed         │   │                 │
│ - GitHub        │   │ - Write Vespa   │   │ Concurrency: 4  │
│ - etc.          │   │                 │   │                 │
│                 │   │ Concurrency: cfg│   │                 │
│ Concurrency: cfg│   │                 │   │                 │
└─────────────────┘   └─────────────────┘   └─────────────────┘

         ▼                      ▼                      ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ KG Processing   │   │  Monitoring     │   │ User File Proc  │
│   Worker        │   │    Worker       │   │    Worker       │
│                 │   │                 │   │                 │
│ Handles:        │   │ Monitors:       │   │ Processes:      │
│ - Entity extract│   │ - Queue health  │   │ - User uploads  │
│ - Relationships │   │ - Memory usage  │   │ - Project files │
│ - Clustering    │   │ - Task latency  │   │ - Indexing      │
│                 │   │ - Alerts        │   │                 │
│ Concurrency: cfg│   │ Concurrency: 1  │   │ Concurrency: cfg│
└─────────────────┘   └─────────────────┘   └─────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  LIGHTWEIGHT MODE (USE_LIGHTWEIGHT_BACKGROUND_WORKER=true)     │
│                                                                │
│  All above workers → Single "background" worker                │
│  Concurrency: 20 threads (handles all task types)             │
└────────────────────────────────────────────────────────────────┘
```

### 4.2 LLM Provider Integration Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    LLM PROVIDER INTEGRATION LAYER                         │
└──────────────────────────────────────────────────────────────────────────┘

Chat Request
     │
     ▼
┌─────────────────────┐
│ Get LLM for Persona │
│                     │
│ 1. Check persona    │
│    overrides        │
│ 2. Fetch default    │
│    provider config  │
│ 3. Build LLM tuple  │
│   (main, fast)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐         ┌──────────────────────────────┐
│ DefaultMultiLLM     │         │   Provider Configurations    │
│                     │         │                              │
│ - Primary model     │◄────────┤ Postgres: llm_provider table │
│ - Fast model        │         │  - API keys                  │
│ - Fallback logic    │         │  - Base URLs                 │
│ - Timeout scaling   │         │  - Model mappings            │
│ - Temperature       │         │  - Custom headers            │
└──────────┬──────────┘         │  - Deployment names          │
           │                    └──────────────────────────────┘
           │
           ├──────────┬──────────┬──────────┬──────────┐
           │          │          │          │          │
           ▼          ▼          ▼          ▼          ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ OpenAI   │ │Anthropic │ │  Azure   │ │  Ollama  │ │  Custom  │
    │          │ │          │ │          │ │          │ │          │
    │ LiteLLM  │ │ LiteLLM  │ │ LiteLLM  │ │ LiteLLM  │ │  Direct  │
    │ Wrapper  │ │ Wrapper  │ │ Wrapper  │ │ Wrapper  │ │  Client  │
    └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
         │            │            │            │            │
         └────────────┴────────────┴────────────┴────────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │ Streaming       │
                          │ Response        │
                          │                 │
                          │ - Token deltas  │
                          │ - Tool calls    │
                          │ - Citations     │
                          │ - Error handling│
                          └─────────────────┘
```

### 4.3 Authentication & Authorization Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATION & AUTHORIZATION                          │
└──────────────────────────────────────────────────────────────────────────┘

HTTP Request
     │
     ▼
┌──────────────────┐
│ Extract Auth     │
│                  │
│ Sources:         │
│ - Cookie session │
│ - Bearer token   │
│ - API key        │
│ - SAML assertion │
└────────┬─────────┘
         │
         ├────────────┬────────────┬────────────┐
         │            │            │            │
         ▼            ▼            ▼            ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Cookie      │ │ JWT/Bearer  │ │  API Key    │ │    SAML     │
│ Session     │ │   Token     │ │             │ │             │
│             │ │             │ │             │ │             │
│ FastAPI-    │ │ Verify      │ │ Lookup in   │ │ Verify      │
│ Users       │ │ signature   │ │ database    │ │ signature   │
│ backend     │ │             │ │             │ │             │
└─────┬───────┘ └─────┬───────┘ └─────┬───────┘ └─────┬───────┘
      │               │               │               │
      └───────────────┴───────────────┴───────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ Load User     │
              │ from Postgres │
              │               │
              │ - user record │
              │ - role        │
              │ - groups      │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ RBAC Check    │
              │               │
              │ Roles:        │
              │ - ADMIN       │
              │ - CURATOR     │
              │ - BASIC       │
              │               │
              │ Depends():    │
              │ - current_user│
              │ - admin_user  │
              │ - curator_user│
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Permission    │
              │ Resolution    │
              │               │
              │ - Document ACL│
              │ - Group access│
              │ - Persona perm│
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Set Context   │
              │ Variables     │
              │               │
              │ - user_id     │
              │ - tenant_id   │
              │ - permissions │
              └───────────────┘
```

---

## 5. Deployment Topologies

### 5.1 Docker Compose Deployment (Development/Small Production)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         DOCKER COMPOSE TOPOLOGY                           │
└──────────────────────────────────────────────────────────────────────────┘

Docker Host Machine
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    knowsee-network (bridge)                   │    │
│  │                                                                │    │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │    │
│  │  │ knowsee-nginx  │  │ knowsee-web    │  │ knowsee-api    │ │    │
│  │  │                │  │                │  │                │ │    │
│  │  │ Nginx          │  │ Next.js        │  │ FastAPI        │ │    │
│  │  │ Port: 80, 443  │  │ Port: 3000     │  │ Port: 8080     │ │    │
│  │  └───────┬────────┘  └───────┬────────┘  └───────┬────────┘ │    │
│  │          │                   │                   │           │    │
│  │          └───────────────────┴───────────────────┘           │    │
│  │                              │                               │    │
│  │  ┌───────────────────────────┼─────────────────────────┐    │    │
│  │  │                           │                         │    │    │
│  │  ▼                           ▼                         ▼    │    │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐│    │
│  │  │ knowsee-       │  │ knowsee-redis  │  │ knowsee-vespa  ││    │
│  │  │ postgres       │  │                │  │                ││    │
│  │  │                │  │ Port: 6379     │  │ Port: 8081     ││    │
│  │  │ Port: 5432     │  │                │  │                ││    │
│  │  └────────────────┘  └────────────────┘  └────────────────┘│    │
│  │                                                              │    │
│  │  ┌───────────────────────────────────────────────────────┐ │    │
│  │  │             Celery Workers                             │ │    │
│  │  │                                                         │ │    │
│  │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │ │    │
│  │  │ │ knowsee- │ │ knowsee- │ │ knowsee- │ │ knowsee- │  │ │    │
│  │  │ │ primary  │ │ light    │ │ heavy    │ │ beat     │  │ │    │
│  │  │ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │ │    │
│  │  │                                                         │ │    │
│  │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │ │    │
│  │  │ │ knowsee- │ │ knowsee- │ │ knowsee- │ │ knowsee- │  │ │    │
│  │  │ │ docfetch │ │ docproc  │ │ kg_proc  │ │ monitor  │  │ │    │
│  │  │ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │ │    │
│  │  └───────────────────────────────────────────────────────┘ │    │
│  │                                                              │    │
│  │  ┌────────────────┐  ┌────────────────┐                    │    │
│  │  │ knowsee-       │  │ knowsee-minio  │                    │    │
│  │  │ model-server   │  │ (S3-compatible)│                    │    │
│  │  │                │  │                │                    │    │
│  │  │ Port: 9000     │  │ Port: 9000     │                    │    │
│  │  └────────────────┘  └────────────────┘                    │    │
│  │                                                              │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  Volumes:                                                             │
│  - knowsee_postgres_data                                              │
│  - knowsee_vespa_data                                                 │
│  - knowsee_minio_data                                                 │
│  - knowsee_redis_data                                                 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Kubernetes Deployment (Production)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      KUBERNETES DEPLOYMENT TOPOLOGY                       │
└──────────────────────────────────────────────────────────────────────────┘

Kubernetes Cluster
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│  Namespace: knowsee                                                    │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                         Ingress                               │    │
│  │  ┌────────────────────────────────────────────────────┐      │    │
│  │  │  Nginx Ingress Controller / ALB                    │      │    │
│  │  │  - TLS termination                                 │      │    │
│  │  │  - Path routing                                     │      │    │
│  │  │  - Rate limiting                                    │      │    │
│  │  └────────┬───────────────────────────────────────────┘      │    │
│  └───────────┼────────────────────────────────────────────────────┘    │
│              │                                                        │
│  ┌───────────┼────────────────────────────────────────────────────┐    │
│  │           │            Services                                 │    │
│  │           │                                                     │    │
│  │  ┌────────▼──────────┐  ┌────────────────┐  ┌────────────────┐│    │
│  │  │ knowsee-webserver │  │ knowsee-api    │  │ knowsee-model  ││    │
│  │  │ Service           │  │ Service        │  │ Service        ││    │
│  │  │ ClusterIP         │  │ ClusterIP      │  │ ClusterIP      ││    │
│  │  │ Port: 3000        │  │ Port: 8080     │  │ Port: 9000     ││    │
│  │  └────────┬──────────┘  └────────┬───────┘  └────────┬───────┘│    │
│  └───────────┼──────────────────────┼──────────────────┼──────────┘    │
│              │                      │                  │               │
│  ┌───────────▼──────────────────────▼──────────────────▼──────────┐    │
│  │                         Deployments                             │    │
│  │                                                                 │    │
│  │  ┌────────────────────────────────────────────────────────┐   │    │
│  │  │ knowsee-webserver Deployment (replicas: 3)             │   │    │
│  │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐                │   │    │
│  │  │ │ Pod 1    │ │ Pod 2    │ │ Pod 3    │                │   │    │
│  │  │ │ Next.js  │ │ Next.js  │ │ Next.js  │                │   │    │
│  │  │ └──────────┘ └──────────┘ └──────────┘                │   │    │
│  │  └────────────────────────────────────────────────────────┘   │    │
│  │                                                                 │    │
│  │  ┌────────────────────────────────────────────────────────┐   │    │
│  │  │ knowsee-api Deployment (replicas: 5)                   │   │    │
│  │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ...            │   │    │
│  │  │ │ Pod 1    │ │ Pod 2    │ │ Pod 3    │                │   │    │
│  │  │ │ FastAPI  │ │ FastAPI  │ │ FastAPI  │                │   │    │
│  │  │ └──────────┘ └──────────┘ └──────────┘                │   │    │
│  │  └────────────────────────────────────────────────────────┘   │    │
│  │                                                                 │    │
│  │  ┌────────────────────────────────────────────────────────┐   │    │
│  │  │ Celery Worker Deployments                              │   │    │
│  │  │                                                          │   │    │
│  │  │ - knowsee-primary (replicas: 2)                        │   │    │
│  │  │ - knowsee-docfetching (replicas: 3)                    │   │    │
│  │  │ - knowsee-docprocessing (replicas: 5)                  │   │    │
│  │  │ - knowsee-light (replicas: 3)                          │   │    │
│  │  │ - knowsee-heavy (replicas: 2)                          │   │    │
│  │  │ - knowsee-kg-processing (replicas: 2)                  │   │    │
│  │  │ - knowsee-monitoring (replicas: 1)                     │   │    │
│  │  │ - knowsee-beat (replicas: 1)                           │   │    │
│  │  └────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    StatefulSets / External Services           │    │
│  │                                                                │    │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │    │
│  │  │ Postgres       │  │ Redis          │  │ Vespa          │ │    │
│  │  │ (RDS/Cloud SQL)│  │ (ElastiCache)  │  │ (StatefulSet)  │ │    │
│  │  │ External       │  │ External       │  │ PVC-backed     │ │    │
│  │  └────────────────┘  └────────────────┘  └────────────────┘ │    │
│  │                                                                │    │
│  │  ┌────────────────┐                                           │    │
│  │  │ S3 / GCS       │                                           │    │
│  │  │ (File Store)   │                                           │    │
│  │  │ External       │                                           │    │
│  │  └────────────────┘                                           │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                      ConfigMaps & Secrets                     │    │
│  │                                                                │    │
│  │  - knowsee-config                                             │    │
│  │  - knowsee-secrets (API keys, DB credentials)                 │    │
│  │  - knowsee-llm-config                                         │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                      HorizontalPodAutoscalers                 │    │
│  │                                                                │    │
│  │  - knowsee-api-hpa (target CPU: 70%)                          │    │
│  │  - knowsee-docprocessing-hpa (target CPU: 80%)                │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Multi-Tenant Architecture

### 6.1 Tenant Isolation Mechanisms

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      MULTI-TENANT ISOLATION LAYERS                        │
└──────────────────────────────────────────────────────────────────────────┘

Request arrives with tenant_id: "acme_corp"
                │
                ▼
        ┌───────────────┐
        │ 1. Entry Point│
        │               │
        │ - Cookie:     │
        │   onyx_tid    │
        │ - Header:     │
        │   X-Onyx-     │
        │   Tenant-ID   │
        └───────┬───────┘
                │
                ▼
        ┌───────────────┐
        │ 2. Context Var│
        │               │
        │ CURRENT_TENANT│
        │ _ID_CONTEXTVAR│
        │ = "acme_corp" │
        └───────┬───────┘
                │
        ┌───────┴─────────────────────────────────┐
        │                                         │
        ▼                                         ▼
┌───────────────────┐                   ┌───────────────────┐
│ 3a. Database      │                   │ 3b. Redis         │
│     Isolation     │                   │     Isolation     │
│                   │                   │                   │
│ Schema Mapping:   │                   │ Key Prefixing:    │
│                   │                   │                   │
│ SQLAlchemy        │                   │ All keys:         │
│ execution_options │                   │ "acme_corp:..."   │
│ schema_translate_ │                   │                   │
│ map = {           │                   │ Examples:         │
│   None:           │                   │ - acme_corp:      │
│   "acme_corp"     │                   │   kv_store:...    │
│ }                 │                   │ - acme_corp:      │
│                   │                   │   da_lock:...     │
│ Tables appear as: │                   │ - acme_corp:      │
│ acme_corp.user    │                   │   signal:...      │
│ acme_corp.document│                   │                   │
│ acme_corp.chat_   │                   │ Tenant-specific   │
│   session         │                   │ Redis namespace   │
└───────────────────┘                   └───────────────────┘
        │                                         │
        └─────────────────┬───────────────────────┘
                          │
                          ▼
                ┌───────────────────┐
                │ 3c. Vespa         │
                │     Isolation     │
                │                   │
                │ Query Filter:     │
                │                   │
                │ WHERE tenant_id = │
                │   "acme_corp"     │
                │                   │
                │ All documents     │
                │ tagged with       │
                │ tenant_id field   │
                │                   │
                │ Search results    │
                │ automatically     │
                │ filtered          │
                └───────────────────┘
                          │
                          ▼
                ┌───────────────────┐
                │ 3d. File Store    │
                │     Isolation     │
                │                   │
                │ Path Prefixing:   │
                │                   │
                │ s3://bucket/      │
                │   acme_corp/      │
                │   documents/...   │
                │                   │
                │ IAM policies or   │
                │ bucket policies   │
                │ per tenant        │
                └───────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                         TENANT LIFECYCLE                                  │
│                                                                          │
│  1. Tenant Creation                                                      │
│     - Create schema in Postgres (CREATE SCHEMA acme_corp)                │
│     - Run tenant-specific migrations (alembic_tenants)                   │
│     - Set up Redis namespace                                             │
│     - Configure tenant_id in all new records                             │
│                                                                          │
│  2. Tenant Operations                                                    │
│     - All queries automatically scoped                                   │
│     - No cross-tenant data leakage                                       │
│     - Separate rate limits per tenant                                    │
│                                                                          │
│  3. Tenant Deletion                                                      │
│     - Drop schema (DROP SCHEMA acme_corp CASCADE)                        │
│     - Clear Redis keys (DEL acme_corp:*)                                 │
│     - Remove Vespa documents (DELETE WHERE tenant_id = 'acme_corp')      │
│     - Delete S3 objects (rm -r s3://bucket/acme_corp/)                   │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Security & Auth Flows

### 7.1 API Key Authentication Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       API KEY AUTHENTICATION FLOW                         │
└──────────────────────────────────────────────────────────────────────────┘

API Client
     │
     │ 1. Request with API key
     │    Header: X-Onyx-Authorization: API_KEY__abc123...
     │
     ▼
┌─────────────────────┐
│ FastAPI Middleware  │
│                     │
│ Extract header:     │
│ X-Onyx-Authorization│
└──────────┬──────────┘
           │
           │ 2. Validate format
           │    (starts with API_KEY__)
           ▼
┌─────────────────────┐
│ Hash API key        │
│                     │
│ SHA256(api_key)     │
└──────────┬──────────┘
           │
           │ 3. Lookup in database
           ▼
┌─────────────────────┐
│ Postgres Query      │
│                     │
│ SELECT user_id      │
│ FROM api_key        │
│ WHERE api_key_hash  │
│   = <hash>          │
│ AND is_active=true  │
└──────────┬──────────┘
           │
           ├─────────┬─────────┐
           │         │         │
           ▼         ▼         ▼
      ┌────────┐ ┌────────┐ ┌─────────┐
      │ Found  │ │ Expired│ │Not Found│
      └───┬────┘ └───┬────┘ └────┬────┘
          │          │           │
          │          │           │
          │          ▼           ▼
          │    ┌─────────────────────┐
          │    │ 401 Unauthorized    │
          │    │                     │
          │    │ Invalid or expired  │
          │    │ API key             │
          │    └─────────────────────┘
          │
          │ 4. Load user & tenant
          ▼
┌─────────────────────┐
│ Load User Record    │
│                     │
│ - user_id           │
│ - tenant_id         │
│ - role (from API    │
│   key record)       │
└──────────┬──────────┘
           │
           │ 5. Set context vars
           ▼
┌─────────────────────┐
│ Context Variables   │
│                     │
│ CURRENT_USER_ID     │
│ CURRENT_TENANT_ID   │
│ CURRENT_USER_ROLE   │
└──────────┬──────────┘
           │
           │ 6. Proceed to endpoint
           ▼
┌─────────────────────┐
│ API Endpoint        │
│                     │
│ with user context   │
│ and permissions     │
└─────────────────────┘
```

### 7.2 Document Access Control Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    DOCUMENT ACCESS CONTROL (ACL)                          │
└──────────────────────────────────────────────────────────────────────────┘

User searches: "engineering roadmap"
           │
           │ 1. User authenticated
           ▼
┌─────────────────────┐
│ Resolve User        │
│ Permissions         │
│                     │
│ - user_id           │
│ - groups[]          │
│ - is_admin          │
└──────────┬──────────┘
           │
           │ 2. Build ACL filter
           ▼
┌─────────────────────────────────────────────────────┐
│ Construct Vespa Query Filter                        │
│                                                     │
│ (                                                   │
│   access_control_list contains "user_123"          │
│   OR                                                │
│   access_control_list contains "group_eng"         │
│   OR                                                │
│   access_control_list contains "group_product"     │
│   OR                                                │
│   is_public = true                                  │
│   OR                                                │
│   user_is_admin = true                              │
│ )                                                   │
│ AND tenant_id = "acme_corp"                         │
└───────────────────────┬─────────────────────────────┘
                        │
                        │ 3. Execute search
                        ▼
              ┌───────────────────┐
              │ Vespa Query       │
              │                   │
              │ SELECT * FROM     │
              │ danswer_chunk     │
              │ WHERE             │
              │   <semantic match>│
              │   AND <ACL filter>│
              │ RANK BY hybrid    │
              └────────┬──────────┘
                       │
                       │ 4. Results (only accessible docs)
                       ▼
              ┌───────────────────┐
              │ Filtered Results  │
              │                   │
              │ ✓ Doc A (public)  │
              │ ✓ Doc B (eng group│
              │ ✗ Doc C (blocked) │
              │ ✓ Doc D (user_123)│
              └────────┬──────────┘
                       │
                       │ 5. Return to user
                       ▼
              ┌───────────────────┐
              │ Chat Response     │
              │ with Citations    │
              │                   │
              │ Only shows docs   │
              │ user can access   │
              └───────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                     ACL UPDATE FLOW (Permissions Sync)                    │
│                                                                          │
│  1. Connector fetches document with permissions                          │
│     - Google Drive: shared with users/groups                             │
│     - Slack: channel membership                                          │
│     - Confluence: space/page restrictions                                │
│                                                                          │
│  2. Normalize to ACL format                                              │
│     acl_list = [                                                         │
│       "user:alice@acme.com",                                             │
│       "group:engineering",                                               │
│       "group:everyone"                                                   │
│     ]                                                                    │
│                                                                          │
│  3. Store in Postgres (document.access_control_list)                     │
│                                                                          │
│  4. Sync to Vespa (access_control_list field in chunks)                  │
│                                                                          │
│  5. Permissions sync task (light worker)                                 │
│     - Runs periodically                                                  │
│     - Fetches updated permissions from source                            │
│     - Updates Vespa index                                                │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Visual Legend

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              DIAGRAM LEGEND                               │
└──────────────────────────────────────────────────────────────────────────┘

Components:
  ┌────────────┐
  │ Component  │  = Service, container, or logical module
  └────────────┘

Data Flow:
  ─────────────►  = Synchronous request/response
  ············►  = Asynchronous message/event
  ═════════════►  = Data stream (SSE, websocket)

Relationships:
  │  = Hierarchy or ownership
  ├  = Branch in flow
  └  = Terminal branch

States:
  ✓  = Success/allowed
  ✗  = Failure/denied
  ⚠  = Warning/conditional

Priorities:
  HIGH    = User-facing, breaking change
  MEDIUM  = Configuration, visible but not breaking
  LOW     = Internal, minimal user impact
```

---

## Appendix: Key File References

All visual diagrams map to specific implementation files referenced in ARCH.md Section 3 (Repository Tree). Here are the most critical mappings:

| Diagram Element | Implementation File(s) |
|----------------|------------------------|
| Request ID Middleware | `backend/onyx/utils/middleware.py` |
| Multi-tenant Context | `backend/shared_configs/contextvars.py` |
| FastAPI Main App | `backend/onyx/main.py` |
| Celery Worker Apps | `backend/onyx/background/celery/apps/*` |
| Chat Processing | `backend/onyx/chat/process_message.py` |
| Indexing Pipeline | `backend/onyx/indexing/indexing_pipeline.py` |
| Connector Factory | `backend/onyx/connectors/factory.py` |
| LLM Factory | `backend/onyx/llm/factory.py` |
| Vespa Client | `backend/onyx/document_index/vespa/index.py` |
| Auth Backends | `backend/onyx/auth/users.py` |
| Database Models | `backend/onyx/db/models.py` |
| Redis Utilities | `backend/onyx/redis/*` |
| Next.js Middleware | `web/src/middleware.ts` |
| Chat UI | `web/src/app/chat/*` |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-31
**Corresponds to:** ARCH.md (October 31, 2025 snapshot)
**Purpose:** Visual complement to architectural documentation for rapid system comprehension
