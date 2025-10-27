# Knowsee CopilotKit Frontend

Next.js user interface for the Knowsee agent. The React app connects to the FastAPI service in `app/api.py` via the CopilotKit runtime and AG-UI protocol, providing a clean chat interface similar to ChatGPT.

## Prerequisites

- Node.js 18 or newer
- Access to the Knowsee backend (run locally with `uv run python -m app.api` or via the deployed API)
- `npm` (or another Node package manager if you prefer to adapt the commands)

## Setup

1. Install dependencies:

```bash
npm install
```

2. Create a `.env.local` (optional) to point the UI at a non-default backend:

```
NEXT_PUBLIC_AGENT_API_URL=https://your-api-url.example.com/
```

   The UI defaults to `http://localhost:8000/`, which matches the local FastAPI server.

3. Start the development server:

```bash
npm run dev
```

   Then open http://localhost:3000 while the backend is running.

## Scripts

- `npm run dev` – start the Next.js development server
- `npm run build` – create a production bundle
- `npm run start` – serve the production build
- `npm run lint` – run ESLint

## Key Files

- `src/app/page.tsx` – chat surface rendered in the browser
- `src/app/api/copilotkit/route.ts` – Next.js route bridging CopilotKit and the FastAPI endpoint
- `src/app/layout.tsx` / `src/app/globals.css` – global layout and styling

## Troubleshooting

- Ensure the FastAPI service is reachable at the URL configured in `NEXT_PUBLIC_AGENT_API_URL`.
- If the chat stalls on first request, check the FastAPI logs for authentication or quota errors from upstream Google services.
