Knowsee Platform Stack Flow

  Architecture Overview

  ┌─────────────────────────────────────────────────────────────────────┐
  │                           BROWSER                                    │
  │                    (React Components)                                │
  └──────────────────────────┬──────────────────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                    NEXT.JS (Port 3001)                               │
  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
  │  │   NextAuth      │  │  API Routes     │  │  Server Actions     │  │
  │  │   (Sessions)    │  │  /api/*         │  │  (form handling)    │  │
  │  └────────┬────────┘  └────────┬────────┘  └──────────┬──────────┘  │
  │           │                    │                      │              │
  │           └────────────────────┼──────────────────────┘              │
  │                                │                                     │
  │                    ┌───────────▼───────────┐                        │
  │                    │  lib/db/queries.ts    │                        │
  │                    │  (API client)         │                        │
  │                    └───────────┬───────────┘                        │
  └────────────────────────────────┼────────────────────────────────────┘
                                   │ HTTP (fetch)
                                   ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                  PYTHON BACKEND (Port 8000)                          │
  │  ┌─────────────────────────────────────────────────────────────┐    │
  │  │                    FastAPI App                               │    │
  │  │  ┌─────────────────┐  ┌─────────────────┐                   │    │
  │  │  │  /api/db/*      │  │  /api/chat      │                   │    │
  │  │  │  (DB Routes)    │  │  (AI Streaming) │                   │    │
  │  │  └────────┬────────┘  └────────┬────────┘                   │    │
  │  └───────────┼────────────────────┼─────────────────────────────┘    │
  │              │                    │                                  │
  │   ┌──────────▼──────────┐  ┌──────▼──────────┐                      │
  │   │  db/queries.py      │  │  LangGraph      │                      │
  │   │  (SQLAlchemy)       │  │  + Vertex AI    │                      │
  │   └──────────┬──────────┘  └─────────────────┘                      │
  └──────────────┼──────────────────────────────────────────────────────┘
                 │ asyncpg
                 ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                   POSTGRESQL (Port 5432)                             │
  │  ┌───────┐ ┌───────┐ ┌───────────┐ ┌──────┐ ┌────────┐ ┌────────┐  │
  │  │ User  │ │ Chat  │ │ Message_v2│ │Vote_v2│ │Document│ │ Stream │  │
  │  └───────┘ └───────┘ └───────────┘ └──────┘ └────────┘ └────────┘  │
  └─────────────────────────────────────────────────────────────────────┘

  Request Flows

  1. Login Flow
  Browser → POST /login
         → Next.js Server Action (actions.ts)
         → getUser() → Python /api/db/users?email=...
         → bcrypt compare (in Next.js)
         → NextAuth session created

  2. Chat History Flow
  Browser → GET /api/history
         → Next.js API Route
         → getChatsByUserId() → Python /api/db/chats?userId=...
         → SQLAlchemy query → PostgreSQL
         → JSON response back through chain

  3. Send Message Flow
  Browser → POST /api/chat (SSE stream)
         → Next.js saves user message → Python /api/db/messages
         → Next.js calls AI (Gemini via Vercel AI SDK)
         → Stream tokens back to browser
         → On finish: save assistant message → Python /api/db/messages

  File Structure

  knowsee-platform/
  ├── .env                          # Python backend env (POSTGRES_URL)
  ├── pyproject.toml                # Python deps (SQLAlchemy, FastAPI)
  ├── Makefile                      # Unified commands
  │
  ├── backend/src/
  │   ├── app.py                    # FastAPI entry point
  │   ├── api/routes.py             # /api/db/* endpoints
  │   ├── db/
  │   │   ├── config.py             # Async SQLAlchemy engine
  │   │   ├── models.py             # ORM models (7 tables)
  │   │   └── queries.py            # 24 CRUD functions
  │   ├── graph.py                  # LangGraph chatbot
  │   └── stream.py                 # Vercel AI SDK protocol
  │
  ├── frontend/
  │   ├── .env.local                # Frontend env (BACKEND_URL)
  │   ├── lib/
  │   │   ├── api/backend.ts        # Python API client
  │   │   └── db/
  │   │       ├── queries.ts        # Calls Python backend
  │   │       └── schema.ts         # TypeScript types (kept)
  │   └── app/
  │       ├── (auth)/               # Login/register
  │       └── (chat)/api/           # Chat API routes
  │
  └── backend/alembic/              # DB migrations (Python owns)

   Key Commands

  | Command                 | What it does                         |
  |-------------------------|--------------------------------------|
  | make local-backend      | Starts Python on :8000               |
  | make frontend           | Starts PostgreSQL + Next.js on :3001 |
  | make backend-lint       | Runs ruff + mypy on Python           |
  | make frontend-typecheck | Runs tsc on TypeScript               |
  | make check              | Full CI pipeline                     |

  Environment Variables

  Root .env (Python backend):
  POSTGRES_URL=postgresql://postgres:postgres@localhost:5432/chatbot
  GOOGLE_CLOUD_PROJECT=...

  frontend/.env.local (Next.js):
  BACKEND_URL=http://localhost:8000
  POSTGRES_URL=...  # Still needed for Drizzle migrations
  AUTH_SECRET=...

  Why This Architecture?

  | Layer      | Responsibility                    | Why                                     |
  |------------|-----------------------------------|-----------------------------------------|
  | Next.js    | Auth, UI, streaming orchestration | Best React/SSR support                  |
  | Python     | DB operations, AI inference       | Better for ML/data, SQLAlchemy maturity |
  | PostgreSQL | Single source of truth            | Both services share same DB             |

  This is the Backend-for-Frontend (BFF) pattern - industry standard for this type of stack.