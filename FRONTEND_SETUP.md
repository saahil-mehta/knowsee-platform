# Knowsee Frontend Setup Guide

This document provides a complete guide for setting up and using the new CoPilotKit + AG-UI frontend for Knowsee.

## What Was Built

A full-featured ChatGPT-like interface for your Knowsee agent with:

- **Modern React/Next.js frontend** with CoPilotKit UI components
- **FastAPI API layer** that wraps your ADK agent using AG-UI protocol
- **Seamless integration** with your existing ADK backend
- **Production-ready** with Docker and Cloud Run deployment support

## Architecture

```
┌───────────────────────┐         ┌────────────────────────┐         ┌──────────────────┐
│   Next.js Frontend    │────────▶│   FastAPI API (New)    │────────▶│   ADK Agent      │
│   CoPilotKit UI       │◀────────│   AG-UI Protocol       │◀────────│   (Existing)     │
│   localhost:3000      │  HTTP   │   localhost:8000       │         │   Vertex AI      │
└───────────────────────┘         └────────────────────────┘         └──────────────────┘
```

## New Files Created

### Backend API Layer
- `app/api.py` - FastAPI wrapper for ADK agent with AG-UI protocol

### Frontend Application
- `frontend/` - Complete Next.js application
  - `src/app/layout.tsx` - Root layout with CoPilotKit provider
  - `src/app/page.tsx` - Main chat interface
  - `src/app/globals.css` - Global styles and chat design tokens
  - `.env.example` / `.env.local` - Environment configuration
  - `Dockerfile` - Production container image
  - `next.config.ts` - Next.js configuration
  - `README.md` - Frontend-specific documentation

### Configuration Updates
- `pyproject.toml` - Added AG-UI and FastAPI dependencies
- `Makefile` - Added `api`, `frontend`, `dev`, and `install-frontend` commands
- `.gitignore` - Added Next.js specific ignores
- `README.md` - Updated with frontend quick start guide

## Getting Started

### Prerequisites

1. **Python environment** (already configured)
2. **Node.js 20+** with npm
3. **Google Cloud credentials** (already configured)

### Step 1: Install Dependencies

```bash
# Install Python dependencies (includes new AG-UI packages)
make install

# Install frontend dependencies
make install-frontend
```

### Step 2: Start Development Environment

#### Option A: Run Both Services Concurrently (Recommended)

```bash
make dev
```

This starts:
- API server on http://localhost:8000
- Frontend on http://localhost:3000

#### Option B: Run Services Separately

Terminal 1:
```bash
make api
```

Terminal 2:
```bash
make frontend
```

### Step 3: Access the Application

- **Frontend UI**: http://localhost:3000
- **API Documentation**: http://localhost:8000/docs
- **API Health Check**: http://localhost:8000/health

## Using the Frontend

1. Open http://localhost:3000 in your browser
2. You'll see a modern chat interface with:
   - Real-time streaming responses
   - Persistent conversation history within the current session
   - Typing composer with markdown support
   - Automatic status updates while tools execute

3. Try asking questions like:
   - "What documents do you have access to?"
   - "Find information about [your topic]"
   - Any question your agent can answer

## Development Workflow

### Making Changes to the Agent

1. Edit `app/agent.py` (your ADK agent)
2. Changes are automatically picked up by the API server
3. Frontend will use the updated agent

### Customising the Frontend

Edit these files:
- `frontend/src/app/page.tsx` - Chat layout and behaviour
- `frontend/src/app/layout.tsx` - CopilotKit provider and metadata
- `frontend/src/app/globals.css` - Styling

Changes are hot-reloaded automatically.

## Deployment

### Local Testing with Production Build

```bash
# Build frontend
cd frontend
npm run build
npm start
```

### Deploy to Cloud Run

#### Backend API

```bash
# Build and deploy API
gcloud builds submit --tag gcr.io/YOUR_PROJECT/knowsee-api app/
gcloud run deploy knowsee-api \
  --image gcr.io/YOUR_PROJECT/knowsee-api \
  --region europe-west2 \
  --allow-unauthenticated
```

#### Frontend

```bash
# Build and deploy frontend
cd frontend
gcloud builds submit --tag gcr.io/YOUR_PROJECT/knowsee-frontend \
  --build-arg NEXT_PUBLIC_AGENT_API_URL=https://YOUR_API_URL.run.app
gcloud run deploy knowsee-frontend \
  --image gcr.io/YOUR_PROJECT/knowsee-frontend \
  --region europe-west2 \
  --allow-unauthenticated \
  --set-env-vars NEXT_PUBLIC_AGENT_API_URL=https://YOUR_API_URL.run.app
```

## Troubleshooting

### API Connection Issues

**Problem**: Frontend can't connect to API

**Solutions**:
1. Verify API is running: `curl http://localhost:8000/health`
2. Check `frontend/.env.local` has correct `NEXT_PUBLIC_AGENT_API_URL`
3. Check browser console for CORS errors
4. Verify API CORS settings in `app/api.py`

### Module Import Errors

**Problem**: `ImportError: cannot import name 'ADKAgent' from 'ag_ui_adk'`

**Solution**:
```bash
# Reinstall dependencies
uv sync --reinstall
```

### Frontend Build Errors

**Problem**: TypeScript or build errors

**Solution**:
```bash
cd frontend
rm -rf node_modules .next
npm install
npm run dev
```

### Port Already in Use

**Problem**: Port 8000 or 3000 already in use

**Solutions**:
```bash
# Find and kill process on port 8000
lsof -ti:8000 | xargs kill -9

# Or use different ports
# Edit .env files to use different ports
```

## Next Steps

### Enhance the UI

1. **Add Custom Components**
   - Create components in `frontend/components/`
   - Display document previews
   - Show retrieval progress
   - Custom citation rendering

2. **Implement Human-in-the-Loop**
   - Add confirmation dialogs for agent actions
   - Feedback collection UI
   - Interactive tool approvals

3. **Improve State Visualization**
   - Show agent reasoning steps
   - Display tool call details
   - Progress indicators for long operations

### Production Readiness

1. **Security**
   - Set up Identity-Aware Proxy (IAP)
   - Restrict CORS origins
   - Add authentication/authorization
   - Use secrets manager for API keys

2. **Monitoring**
   - Add error tracking (Sentry, etc.)
   - Set up Cloud Logging
   - Create dashboards for metrics
   - Monitor API latency

3. **Performance**
   - Enable CDN for static assets
   - Implement caching strategy
   - Optimize bundle size
   - Add loading states

## Additional Resources

- Frontend Documentation: `frontend/README.md`
- API Documentation: http://localhost:8000/docs (when running)
- CoPilotKit Docs: https://docs.copilotkit.ai
- AG-UI Protocol: https://docs.ag-ui.com
- Google ADK: https://github.com/google/adk-python

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs from API and frontend
3. Refer to the documentation links
4. Check browser console for frontend errors
5. Check API logs for backend errors

## Summary

You now have:
- ✅ FastAPI API server exposing ADK agent via AG-UI protocol
- ✅ Modern Next.js frontend with CoPilotKit
- ✅ Development workflow with `make` commands
- ✅ Docker containerization for deployment
- ✅ Documentation and guides

The setup maintains your existing ADK agent while providing a professional, production-ready frontend interface!
