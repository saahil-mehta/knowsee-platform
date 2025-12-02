Knowsee Platform Stack Flow

  Architecture Overview

  ┌─────────────────────────────────────────────────────────────────────┐
  │                           BROWSER                                    │
  │                    (React Components)                                │
  └──────────────────────────┬──────────────────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                    NEXT.JS (Port 3000)                               │
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
  │   │       └── types.ts          # TypeScript type definitions
  │   └── app/
  │       ├── (auth)/               # Login/register
  │       └── (chat)/api/           # Chat API routes
  │
  └── backend/alembic/              # Alembic DB migrations
      └── versions/                 # Migration scripts

  Commands, Migrations, and Environment Variables

  See README.md for Make commands, database migrations, and environment setup.

  Why This Architecture?

  | Layer      | Responsibility                    | Why                                     |
  |------------|-----------------------------------|-----------------------------------------|
  | Next.js    | Auth, UI, streaming orchestration | Best React/SSR support                  |
  | Python     | DB operations, AI inference       | Better for ML/data, SQLAlchemy maturity |
  | PostgreSQL | Single source of truth            | Both services share same DB             |

  This is the Backend-for-Frontend (BFF) pattern - industry standard for this type of stack.