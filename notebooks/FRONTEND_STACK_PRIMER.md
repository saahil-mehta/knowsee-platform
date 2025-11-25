# Frontend Stack Primer

A practical guide to the technologies powering the Knowsee frontend.

---

## Table of Contents

1. [TypeScript (ts)](#typescript)
2. [pnpm](#pnpm)
3. [Vitest](#vitest)
4. [Playwright](#playwright)
5. [Vercel AI SDK Chatbot](#vercel-ai-sdk-chatbot)
6. [Bun (bonus)](#bun)
7. [How They Fit Together](#how-they-fit-together)

---

## TypeScript

**What:** JavaScript with static types. Catches errors at compile-time instead of runtime.

**Why it matters:**
```typescript
// JavaScript - fails silently at runtime
function greet(name) {
  return "Hello " + name.toUpperCase(); // Crashes if name is undefined
}

// TypeScript - caught at compile time
function greet(name: string): string {
  return "Hello " + name.toUpperCase(); // Editor warns if name might be undefined
}
```

**Key concepts:**
- **Types** - `string`, `number`, `boolean`, `object`, arrays (`string[]`)
- **Interfaces** - Define object shapes
- **Generics** - Reusable type patterns (`Array<T>`)
- **Type inference** - TS often figures out types automatically

**In this project:**
- All `.ts` and `.tsx` files are TypeScript
- `tsconfig.json` configures the compiler
- `pnpm tsc --noEmit` checks types without building

**Practical tip:** Hover over variables in VS Code to see inferred types.

---

## pnpm

**What:** Fast, disk-efficient package manager. Alternative to npm/yarn.

**Why pnpm over npm:**
```
npm install     → copies packages to each project (wastes disk)
pnpm install    → symlinks from global store (saves disk, faster)
```

**Key commands:**
```bash
pnpm install              # Install all deps from lock file
pnpm add <package>        # Add a dependency
pnpm add -D <package>     # Add dev dependency
pnpm remove <package>     # Remove a dependency
pnpm run <script>         # Run a script from package.json
pnpm exec <command>       # Run a binary from node_modules
```

**Important files:**
- `package.json` - Dependencies and scripts (committed)
- `pnpm-lock.yaml` - Exact versions locked (committed - ensures reproducibility)
- `node_modules/` - Installed packages (gitignored)

**How dependency sharing works:**
1. You run `pnpm add vitest`
2. pnpm updates `package.json` and `pnpm-lock.yaml`
3. You commit both files
4. Collaborator pulls and runs `pnpm install`
5. They get exact same versions from the lock file

---

## Vitest

**What:** Fast unit testing framework. Built on Vite, works great with TypeScript.

**Why Vitest:**
- Native TypeScript support (no config needed)
- Compatible with Jest API (easy migration)
- Very fast (uses Vite's transform pipeline)
- Watch mode for TDD

**Anatomy of a test:**
```typescript
import { describe, it, expect } from "vitest";

describe("Calculator", () => {           // Test suite
  it("adds two numbers", () => {         // Test case
    expect(1 + 1).toBe(2);               // Assertion
  });

  it("handles edge cases", () => {
    expect(0 + 0).toBe(0);
    expect(-1 + 1).toBe(0);
  });
});
```

**Key concepts:**
- `describe()` - Groups related tests
- `it()` or `test()` - Individual test case
- `expect()` - Creates an assertion
- `toBe()`, `toEqual()`, `toContain()` - Matchers

**Commands:**
```bash
pnpm test:unit           # Run once
pnpm test:unit:watch     # Watch mode (re-runs on file change)
pnpm test:unit:coverage  # With coverage report
```

**Configuration:** `vitest.config.ts`

---

## Playwright

**What:** End-to-end testing framework. Automates real browsers.

**Unit tests vs E2E tests:**
```
Unit tests (Vitest)     → Test functions/components in isolation
                        → Fast (milliseconds)
                        → No browser, no network

E2E tests (Playwright)  → Test full user flows in real browser
                        → Slower (seconds to minutes)
                        → Real browser, real network
```

**How Playwright works:**
```typescript
import { test, expect } from "@playwright/test";

test("user can log in", async ({ page }) => {
  await page.goto("/login");
  await page.fill('[name="email"]', "test@example.com");
  await page.fill('[name="password"]', "password");
  await page.click('button[type="submit"]');

  await expect(page).toHaveURL("/dashboard");
});
```

**Why browsers must be installed separately:**
- Playwright downloads actual browser binaries (Chromium, Firefox, WebKit)
- These are ~100MB+ each, not npm packages
- `pnpm exec playwright install` downloads them to system cache

**Configuration:** `playwright.config.ts`

---

## Vercel AI SDK Chatbot

**What:** The foundation of this frontend. A production-ready AI chat template.

**Architecture:**
```
User Input → React UI → API Route → AI Provider → Stream Response → UI Update
```

**Key components:**

1. **AI SDK (`ai` package)**
   - `streamText()` - Stream LLM responses
   - `useChat()` - React hook for chat state
   - Provider adapters (OpenAI, Google, etc.)

2. **Next.js App Router**
   - `app/` - File-based routing
   - `app/(chat)/` - Chat-related pages
   - `app/api/` - API endpoints

3. **Database (Backend API)**
   - `lib/db/types.ts` - TypeScript type definitions
   - `lib/db/queries.ts` - API calls to Python backend
   - SQLAlchemy + PostgreSQL in backend

4. **Authentication (NextAuth)**
   - `app/(auth)/` - Auth pages and config
   - Session management
   - Protected routes

**Request flow for a chat message:**
```
1. User types message in UI
2. useChat() sends POST to /api/chat
3. API route calls streamText() with selected model
4. Response streams back token-by-token
5. UI updates in real-time
6. Message saved to database
```

---

## Bun

**What:** All-in-one JavaScript runtime. Alternative to Node.js + npm + bundlers.

**Bun vs Node.js:**
```
Node.js     → Runtime only, need separate tools (npm, webpack, etc.)
Bun         → Runtime + package manager + bundler + test runner
```

**Why mention it:**
- Significantly faster than Node.js
- Drop-in replacement (mostly compatible)
- This project uses Node.js + pnpm, but Bun is gaining popularity
- If you see `bun` commands in other projects, they're similar to `pnpm`

**Equivalent commands:**
```bash
pnpm install     ≈  bun install
pnpm add react   ≈  bun add react
pnpm run dev     ≈  bun run dev
```

---

## How They Fit Together

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Development                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TypeScript (.ts/.tsx)                                          │
│       │                                                         │
│       ▼                                                         │
│  pnpm install ──────► Dependencies from pnpm-lock.yaml          │
│       │                                                         │
│       ▼                                                         │
│  pnpm dev ──────────► Next.js dev server (localhost:3000)       │
│       │                                                         │
│       ▼                                                         │
│  Testing Pipeline:                                              │
│       │                                                         │
│       ├── pnpm test:unit ────► Vitest (fast, isolated)          │
│       │                                                         │
│       └── pnpm test:e2e ─────► Playwright (browser, slow)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Development workflow:**
1. `make install` - Get dependencies + playwright browsers
2. `make frontend` - Start dev server with database
3. Write code in TypeScript
4. `make frontend-test-unit` - Quick feedback (run often)
5. `make frontend-test-e2e` - Full validation (run before commits)
6. `make check` - Full CI pipeline (lint + typecheck + test + build)

---

## Quick Reference

| Technology | Purpose | Config File | Main Command |
|------------|---------|-------------|--------------|
| TypeScript | Type safety | `tsconfig.json` | `pnpm tsc` |
| pnpm | Package management | `package.json` | `pnpm install` |
| Vitest | Unit testing | `vitest.config.ts` | `pnpm test:unit` |
| Playwright | E2E testing | `playwright.config.ts` | `pnpm test:e2e` |
| Next.js | React framework | `next.config.ts` | `pnpm dev` |

---

## Further Reading

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)
- [pnpm Documentation](https://pnpm.io/)
- [Vitest Guide](https://vitest.dev/guide/)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [Vercel AI SDK](https://sdk.vercel.ai/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/) (Backend ORM)
