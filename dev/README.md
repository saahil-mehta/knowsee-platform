# Shadow Knowsee Development Environment

This directory contains the local development environment for Shadow Knowsee, including a mock GPT-OSS-120B API server.

## Quick Start

```bash
# Copy environment file
cp .env.example .env

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## Services

### Mock API Server (Port 8000)
- **URL**: http://localhost:8000
- **Docs**: http://localhost:8000/docs (FastAPI auto-generated)
- **Health**: http://localhost:8000/health

Provides OpenAI-compatible API endpoints for local development:
- `POST /v1/chat/completions` - Chat with streaming support
- `POST /v1/files/upload` - File upload (mock)

### Redis (Port 6379)
- Optional caching and session storage
- Will be used for conversation persistence in future

## Configuration

Edit `.env` file to customize:

```env
# Streaming delay (milliseconds between tokens)
MOCK_DELAY_MS=50

# Enable/disable streaming
STREAMING_ENABLED=true
```

## API Usage Examples

### Streaming Chat (curl)

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'
```

### Non-Streaming Chat

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

### Health Check

```bash
curl http://localhost:8000/health
```

## Development Workflow

1. **Start services**: `docker-compose up -d`
2. **Start frontend**: `cd ../web && npm run dev`
3. **Make changes**: API code hot-reloads automatically
4. **View logs**: `docker-compose logs -f api`
5. **Stop services**: `docker-compose down`

## Mock API Features

The mock API simulates GPT-OSS-120B behavior with:
- ✅ Streaming responses (Server-Sent Events)
- ✅ OpenAI-compatible API format
- ✅ Configurable delay for realistic streaming
- ✅ Different responses based on user input
- ✅ Health checks for Docker
- ✅ CORS enabled for local frontend

## Switching to Real Model

When ready to test with the actual GPT-OSS-120B model:

1. Update `.env` with Vertex AI credentials
2. Modify `docker-compose.yml` to point to Vertex AI endpoint
3. Or deploy to staging/prod using Terraform

## Troubleshooting

### Port already in use

```bash
# Find process using port 8000
lsof -ti:8000 | xargs kill -9

# Or use different port in docker-compose.yml
ports:
  - "8001:8000"
```

### Services not starting

```bash
# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### View all logs

```bash
docker-compose logs --tail=100 -f
```

## Next Steps

After dev environment is running:
1. Initialize the frontend in `../web`
2. Connect frontend to http://localhost:8000
3. Start building the chat interface!
