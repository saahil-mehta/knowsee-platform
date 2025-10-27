# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
FastAPI API server for the Knowsee agent using AG-UI protocol.

This module provides a web API interface for the ADK agent, enabling
frontend applications (like CoPilotKit) to interact with the agent
via the AG-UI protocol.
"""

import logging
import os
from typing import Any

from ag_ui_adk import ADKAgent, add_adk_fastapi_endpoint
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.agent import root_agent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI application
app = FastAPI(
    title="Knowsee Agent API",
    description="ADK RAG agent API for document retrieval and Q&A using AG-UI protocol",
    version="0.1.0",
)

# Configure CORS for frontend access
# In production, restrict this to your frontend domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create ADK Agent wrapper with AG-UI protocol support
knowsee_agent = ADKAgent(
    adk_agent=root_agent,
    app_name="knowsee",
    user_id=os.getenv("DEFAULT_USER_ID", "default_user"),
    session_timeout_seconds=int(os.getenv("SESSION_TIMEOUT", "3600")),
    use_in_memory_services=True,  # Use in-memory sessions for local dev
)

# Add the AG-UI endpoint to FastAPI
# This exposes the agent via AG-UI protocol at the root path
add_adk_fastapi_endpoint(
    app=app,
    agent=knowsee_agent,
    path="/",
)


@app.get("/health")
async def health_check() -> dict[str, Any]:
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "service": "knowsee-api",
        "agent": "root_agent",
    }


@app.get("/info")
async def agent_info() -> dict[str, Any]:
    """Returns information about the agent."""
    return {
        "name": "Knowsee",
        "description": "ADK RAG agent for document retrieval and Q&A",
        "model": root_agent.model,
        "capabilities": [
            "document_retrieval",
            "question_answering",
            "rag",
        ],
    }


def main() -> None:
    """Run the API server with uvicorn."""
    import uvicorn

    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    reload = os.getenv("RELOAD", "True").lower() == "true"

    logger.info(f"Starting Knowsee API server on {host}:{port}")
    logger.info(f"API documentation available at http://{host}:{port}/docs")

    uvicorn.run(
        "app.api:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info",
    )


if __name__ == "__main__":
    main()
