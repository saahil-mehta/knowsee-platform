# ARCHITECTURE MANUAL

This document captures the full-stack behavior of the repository in three complementary views:

1. **Detailed Workflow & Process Diagram** – exhaustive, swim-lane style walkthroughs of every major runtime path.
2. **Abstracted Architecture Overview** – system-level block diagram for rapid orientation.
3. **Repository Tree with Commentary** – annotated file map so that every artifact is identifiable at a glance.

All descriptions reflect the code as checked in on **October 31, 2025**.

---

## 1. Detailed Workflow & Process Diagram

The following textual diagrams describe the end-to-end lifecycle for core scenarios. Swim-lanes are ordered left-to-right from user experience to infrastructure layers; indentation indicates synchronous call chains, while numbered bullets show temporal order. Every node references the concrete module(s) that implement it.

### 1.1 Boot, Configuration, and Multi-Tenant Scaffolding

```
Lane: Runtime Shell / Supervisord
  1. Launch entrypoints defined in deployment scripts (e.g., backend/supervisord.conf, deployment/docker_compose/*).
     -> Spawns FastAPI (`backend/onyx/main.py`), Celery workers (`backend/onyx/background/celery/apps/*`), Vespa, Redis, Postgres, model server.

Lane: FastAPI Application (backend/onyx/main.py)
  2. Imports shared configuration from `backend/onyx/configs/*` and `backend/shared_configs/configs.py`.
     -> Applies environment toggles (AUTH_TYPE, USE_LIGHTWEIGHT_BACKGROUND_WORKER, MULTI_TENANT, etc.).
  3. Initializes logging via `onyx.utils.logger.setup_logger`, attaches Prometheus instrumentation (Instrumentator) and Sentry (if `SENTRY_DSN`).
  4. Registers middleware stack:
       - CORS (`fastapi.middleware.cors.CORSMiddleware`) – allowed origins from `shared_configs`.
       - Request ID injection (`onyx.utils.middleware.add_onyx_request_id_middleware`).
       - Optional latency logging (`onyx.server.middleware.latency_logging`).
       - Auth rate limiting (if enabled) via `onyx.server.middleware.rate_limiting`.
  5. Configures FastAPI-Users routers (`onyx.auth.users.fastapi_users`) for session, OAuth, and API key auth.
  6. Includes versioned API routers (chat, documents, personas, connectors, admin routes) with global prefix `APP_API_PREFIX`.
  7. Lifespan events (`lifespan()` in main.py):
       - Seed tenant metadata using `onyx.setup.setup_onyx` / `setup_multitenant_onyx`.
       - Warm Postgres connection pools (`onyx.db.engine.connection_warmup`).
       - Prepare default file store (S3/MinIO/local) via `onyx.file_store.file_store.get_default_file_store`.

Lane: Celery Workers (backend/onyx/background/celery/apps/*)
  8. For each worker profile (primary, docfetching, docprocessing, light, heavy, kg_processing, monitoring, user_file_processing, beat):
       - Load base configuration in `apps/app_base.py`.
       - Attach Sentry via `memory_monitoring.emit_process_memory` and custom `task_prerun` loggers.
       - Register task modules under `backend/onyx/background/celery/tasks/*`.

Lane: Frontend (web/src/app/layout.tsx, web/src/app/providers.tsx)
  9. Next.js 15 App Router bootstraps root layout:
       - Injects global providers (SWR config, Theme, Zustand stores).
       - Loads environment from `/env.mjs` and `web/src/lib/constants.ts`.
 10. On server-side render, middleware (`web/src/middleware.ts`) enforces auth redirects based on cookies and NextAuth integration.
```

### 1.2 Identity, Authorization, and Session Guardrails

```
Lane: Browser + Next.js Auth Pages (web/src/app/auth/*, web/src/app/anonymous/*)
  1. User requests login route -> server components fetch `/api/manage/users/self` to detect session.
  2. Auth forms invoke `web/src/lib/auth/*` utilities (FastAPI Users-compatible) to POST credentials or SSO callbacks.

Lane: API (backend/onyx/server/manage/users.py & auth routers)
  3. Requests flow through OAuth providers (`httpx_oauth.clients.*`), SAML (`backend/onyx/server/saml.py`), or password endpoints.
  4. `onyx.auth.users.auth_backend` issues JWT / cookie tokens, persisted in Redis-backed session storage if configured.
  5. Role resolution (`backend/onyx/access`) ensures RBAC (admin, curator, basic) for each API route.

Lane: Persistence
  6. User records stored via SQLAlchemy models (`backend/onyx/db/models.py`) in Postgres.
  7. OAuth token secrets encrypted & stored via `onyx.key_value_store` (KV providers: Redis, Postgres, Secrets Manager).
```

### 1.3 Connector Provisioning & Indexing Trigger (Detailed Swim-Lane)

```
Lane: Web UI (web/src/app/connector/*, web/src/lib/connectors/*.tsx)
  1. User navigates to `/connector` management UI.
  2. UI loads `SOURCE_METADATA_MAP` + `connectorConfigs` (web/src/lib/sources.ts & web/src/lib/connectors/connectors.tsx) to render dynamic forms.
  3. Credential creation:
       - Form submission goes through `web/src/lib/credential.ts` -> fetch helper (`web/src/lib/fetcher.ts`) -> POST `/manage/credential`.
       - OAuth connectors open popups using `web/src/lib/googleConnector.ts` to call `/manage/connector/google-drive/app-credential` etc.
  4. Connector creation:
       - UI sends POST `/manage/connector` with connector metadata, frequency, scheduling options.
  5. UI polls `/manage/connector/indexing-status` (via SWR hooks) to display progress.

Lane: FastAPI Documents Service (backend/onyx/server/documents/*.py)
  6. `/manage/connector` endpoint:
       - Validates tenant & role (Depends `current_admin_user` or `current_curator_or_admin_user`).
       - Persists connector via `onyx.db.connector.create_connector`, creating DB records in `connector`, `credential`, `connector_credential_pair`.
       - Optionally calls provider-specific validators (e.g., Google service account checks in `backend/onyx/connectors/google_utils`).
       - Emits telemetry milestones (`create_milestone_and_report` with `MilestoneRecordType.CONNECTOR_CREATED`).
  7. Index trigger:
       - `mark_ccpair_with_indexing_trigger` flips flags so beat worker enqueues tasks.
       - For immediate runs, `client_app.send_task(OnyxCeleryTask.CONNECTOR_INDEXING)` pushes to Celery queue with cc_pair_id, priority.
  8. File uploads (File connector):
       - `/manage/connector/upload` handles `UploadFile`, stores binary via `onyx.file_store.file_store` and attaches metadata.

Lane: Celery — Primary + Docfetching Workers
  9. Beat worker (`tasks/periodic/beat_schedule.py`) schedules `OnyxCeleryTask.CONNECTOR_INDEXING`.
 10. Primary worker (`tasks/docfetching/tasks.py:docfetching_task`) validates the `IndexAttempt` fence, ensures no deletions in flight.
 11. A new process is spawned via `SimpleJobClient` to run `run_docfetching_entrypoint` (`backend/onyx/background/indexing/run_docfetching.py`).

Lane: Connector Runtime (backend/onyx/connectors/*)
 12. `run_docfetching_entrypoint` creates connector instance using `onyx.connectors.factory.get_connector`.
 13. Connector types:
       - Load connectors implement `load_from_state` to fetch entire corpus.
       - Poll connectors implement `poll_source` for incremental updates.
       - Slim connectors fetch only identifiers for pruning.
       - Event connectors (future support) push updates via webhooks.
 14. Connector emits `Document` objects (defined in `onyx.connectors.models`) containing sections, metadata, permissions.
 15. Documents persisted to staging: stored in Postgres via `onyx.db.document.upsert_document_by_connector_credential_pair`.

Lane: Docprocessing Worker
 16. `tasks/docprocessing/tasks.py` receives batches; uses `ConnectorIndexingLogBuilder` to log progress.
 17. `onyx.indexing.indexing_pipeline` executes for each batch:
       a. Deduplicates documents (`upsert_documents`) and tags (`upsert_document_tags`).
       b. Splits documents with `Chunker` (`onyx.indexing.chunker.Chunker`).
       c. Optional summarization:
             - Document summary (`DOCUMENT_SUMMARY_PROMPT`) via `get_default_llm_with_vision`.
             - Chunk summary & info content classification (`InformationContentClassificationModel`).
       d. Embeds chunks through `embed_chunks_with_failure_handling` (LiteLLM providers or local model server).
       e. Writes chunks to Vespa (`write_chunks_to_vector_db_with_backoff` leveraging `onyx.document_index.vespa`).
       f. Uploads large binaries to file store (S3/MinIO/local) using `onyx.file_store`.
       g. Records attempt metrics in Postgres (`onyx.db.index_attempt`).
 18. `IndexingCoordination` releases fences; success/failure statuses propagate back to API for UI polling.

Lane: Downstream Maintenance
 19. `tasks/pruning/*` compare connector's slim poll responses against current DB to remove stale docs.
 20. `tasks/kg_processing/*` enrich graph relationships, updating `onyx.kg` tables.
 21. `tasks/monitoring/*` emit health stats to logs/Prometheus.
 22. `tasks/llm_model_update` refreshes cached LLM configs, `tasks/user_file_processing` indexes user uploads, `tasks/vespa` handle schema upgrades.
```

### 1.4 Chat, Query, and Retrieval Workflow

```
Lane: Web Chat Client (web/src/app/chat/*)
  1. Chat page (`page.tsx`) loads session list via `useChatSessionController` (GET `/chat/get-user-chat-sessions`).
  2. On new message:
       - `useChatController` constructs payload with persona overrides, streaming flags, attachments.
       - Sends POST `/chat/create-chat-message` using `fetcher.ts`.

Lane: FastAPI Chat Router (backend/onyx/server/query_and_chat/chat_backend.py)
  3. Dependency injection resolves:
       - Tenant context via `shared_configs.contextvars`.
       - DB session (`get_session` / `get_session_with_tenant`).
       - User persona from Postgres (`onyx.db.persona`).
  4. Pre-processing:
       - Reserve message ID (`onyx.db.chat.reserve_message_id`).
       - Persist initial message via `create_new_chat_message`.
       - Attach uploaded files using `onyx.file_store.utils`.
  5. Streaming pipeline:
       - Builds `ChatTurnDependencies` and `create_chat_chain` (which configures retrieval, LLM, tool stack).
       - Wraps generator `stream_chat_message` in `StreamingResponse`, streaming SSE/JSON packets (`chat_backend.Packet`).

Lane: Retrieval Orchestration (backend/onyx/chat/process_message.py)
  6. Constructs `AnswerPromptBuilder` with persona instructions, project context, and tool configs.
  7. Optional Deep Research:
       - If persona demands, `onyx.tools.tool_constructor` activates `WebSearchTool` and `SearchTool`.
       - Tool calls mediated via `onyx.tools.tool` + `onyx.tools.force`.
  8. Retrieval steps:
       a. Determine search settings from DB (`onyx.db.search_settings`).
       b. Query Vespa via `onyx.document_index.factory.get_default_document_index`.
       c. Apply KG augmentations (`onyx.context.search.retrieval.search_runner`).
       d. Fetch file snippets & metadata from Postgres, file store.
  9. Token management & rate limiting enforced by:
       - `onyx.server.query_and_chat.token_limit` (per-tenant/per-user budgets).
       - `onyx.server.token_rate_limits` for admin overrides.
 10. LLM execution:
       - `onyx.llm.factory.get_llms_for_persona` returns main + fallback models (LiteLLM settings defined in configs).
       - Streaming handled via `onyx.chat.models.AnswerStream` -> `Answer` generator.
       - Tool outputs aggregated into citations, message packets (`onyx.server.query_and_chat.streaming_models`).

Lane: Post-processing & Persistence
 11. `stream_chat_message` iteratively:
       - Updates message content (partial deltas) in DB.
       - Persists retrieved document list (`onyx.db.chat.get_doc_query_identifiers_from_model`).
       - Logs metrics to `onyx.utils.telemetry`.
 12. Once complete:
       - Marks chat session as latest (`set_as_latest_chat_message`).
       - Schedules optional renaming via `secondary_llm_flows/chat_session_naming.py`.
 13. Feedback loop:
       - Frontend triggers POST `/chat/feedback` -> `onyx.db.feedback`.
       - Document-level feedback stored for later re-ranking.
```

### 1.5 User File Upload and Project Scoping

```
Lane: Frontend (web/src/app/chat/services/fileUtils.ts)
  1. User drags files into chat composer -> files uploaded to `/chat/upload-user-file`.

Lane: API (backend/onyx/server/query_and_chat/query_backend.py & user_file_processing router)
  2. Files streamed into default file store; metadata recorded in `onyx.db.user_file`.
  3. `user_file_processing` Celery tasks index these files using same pipeline as connectors but scoped per-user.
  4. Project-specific file associations tracked in `onyx.db.projects`.

Lane: Retrieval
  5. When chat is project-scoped, `process_message` merges project files into candidate documents before sending to LLM.
```

### 1.6 Federated Search and External Connectors

```
Lane: Frontend (web/src/app/federated/*)
  1. Admin configures external federated connectors (e.g., Elastic, remote Onyx) via UI forms.

Lane: Backend
  2. `backend/onyx/federated_connectors` define HTTP clients, caching, and merging heuristics.
  3. `onyx.server.federated.api` proxies queries asynchronously, merges results with internal search (hybrid ranking).
  4. Rate limiting and credential storage handled similar to internal connectors, but requests executed on-demand during chat/search.
```

### 1.7 Observability, Telemetry, and Safety Nets

```
Lane: Monitoring Worker
  1. `backend/onyx/background/celery/tasks/monitoring` polls Celery queues, process RSS, and writes metrics to `backend/log/*`.

Lane: Telemetry
  2. `onyx.utils.telemetry` records anonymized usage, optionally sending to Braintrust (`onyx.tracing.braintrust_tracing`) or Langfuse (`onyx.tracing.langfuse_tracing`).
  3. `shared_configs` toggles metric destinations; environment variables control sampling.

Lane: Error Handling
  4. Exceptions bubble through custom handlers (`value_error_handler`, `validation_exception_handler` in main.py), returning consistent JSON envelopes.
  5. `onyx.background.error_logging` ensures Celery failures captured with connector context and sent to Sentry.
  6. Retry policies defined per-task via Celery decorators (`acks_late`, `autoretry_for`, exponential backoff).
```

### 1.8 Deployment Footpaths

```
Lane: Docker / Terraform / Helm (deployment/*)
  1. Docker Compose (`deployment/docker_compose/`) orchestrates services for local/dev.
  2. Helm charts (`deployment/helm/`) manage K8s deployments, toggling lightweight vs standard worker topology.
  3. Terraform modules (`deployment/terraform/modules/aws`) provision AWS infrastructure (ECS/EKS, RDS, S3, Redis Elasticache).
  4. CloudFormation templates support AWS Fargate deployment (`deployment/aws_ecs_fargate`).
```

> **Result:** Every runtime interaction—from connector onboarding to LLM streaming—links back to specific modules, enabling developers to trace any behavior to its implementation.

### 1.9 Model & Embedding Infrastructure

```
Lane: LLM Provider Registry (backend/onyx/server/manage/llm/*, backend/onyx/db/llm.py)
  1. Admin APIs persist provider metadata (API key, base URL, deployment, default/fast/vision models, custom headers) in Postgres tables (`llm_provider`, `llm_provider_model_configuration`).
  2. Persona records (`backend/onyx/db/models.Persona`) may override provider/model; overrides stored per persona and exposed to UI.
  3. Runtime fetches provider snapshots via `fetch_default_provider`, `fetch_llm_provider_view` with tenant-aware SQLAlchemy sessions.

Lane: LLM Selection & Orchestration (backend/onyx/llm/factory.py, backend/onyx/llm/chat_llm.py)
  4. Chat or agent flows call `get_llms_for_persona` / `get_llm_model_and_settings_for_persona` to build `(primary, fast)` pairs and LiteLLM settings objects.
  5. `DefaultMultiLLM` wraps LiteLLM, setting temperature, timeouts (`QA_TIMEOUT` scaling for reasoning models), request headers, and provider-specific authentication shims (e.g., Ollama bearer token synthesis, OpenRouter telemetry headers).
  6. Optional overrides (`LLMOverride`, `PromptOverride`) from personas or request payloads adjust provider, model version, temperature, or prompt strings.
  7. Streaming responses flow through `chat_llm.stream_complete` which adapts LiteLLM deltas into LangChain-style `AIMessageChunk`s, enabling tool calls, fallback handling, and cancellation/fence awareness.
  8. Vision use cases call `get_default_llm_with_vision`, filtering providers that advertise multimodal support via `model_supports_image_input`.

Lane: Model Server & Local Embedding (backend/model_server, backend/onyx/indexing/embedder.py)
  9. Indexing pipeline instantiates `EmbeddingModel`, configured with SearchSettings metadata (model, normalization, prefixes, reduced dimension).
 10. Local embeddings route to the Model Server (`backend/model_server/main.py`) on a dedicated port (`INDEXING_MODEL_SERVER_*`), using `/encoder/embed-text` to encode batched passages; model server caches `SentenceTransformer` instances, pre-warms RoPE caches, and enforces max context length.
 11. Model server also exposes reranker (`/encoder/rerank`) and custom classifier endpoints; warm-up toggled via `SKIP_WARM_UP` and `INDEXING_ONLY`.

Lane: Cloud Embedding Providers (backend/onyx/natural_language_processing/search_nlp_models.py)
 12. When SearchSettings specify API providers (OpenAI, Cohere, Voyage, Vertex, AWS Bedrock, etc.), `CloudEmbedding` adapters authenticate, batch requests, and retry with jitter/backoff; errors mapped to `ConnectorFailure` or surfaced to UI with sanitized API keys.
 13. Vertex AI embedding calls handle service account credentials; Voyage/Bedrock clients reuse httpx sessions for concurrency.
 14. Query vs passage prefixes applied according to `EmbedTextType` to maximize dual-encoder performance.

Lane: Downstream Scoring Enhancements
 15. `InformationContentClassificationModel` (LLM-triggered content booster) requests inference from model server or remote provider to assign chunk boost factors.
 16. Optional cross-encoder reranking executes via local `CrossEncoder` or API, depending on SearchSettings; results blend with hybrid (BM25 + embedding) scores.
 17. Long-term logging (`LongTermLogger`) captures prompt/response metadata when `LOG_ONYX_MODEL_INTERACTIONS` is enabled, routed through masked logging utilities.
```

### 1.10 Data Persistence & Multi-Tenant Layout

```
Lane: Postgres Primary Schema (backend/onyx/db/models.py)
  1. Core tables: `connector`, `credential`, `connector_credential_pair`, `document`, `document_by_connector_credential_pair`, `chat_session`, `chat_message`, `persona`, `user_file`, `kg_entity`, `kg_relationship`, `index_attempt`, `search_settings`, `llm_provider`, etc.
  2. Large JSON/Binary fields use custom types:
       - `EncryptedString`/`EncryptedJson` for credential and OAuth secrets.
       - `NullFilteredString` strips NULs before persistence.
  3. Multi-tenancy achieved by schema translation maps in `get_session_with_tenant` (`schema_translate_map = {None: tenant_id}`) driven by `CURRENT_TENANT_ID_CONTEXTVAR`; migrations duplicated in `alembic` (public schema) and `alembic_tenants` (private schema).
  4. `Document` stores metadata (semantic identifier, owners, ACLs, tags) but not chunk text; heavy content lives in Vespa and file stores.
  5. `ChunkStats` aggregates chunk counts/metadata for reporting; `IndexAttempt` tracks connector runs with status enums (`IndexingStatus`, `IndexModelStatus`).
  6. Knowledge graph tables (`kg_entity`, `kg_relationship`, staging variants) reference documents and capture extracted entities/relations for clustering.

Lane: Redis Coordination (backend/onyx/redis/*, backend/onyx/background/tasks)
  7. Redis namespaces partitioned per tenant; `RedisConnector` manages fences (delete/stop) for connector runs, job heartbeats, rate-limit counters.
  8. Chat features leverage Redis for WebSocket/session state (rate-limiting, ephemeral tokens) and Celery broker/backends.

Lane: Vespa Vector Store (backend/onyx/document_index/vespa/*)
  9. Vespa schema (`danswer_chunk.sd`) stores chunk embeddings, metadata fields (access control list, document sets, KG annotations, boost).
 10. `VespaIndex.index` handles batch inserts; fallbacks split per document with additional logging for HTTP 507 (insufficient storage).
 11. Query-time retrieval merges BM25 text match, semantic similarity, KG expansion, and time decay; results limited via `NUM_RETURNED_HITS` and streaming-chunk capping logic.

Lane: File & Blob Storage (backend/onyx/file_store/*, backend/onyx/file_processing/*)
 12. File store abstractions support S3-compatible, GCS, local disk backends; `FileDescriptor` records persisted in Postgres with signed URL helpers.
 13. User file uploads, connector-ingested binaries, and chat attachments stored here; indexing pipeline fetches bytes on demand for OCR/summarization.

Lane: Analytics & Telemetry Sinks
 14. Postgres tables log milestones (`milestone`), feedback (`chat_feedback`, `doc_retrieval_feedback`), and usage metrics for dashboards.
 15. Optional exports to Braintrust or Langfuse via `onyx.tracing.*`, controlled by environment flags.
```

---

## 2. Abstracted Architecture Overview

Below is a systems-level text diagram capturing major subsystems and data flow.

```
                             +---------------------------+
                             |        Web Client         |
                             |  Next.js 15 (web/src)     |
                             |  SWR, Zustand, Tailwind   |
                             +-------------+-------------+
                                           |
                                           | HTTPS (REST + SSE)
                                           v
+-------------------------------+      +---+-------------------------+
|  Edge / Middleware            |      |   FastAPI API Server       |
|  - web/src/middleware.ts      |----->|   backend/onyx/main.py      |
|  - Auth cookie guards         |      |   Routers under onyx/server |
+-------------------------------+      |   Pydantic models, auth     |
                                       +---+-----------+-------------+
                                           |           |
                                RPC (Celery)|           | SQLAlchemy (async context)
                                           v           v
                         +-------------------+   +---------------+
                         |  Celery Workers    |   | Postgres DB   |
                         |  backend/onyx/     |   | (metadata,    |
                         |  background/*      |   | chat, configs)|
                         +---+--+--+--+--+----+   +-------+-------+
                             |  |  |  |  |              |
        +--------------------+  |  |  |  +--------------+--------------+
        |                       |  |  |                 |              |
        v                       v  v  v                 v              v
+---------------+    +---------------------+   +---------------+   +----------------+
| Connector SDK |    | Indexing Pipeline    |   | Redis         |   | File Store     |
| onyx/connectors|   | onyx/indexing/*      |   | (queues,      |   | (S3/MinIO/local|
| - REST, OAuth |    | Chunking, Embedding  |   | fences, cache)|   |  binary blobs) |
+-------+-------+    +----+-----------------+   +-------+-------+   +--------+-------+
        |                 |                                 |                 |
        |                 |                                 |                 |
        v                 v                                 v                 v
  External Apps   +---------------+                  +-------------+    +---------------+
  (Google, Slack, | Vespa Vector  |                  | LiteLLM /    |    | Observability |
   GitHub, etc.)  | Store         |                  | Model Server |    | (Sentry,      |
                  | embeddings &  |                  | (LLM calls & |    | Prometheus,   |
                  | metadata      |                  | embeddings)  |    | Braintrust)   |
                  +---------------+                  +-------------+    +---------------+
```

Key relationships:

- **Next.js ↔ FastAPI:** REST endpoints, streaming responses for chat, file uploads, OAuth callbacks.
- **FastAPI ↔ Celery:** Enqueue background jobs via Redis broker; job payloads reference tenant, connector, search settings IDs.
- **Celery ↔ Connectors:** Workers instantiate connectors to pull remote content, respect credentials stored in Postgres/KV.
- **Indexing ↔ Vespa:** Processed chunks written to Vespa; metadata (boosts, tags, owners) stored in Postgres.
- **LLM Integrations:** Via `liteLLM` proxy or direct provider SDKs; results streamed back to client and logged.
- **Observability & Feature Flags:** shared_configs toggles features per deployment (CE vs EE), while tracing modules export telemetry.

---

## 3. Repository Tree with Commentary

The annotated tree lists every top-level artifact and drills into significant subdirectories. For directories with numerous homogeneous files (e.g., migrations, tests), patterns are described to keep the map consumable while still covering all contents.

```
repo-root/
├── ARCH.md — Comprehensive architecture manual (this document).
├── AGENTS.md — Instructions for automated agents (Celery workers, agent SDK usage guidelines).
├── CLAUDE.md — Supplemental guidance for Anthropic Codex agents.
├── CONTRIBUTING.md — General contribution workflow, coding standards.
├── CONTRIBUTING_MACOS.md — macOS-specific setup steps.
├── CONTRIBUTING_VSCODE.md — Recommended VSCode configuration, tasks.
├── README.md — Product overview, features, deployment quickstart.
├── REBRANDING_PLAN.md — Notes and action items for rebranding initiatives.
├── LICENSE — MIT license for community edition.
├── .gitignore — Ignore rules for Git.
├── .pre-commit-config.yaml — Pre-commit hook definitions.
├── .prettierignore — Paths excluded from Prettier.
├── .mcp.json.template — MCP configuration template for local tooling.
├── .claude/ — Anthropic Copilot workspace state.
├── .vscode/ — VSCode workspace settings, launch configs.
├── .github/ — CI workflows (lint, test, deploy) and issue templates.
├── .git/ — Git metadata directory.
├── ct.yaml — Codeowners/test owners configuration for continuous testing.
├── deployment/ — Deployment manifests and scripts.
│   ├── README.md — Directory usage overview.
│   ├── docker_compose/ — Local/Docker deployments.
│   │   ├── README.md — Compose stack explanation.
│   │   ├── .env.example — Template env file for Docker setup.
│   │   ├── docker-compose.yml — Service topology (API, web, workers, db, redis, vespa).
│   │   ├── install.sh — Convenience installer for Onyx Docker stack.
│   │   ├── seed_data.sql — Sample dataset for quickstart.
│   │   └── (other yaml/scripts) — Healthchecks, override files.
│   ├── helm/ — Kubernetes Helm charts.
│   │   ├── README.md — Helm deployment guidance.
│   │   ├── charts/onyx/Chart.yaml — Chart metadata.
│   │   ├── templates/*.yaml — K8s manifests (Deployments, Services, Ingress, Secrets).
│   │   ├── values.yaml — Default Helm values (toggle lightweight worker, resources).
│   │   └── values-*.yaml — Environment-specific overrides (prod/dev).
│   ├── terraform/ — Infrastructure-as-code modules.
│   │   ├── README.md — Terraform usage.
│   │   ├── main.tf / variables.tf / outputs.tf — Root module wiring.
│   │   └── modules/aws/ — Reusable AWS building blocks (VPC, RDS, S3, ECS/EKS).
│   ├── aws_ecs_fargate/ — CloudFormation templates for ECS Fargate deployments.
│   └── (scripts, docs) — Additional cloud deployment examples.
├── examples/ — Reference integrations and widgets.
│   ├── mcp/onyx_server/README.md — Example MCP server integration.
│   ├── widget/README.md — Embeddable chat widget usage.
│   └── (sample code) — Minimal clients demonstrating API usage.
├── onyx_data/ — Seeds and artifacts for sample data sets.
│   └── README.md — Instructions for populating demo datasets.
├── refs/ — Reference assets/configs (e.g., docs snapshots, prompt references).
├── backend/ — Python backend services.
│   ├── README.md — Backend-specific instructions.
│   ├── alembic/ — Community edition Alembic migrations.
│   │   ├── README.md — Migration guide.
│   │   ├── env.py — Alembic environment, SQLAlchemy metadata binding.
│   │   ├── script.py.mako — Migration template.
│   │   └── versions/*.py — Timestamped migration scripts (each upgrades schema objects; filenames describe change set).
│   ├── alembic_tenants/ — Tenant-specific migrations (private schema).
│   │   ├── README.md — Multi-tenant migration instructions.
│   │   └── versions/*.py — Tenant scoped schema diffs (mirrors alembic flow).
│   ├── assets/ — Static backend assets (prompt templates, sample configs).
│   ├── docker-bake.hcl — Buildx multi-platform Docker build definitions.
│   ├── Dockerfile — Backend API container definition.
│   ├── Dockerfile.model_server — Build instructions for model-serving image.
│   ├── ee/ — Enterprise edition overrides/extensions.
│   │   ├── onyx/ — EE-specific modules (additional connectors, billing, enterprise policies).
│   │   └── background/ — EE-only Celery tasks (advanced analytics, premium features).
│   ├── generated/ — Auto-generated code/assets (e.g., client SDK stubs).
│   ├── hello-vmlinux.bin — Sample binary used for eBPF or debugging flows.
│   ├── model_server/ — Lightweight inference server code.
│   │   ├── __init__.py — Package init.
│   │   ├── app.py — FastAPI app for embeddings/completions proxy.
│   │   └── routers/*.py — Endpoints for embeddings, rerankers.
│   ├── onyx/ — Primary backend package.
│   │   ├── __init__.py — Package exports.
│   │   ├── access/ — RBAC helpers.
│   │   │   ├── __init__.py — Consolidates access utilities.
│   │   │   ├── groups.py — Group resolution for auth scopes.
│   │   │   └── permissions.py — Fine-grained permission checks.
│   │   ├── agents/ — Agent framework integrations.
│   │   │   ├── agent_sdk/ — Shared message & streaming adapters.
│   │   │   │   ├── message_format.py — Converts chat history into SDK format.
│   │   │   │   ├── message_types.py — Typed message envelopes.
│   │   │   │   ├── monkey_patches.py — Compatibility tweaks for third-party SDKs.
│   │   │   │   └── sync_agent_stream_adapter.py — Bridges streaming generators.
│   │   │   └── agent_search/ — Tools enabling agentic search flows.
│   │   ├── auth/ — Authentication domain.
│   │   │   ├── __init__.py — Auth exports.
│   │   │   ├── schemas.py — Pydantic models for users.
│   │   │   ├── users.py — FastAPI Users integration, dependency providers.
│   │   │   ├── backends/ — Pluggable auth backends (OAuth, JWT).
│   │   │   └── utils.py — Password hashing, token helpers.
│   │   ├── background/ — Celery orchestration.
│   │   │   ├── celery/ — Worker definitions & tasks.
│   │   │   │   ├── apps/ — Celery app factories per worker type.
│   │   │   │   │   ├── app_base.py — Shared Celery configuration.
│   │   │   │   │   ├── primary.py / docfetching.py / docprocessing.py / light.py / heavy.py / monitoring.py / kg_processing.py / user_file_processing.py — Worker-specific entrypoints (concurrency, queue binding).
│   │   │   │   │   └── versioned_apps/ — Legacy/alternate Celery configurations.
│   │   │   │   ├── celery_k8s_probe.py — Health probes for K8s.
│   │   │   │   ├── celery_redis.py — Redis broker utilities.
│   │   │   │   ├── celery_utils.py — Retry, logging helpers.
│   │   │   │   ├── configs/ — YAML/JSON worker configs (queue names, priorities).
│   │   │   │   └── tasks/ — Task modules (connector_deletion, docfetching, docprocessing, pruning, monitoring, kg_processing, vespa, evals, periodic beat schedules, user file processing).
│   │   │   ├── error_logging.py — Celery exception to Sentry bridge.
│   │   │   ├── indexing/ — Shared indexing utilities (job client, checkpointing, memory tracing).
│   │   │   └── task_utils.py — Common Celery decorators and fences.
│   │   ├── chat/ — Conversational logic.
│   │   │   ├── __init__.py — Chat exports.
│   │   │   ├── answer.py — Structures the final answer payload with citations.
│   │   │   ├── chat_utils.py — Creates chat chains, persona contexts.
│   │   │   ├── memories.py — Long-term memory storage & retrieval.
│   │   │   ├── models.py — Chat-related data models (Answer, ChatMessage, etc.).
│   │   │   ├── process_message.py — Core message processing pipeline, tool orchestration.
│   │   │   ├── prompt_builder/ — Prompt templates for answers, citations.
│   │   │   ├── stop_signal_checker.py — Mechanism to cancel running chats.
│   │   │   ├── tool_handling/ — Chat tool integration (search, web).
│   │   │   ├── turn/ — Chat turn execution, streaming emitter infrastructure.
│   │   │   ├── stream_processing/ — SSE packet formatting & transformations.
│   │   │   └── user_files/ — Parsing and prepping user-uploaded docs for chat.
│   │   ├── configs/ — Centralized configuration values.
│   │   │   ├── app_configs.py — Core application settings (host, port, toggles).
│   │   │   ├── chat_configs.py — Chat-specific constants (chunk limits).
│   │   │   ├── constants.py — Global enums, Onyx-specific constants.
│   │   │   ├── llm_configs.py — LLM provider toggles, defaults.
│   │   │   └── model_configs.py — Model-specific flags (embeddings, ICC).
│   │   ├── connectors/ — Connector implementations (one directory per source).
│   │   │   ├── README.md — Contribution guide for new connectors.
│   │   │   ├── __init__.py — Registry exports.
│   │   │   ├── factory.py — Maps DocumentSource enum to connector classes.
│   │   │   ├── interfaces.py — Base connector protocols (LoadConnector, PollConnector, SlimConnector).
│   │   │   ├── models.py — Connector domain models (Document, Section, IndexAttemptMetadata).
│   │   │   ├── credentials_provider.py — Centralized credential loading.
│   │   │   ├── connector_runner.py — Utility to execute connectors directly.
│   │   │   ├── exceptions.py — Connector-specific error types.
│   │   │   ├── registry.py — Metadata about available connectors.
│   │   │   ├── cross_connector_utils/ — Shared helpers (rate limiting, Owner mapping).
│   │   │   ├── <connector_name>/ — Source-specific implementations:
│   │   │   │   ├── e.g., airtable/*.py — Airtable REST pagination, schema parsing.
│   │   │   │   ├── github/*.py — GitHub API clients, repo walkers.
│   │   │   │   ├── sharepoint/*.py — SharePoint site traversal.
│   │   │   │   └── ... (asana, slack, zendesk, etc.) — Each contains API client wrappers, load/poll logic, state serialization.
│   │   │   └── google_utils/ — OAuth flows, token refresh utilities shared by Google connectors.
│   │   ├── context/ — Search context builders (hybrid search, rerank fusion).
│   │   ├── db/ — Database access layer.
│   │   │   ├── __init__.py — DB exports.
│   │   │   ├── engine/ — SQLAlchemy engine factories, session helpers, multi-tenant support.
│   │   │   ├── models.py — ORM definitions for users, connectors, chats, documents, projects, etc.
│   │   │   ├── <entity>.py — CRUD utilities per domain (connector.py, chat.py, document.py, persona.py, projects.py, etc.).
│   │   │   ├── enums.py — Enum wrappers for statuses (IndexingMode, ConnectorCredentialPairStatus).
│   │   │   ├── migration_utils.py — Helper functions used in Alembic migrations.
│   │   │   └── search_settings.py — Accessors for search configuration rows.
│   │   ├── document_index/ — Vector store abstractions.
│   │   │   ├── interfaces.py — DocumentIndex interface, DocumentMetadata, IndexBatchParams.
│   │   │   ├── factory.py — Instantiates Vespa-backed index.
│   │   │   ├── vespa/ — Vespa client, schema definitions, query wrappers.
│   │   │   └── document_index_utils.py — Multipass configuration, query helpers.
│   │   ├── evals/ — Evaluation harnesses for answer/search quality.
│   │   ├── feature_flags/ — Toggle infrastructure (providers, keys).
│   │   ├── federated_connectors/ — Federated search clients and merging logic.
│   │   ├── file_processing/ — File parsers, converters (PDF, DOCX, image summarization).
│   │   ├── file_store/ — Backends for file persistence (S3, local FS, GCS).
│   │   ├── httpx/ — Shared HTTP client session configuration, retries.
│   │   ├── indexing/ — Indexing pipeline core.
│   │   │   ├── adapters/ — Glue between connector docs and DB records.
│   │   │   ├── chunker.py — Document chunk splitting logic.
│   │   │   ├── content_classification.py — Calls ICC model to boost scoring.
│   │   │   ├── embedder.py — Embedding orchestration, handles rate limits.
│   │   │   ├── indexing_pipeline.py — Main pipeline orchestrator (see Section 1.3).
│   │   │   ├── models.py — Data classes for chunks, batches, update payloads.
│   │   │   ├── vector_db_insertion.py — Write paths to Vespa / backoff handling.
│   │   │   └── indexing_heartbeat.py — Heartbeat thread to ensure progress visibility.
│   │   ├── key_value_store/ — Pluggable KV interfaces (Redis, Postgres, Secrets Manager).
│   │   ├── kg/ — Knowledge graph builders and clustering algorithms.
│   │   ├── llm/ — LLM abstractions, provider integrations.
│   │   │   ├── factory.py — Creates default LLM tuples (main, fallback, summary).
│   │   │   ├── interfaces.py — LLM interface definition.
│   │   │   ├── chat_llm.py — LiteLLM wrappers for chat/completions.
│   │   │   ├── models.py — Pydantic settings for LLM invocation.
│   │   │   ├── utils.py — Token counting, prompt conversion.
│   │   │   └── exceptions.py — Error types for rate limits, disabled LLMs.
│   │   ├── natural_language_processing/ — Tokenizers, text normalization, ICC models.
│   │   ├── onyxbot/ — Slack bot integrations, commands.
│   │   ├── prompts/ — Prompt template strings for chat, summarization.
│   │   ├── redis/ — Redis connection pooling, key namespaces (delete fences, stop signals).
│   │   ├── secondary_llm_flows/ — Auxiliary LLM workflows (chat naming, summarization).
│   │   ├── seeding/ — Data seeding scripts for personas, connectors.
│   │   ├── server/ — FastAPI routers and request models.
│   │   │   ├── __init__.py — Router exports.
│   │   │   ├── api_key/ — API key issuance endpoints.
│   │   │   ├── documents/ — Connectors, credentials, document management APIs.
│   │   │   ├── features/ — Feature-specific APIs (input prompts, personas, notifications, MCP, projects, tools).
│   │   │   ├── federated/ — Federated search API endpoints.
│   │   │   ├── gpts/ — GPT-style assistant APIs.
│   │   │   ├── long_term_logs/ — Access to long-term log exports.
│   │   │   ├── manage/ — Admin endpoints (embedding configs, state, Slack bot, users).
│   │   │   ├── middleware/ — Custom FastAPI middlewares (latency logging, rate limiting).
│   │   │   ├── onyx_api/ — Ingestion API for external systems.
│   │   │   ├── openai_assistants_api/ — OpenAI-compatible API surface.
│   │   │   ├── query_and_chat/ — Chat and query endpoints (see Section 1.4).
│   │   │   ├── saml.py — SAML auth endpoints.
│   │   │   ├── settings/ — User and admin settings APIs.
│   │   │   ├── token_rate_limits/ — Per-user/token rate limit endpoints.
│   │   │   └── utils.py — Shared response helpers.
│   │   ├── tools/ — Tool registry and implementations (web search, actions, code execution).
│   │   ├── tracing/ — Integrations with Langfuse, Braintrust, OpenTelemetry.
│   │   └── utils/ — General utilities (logging, timing, headers, threading, telemetry).
│   ├── pyproject.toml — Backend dependencies, tooling configuration.
│   ├── pytest.ini — Pytest defaults (markers, ignores).
│   ├── requirements/ — Pinned requirement sets per environment (base.txt, dev.txt, worker.txt).
│   ├── scripts/ — Operational scripts.
│   │   ├── dev-run.sh — Local run helper.
│   │   ├── seed_db.py — Seed database with demo content.
│   │   ├── debugging/ — Scripts for log analysis, connector debugging.
│   │   ├── query_time_check/ — Tools for measuring query latency.
│   │   └── tenant_cleanup/ — Utilities for removing tenants safely (README explains usage).
│   ├── shared_configs/ — Shared configuration between CE and EE; includes feature toggles, constant enums, contextvars.
│   ├── slackbot_images/README.md — Guidance for Slackbot imagery.
│   ├── static/ — Static backend assets (images, CSS).
│   └── tests/ — Backend test suites.
│       ├── README.md — Test overview.
│       ├── unit/ — Pure unit tests (mocking external services).
│       ├── external_dependency_unit/ — Tests requiring external services (connectors, DB).
│       ├── integration/ — Full integration tests hitting deployed stack.
│       ├── regression/search_quality/ — Search quality regression harness.
│       └── regression/answer_quality/ — QA regression tests.
├── backend/log/ — Runtime log directory (api_server_debug.log, celery_*_debug.log).
├── backend/.venv/ — (Ignored) Optional local virtualenv.
├── pyproject.toml — Monorepo-level Python packaging metadata.
├── web/ — Next.js frontend.
│   ├── README.md — Frontend usage guide.
│   ├── Dockerfile — Frontend container definition.
│   ├── package.json / package-lock.json — NPM dependencies.
│   ├── tsconfig.json — TypeScript configuration.
│   ├── next.config.js — Next.js config (Sentry, rewrites).
│   ├── playwright.config.ts — E2E test configuration.
│   ├── jest.config.js — Jest unit test config.
│   ├── postcss.config.js — Tailwind/PostCSS config.
│   ├── tailwind.config.js — Tailwind theme definitions.
│   ├── STANDARDS.md — Frontend coding standards.
│   ├── public/ — Static assets served by Next.js (favicons, logos).
│   ├── @types/ — Custom TypeScript type declarations.
│   ├── src/
│   │   ├── app/ — App Router pages & server components.
│   │   │   ├── layout.tsx — Root layout (providers, fonts).
│   │   │   ├── page.tsx — Root landing page.
│   │   │   ├── global-error.tsx — Global error boundary.
│   │   │   ├── components/ — Shared server components for app directory.
│   │   │   ├── admin/ — Admin dashboards (connectors, search settings).
│   │   │   ├── anonymous/ — Anonymous landing experience (no auth).
│   │   │   ├── api/ — Route handlers for Next.js API endpoints (proxying backend).
│   │   │   ├── assistants/ — Assistant builder UI.
│   │   │   ├── auth/ — Login, signup pages.
│   │   │   ├── chat/ — Chat UI (components, hooks, services, stores).
│   │   │   ├── connector/ — Connector management UI.
│   │   │   ├── federated/ — Federated search management UI.
│   │   │   ├── mcp/ — MCP console and management.
│   │   │   ├── oauth-config/ — OAuth configuration UI.
│   │   │   ├── providers.tsx — Client/provider wrappers (SWR, modals).
│   │   │   └── ... (EE-specific pages under `ee/`).
│   │   ├── components/ — Reusable client components (buttons, forms, modals).
│   │   ├── hooks/ — Shared React hooks (useDebounce, useMediaQuery).
│   │   ├── icons/ — SVG icon exports.
│   │   ├── lib/ — Client-side domain logic.
│   │   │   ├── admin/ — Admin-related fetch wrappers & helpers.
│   │   │   ├── assistants/ — Assistant configuration client helpers.
│   │   │   ├── auth/ — Auth helpers compatible with backend sessions.
│   │   │   ├── chat/ — Chat DTOs, streaming utilities (`packetUtils`, `streamingModels`).
│   │   │   ├── connectors/ — Connector metadata, dynamic form definitions, OAuth flows.
│   │   │   ├── credential.ts — CRUD helpers for credentials.
│   │   │   ├── fetcher.ts — Centralized fetch wrapper with error handling.
│   │   │   ├── generated/ — Client-side generated types (OpenAPI).
│   │   │   ├── llm/ — Frontend LLM preference helpers.
│   │   │   ├── search/ — Search query helpers.
│   │   │   ├── tools/ — Tool metadata mirroring backend.
│   │   │   ├── types.ts — Shared TypeScript types/enums for connectors, personas.
│   │   │   └── utils.ts — Misc utilities (date, url builders, string helpers).
│   │   ├── refresh-components/ — Components revalidated server-side.
│   │   ├── sections/ — Marketing/landing page section components.
│   │   ├── instrumentation.ts / instrumentation-client.ts — Web vitals + PostHog integration.
│   │   └── middleware.ts (at repo root) — Next.js edge middleware for auth & routing.
│   ├── tailwind-themes/ — Theme configuration (CSS variables, custom palettes).
│   └── tests/ — Frontend tests.
│       ├── README.md — Testing notes.
│       ├── e2e/ — Playwright specs (simulate full UI flows).
│       ├── setup/ — Jest/playwright setup files (`jest.setup.ts`, mocks).
│       └── unit/component tests — Under `web/src/.../*.test.ts(x)`.
└── web/test-results/ — (Generated) Playwright artifacts.
```

> **Note:** Generated artifacts (e.g., compiled build outputs, virtual environments) are generally excluded via `.gitignore`. Any file not explicitly enumerated above either follows predictable naming patterns (e.g., Alembic migration scripts, test cases) or is auto-generated during build/test; their purpose is documented by the parent directory comments.

---

### Maintenance Checklist

- Update **Section 1** whenever connector flows, chat pipelines, or worker topologies change.
- Update **Section 2** if new core subsystems (e.g., new vector DB, analytics pipeline) are introduced.
- Update **Section 3** when adding new top-level directories or significant module groups so this tree remains exhaustive.

With these three synchronized views, any maintainer can trace a runtime behavior to its implementation and understand the platform end-to-end.
