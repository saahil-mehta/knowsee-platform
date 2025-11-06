# Playwright Smoke Tests

The Playwright suite exercises the high-level chat experience and runs against the development server.

## Prerequisites

```bash
cd web
npx playwright install --with-deps
```

The command above downloads the Chromium browser bundle (and, on Linux, installs required system libraries).

## Running tests

```bash
cd web
npm run test:e2e
```

By default the config launches the Next.js dev server automatically and reuses an existing server when you have one running locally.

## Test locations

- `web/tests/chat-smoke.spec.ts` – verifies that the chat surface renders, the sidebar lists conversations, and the input interactions work.

## CI recommendations

- Set `CI=1` to prevent Playwright from reusing a local server.
- Cache the `playwright` Chromium bundle between runs (`~/.cache/ms-playwright`).
- For faster builds, you can run `npx playwright install chromium` only.
