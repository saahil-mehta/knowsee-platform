# Knowsee Web Frontend

Next.js 15 + React + TypeScript chat interface for GPT-OSS-120B.

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local

# Start development server
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

## Prerequisites

- Node.js 20+
- npm or yarn
- Running dev API server (see `../dev/README.md`)

## Development

```bash
# Start dev server with hot reload
npm run dev

# Type checking
npm run type-check

# Linting
npm run lint

# Production build
npm run build

# Start production server
npm start
```

## Project Structure

```
web/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── layout.tsx          # Root layout
│   │   ├── page.tsx            # Home page (chat interface)
│   │   ├── globals.css         # Global styles
│   │   └── api/                # API routes
│   │       ├── chat/           # Chat endpoint
│   │       └── upload/         # File upload
│   ├── components/             # React components
│   │   └── chat/               # Chat-specific components
│   │       ├── ChatInterface.tsx
│   │       ├── MessageList.tsx
│   │       ├── Message.tsx
│   │       ├── ChatInput.tsx
│   │       └── ...
│   ├── hooks/                  # Custom React hooks
│   │   ├── useChat.ts
│   │   ├── useConversations.ts
│   │   └── useFileUpload.ts
│   ├── lib/                    # Utility functions
│   │   ├── api.ts              # API client
│   │   ├── storage.ts          # LocalStorage
│   │   └── streaming.ts        # SSE handling
│   └── types/                  # TypeScript definitions
│       └── chat.ts
├── public/                     # Static assets
├── package.json
├── next.config.js              # Next.js configuration
├── tailwind.config.ts          # Tailwind CSS config
└── tsconfig.json               # TypeScript config
```

## Features

- ✅ Real-time streaming chat
- ✅ Conversation history
- ✅ File upload support
- ✅ Responsive design
- ✅ TypeScript
- ✅ Tailwind CSS

## API Integration

The frontend connects to the mock API server at `http://localhost:8000` in development.

API endpoints used:
- `POST /v1/chat/completions` - Chat with streaming
- `POST /v1/files/upload` - File upload

## Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

See `.env.example` for all available options.

## Deployment

### Docker

```bash
# Build production image
docker build -t knowsee-web .

# Run container
docker run -p 3000:3000 knowsee-web
```

### Terraform (Cloud Run)

```bash
# From project root
cd terraform
make staging     # Deploy to staging
make prod        # Deploy to production
```

## Tech Stack

- **Framework**: Next.js 15.1.6 (App Router)
- **UI**: React 18.3.1
- **Language**: TypeScript 5.0
- **Styling**: Tailwind CSS 3.4
- **State**: Zustand 5.0
- **Deployment**: Cloud Run (Terraform)

## Development Tips

### Hot Reload
Changes to components automatically reload in development mode.

### Type Safety
Run `npm run type-check` to catch TypeScript errors before committing.

### Tailwind IntelliSense
Install the [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) VS Code extension for autocomplete.

### API Testing
Use the FastAPI docs at [http://localhost:8000/docs](http://localhost:8000/docs) to test API endpoints.

## Troubleshooting

### Port 3000 already in use

```bash
# Use different port
PORT=3001 npm run dev
```

### API connection errors

1. Ensure dev API is running: `cd ../dev && docker-compose ps`
2. Check API health: `curl http://localhost:8000/health`
3. Verify `.env.local` has correct `NEXT_PUBLIC_API_URL`

### Build errors

```bash
# Clear Next.js cache
rm -rf .next

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## Contributing

1. Create a feature branch
2. Make changes
3. Run `npm run type-check` and `npm run lint`
4. Test locally
5. Submit pull request
