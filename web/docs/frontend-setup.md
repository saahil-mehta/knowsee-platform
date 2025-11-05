# Frontend Development Setup

This guide covers the developer workflow for the Knowsee web client after the tooling refresh.

## 1. Bootstrap dependencies

```bash
cd web
npm run bootstrap
```

The bootstrap script installs `node_modules` if the directory is empty and creates `.env.local` from `.env.example` when needed. It will also warn about missing environment variables such as `NEXT_PUBLIC_API_URL`.

## 2. Run the stack with Docker

```bash
cd ..
make dev
```

`make dev` builds the images, brings up the FastAPI mock, Redis, and the Next.js development server, and waits for the health checks to pass. Use `make dev-down` when you are finished.

### Useful adjunct commands

- `make dev-logs` – tail all service logs.
- `make dev-restart` – restart the containers without rebuilding.
- `make dev-health` – rerun the readiness probes.

## 3. Local-only development (without Docker)

```bash
cd web
npm run dev
```

This starts the Next.js server directly. Ensure the mock API is running separately (`docker compose -f dev/docker-compose.yml up api`).

## 4. Quality gates

```bash
cd web
npm run lint
npm run type-check
npm run test:e2e   # requires playwright browsers; see docs below
```

- `npm run lint` executes Next.js ESLint with the shared config.
- `npm run type-check` runs TypeScript via the local compiler install.
- `npm run test:e2e` launches the Playwright smoke suite (see `web/docs/playwright.md`).

## 5. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `make dev` reports `web: starting` for >30s | Run `docker logs knowsee-web` to confirm the Next.js server; check for missing dependencies or invalid env vars. |
| Next.js hot reload misses changes | The web container mounts `web/` with `:cached`. If changes do not propagate, run `docker compose -f dev/docker-compose.yml restart web`. |
| `npm run dev` exits immediately | Ensure `.env.local` exists and includes `NEXT_PUBLIC_API_URL=http://localhost:8000`. |
