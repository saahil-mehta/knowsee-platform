# Shadow Knowsee

AI-powered chat interface using GPT-OSS-120B, built with Next.js 15 and deployed on Google Cloud Platform.

## Project Structure

```
knowsee/
├── dev/                    # Development environment
│   ├── api/                # Mock API server (FastAPI)
│   └── docker-compose.yml  # Docker services for dev
├── web/                    # Frontend application
│   ├── src/
│   │   ├── app/            # Next.js App Router
│   │   ├── components/     # React components
│   │   ├── hooks/          # Custom hooks
│   │   ├── lib/            # Utilities
│   │   └── types/          # TypeScript types
│   └── Dockerfile          # Production build
└── terraform/              # Infrastructure as Code
    ├── modules/            # Reusable modules
    ├── infra/              # Shared infrastructure templates
    ├── permissions/        # IAM templates
    └── environments/       # Environment configs
        ├── staging/
        └── prod/
```

## Quick Start

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- Python 3.11+ (for API development)
- Terraform (for deployment)

### 1. Start Development Environment

```bash
# Start mock API server
cd dev
docker-compose up -d

# Verify API is running
curl http://localhost:8000/health
```

### 2. Start Frontend

```bash
# Install dependencies
cd web
npm install

# Copy environment file
cp .env.example .env.local

# Start development server
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

## Features

- ✅ Real-time streaming chat interface
- ✅ Conversation history (LocalStorage)
- ✅ File upload support
- ✅ Responsive design (mobile-friendly)
- ✅ TypeScript & type-safe
- ✅ Dark mode support
- ✅ Production-ready deployment

## Architecture

### Development
```
┌─────────────────┐
│  Frontend       │
│  Next.js :3000  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Mock API       │
│  FastAPI :8000  │
└─────────────────┘
```

### Production
```
┌─────────────────┐
│  Frontend       │
│  Cloud Run      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  GPT-OSS-120B   │
│  Vertex AI      │
└─────────────────┘
```

## Development Workflow

### Running the Full Stack

```bash
# Terminal 1: Start API
cd dev
docker-compose up

# Terminal 2: Start Frontend
cd web
npm run dev
```

### Testing the API

```bash
# Stream chat
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}], "stream": true}'

# Check health
curl http://localhost:8000/health
```

### Code Quality

```bash
cd web
npm run type-check  # TypeScript checking
npm run lint        # ESLint
npm run build       # Production build test
```

## Deployment

### Deploy to Staging

```bash
# Configure Terraform
cd terraform
make staging-init

# Deploy infrastructure + frontend
make staging
```

### Deploy to Production

```bash
make prod
```

## Configuration

### Environment Variables

**Development (`dev/.env`):**
```env
MOCK_DELAY_MS=50
STREAMING_ENABLED=true
```

**Frontend (`web/.env.local`):**
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**Production (Terraform):**
- `terraform/environments/staging/terraform.tfvars`
- `terraform/environments/prod/terraform.tfvars`

## Project Details

### Tech Stack

**Frontend:**
- Next.js 15.1.6 (App Router, Server Components)
- React 18.3.1
- TypeScript 5.0
- Tailwind CSS 3.4
- Zustand (state management)

**Backend (Dev):**
- FastAPI
- Python 3.11
- Uvicorn
- OpenAI-compatible API

**Infrastructure:**
- Google Cloud Platform
- Vertex AI (model hosting)
- Cloud Run (frontend)
- Cloud Storage (files)
- Terraform (IaC)

### Key Components

**Frontend:**
- `ChatInterface` - Main container
- `MessageList` - Scrollable messages
- `Message` - Individual message bubble
- `ChatInput` - Input with send button

**Hooks:**
- `useChat` - Chat logic & streaming
- `useConversations` - History management

**API Client:**
- `streamChatCompletion` - SSE streaming
- `uploadFile` - File upload

## Troubleshooting

### Port conflicts

```bash
# Check what's using port 3000
lsof -ti:3000 | xargs kill -9

# Check what's using port 8000
lsof -ti:8000 | xargs kill -9
```

### Docker issues

```bash
# Rebuild containers
cd dev
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### Frontend build errors

```bash
cd web
rm -rf .next node_modules
npm install
npm run build
```

## Documentation

- [Dev Environment](./dev/README.md) - Local development setup
- [Frontend](./web/README.md) - Web application details
- [Terraform](./terraform/README.md) - Infrastructure guide
- [Architecture](./terraform/ARCHITECTURE.md) - System design

## Roadmap

### Phase 1 (Current - MVP)
- ✅ Basic chat interface
- ✅ Streaming responses
- ✅ Conversation history
- ✅ File upload support
- ✅ Dev environment
- ✅ Terraform setup

### Phase 2 (Next)
- [ ] User authentication
- [ ] Multi-model support
- [ ] Enhanced file handling
- [ ] Markdown/code rendering
- [ ] Search conversations
- [ ] Share conversations

### Phase 3 (Future)
- [ ] RAG capabilities
- [ ] Voice input
- [ ] Image generation
- [ ] Function calling
- [ ] Admin dashboard
- [ ] Usage analytics

## Contributing

This is a private project. For questions or suggestions, contact the team.

## License

Private - All rights reserved

---

**Built with ❤️ using Next.js, FastAPI, and Google Cloud Platform**
