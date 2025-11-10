"""Utilities to mount the AG-UI adapter for CopilotKit."""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Iterable

from ag_ui_adk import ADKAgent, add_adk_fastapi_endpoint
from fastapi import FastAPI
from google.adk.agents import LlmAgent

from app.agent import LLM, instruction, retrieve_docs

AGUI_ENDPOINT_PATH = os.getenv("AGUI_ENDPOINT_PATH", "/api/agui")
AGUI_AGENT_NAME = os.getenv("AGUI_AGENT_NAME", "sagent_copilot")
AGUI_APP_NAME = os.getenv("AGUI_APP_NAME", "knowsee_copilot")
AGUI_DEFAULT_USER = os.getenv("AGUI_DEFAULT_USER", "web-user")
AGUI_SESSION_TIMEOUT = int(os.getenv("AGUI_SESSION_TIMEOUT", "3600"))

AGUI_AGENT_TOOLS: Iterable = (retrieve_docs,)


def _build_instruction() -> str:
    suffix = (
        "You are the streaming assistant that powers the CopilotKit sidebar. "
        "Use the provided tools when the user needs factual context and defer "
        "UI mutations to the frontend actions exposed through CopilotKit."
    )
    return f"{instruction}\n\n{suffix}"


def create_llm_agent() -> LlmAgent:
    """Create the underlying ADK LLM agent the middleware will wrap."""

    return LlmAgent(
        name=AGUI_AGENT_NAME,
        model=LLM,
        instruction=_build_instruction(),
        tools=list(AGUI_AGENT_TOOLS),
    )


@lru_cache(maxsize=1)
def _get_adk_agent() -> ADKAgent:
    return ADKAgent(
        adk_agent=create_llm_agent(),
        app_name=AGUI_APP_NAME,
        user_id=AGUI_DEFAULT_USER,
        session_timeout_seconds=AGUI_SESSION_TIMEOUT,
        use_in_memory_services=True,
    )


def register_agui(app: FastAPI) -> None:
    """Expose the AG-UI endpoint so CopilotKit can relay traffic."""

    add_adk_fastapi_endpoint(app, _get_adk_agent(), path=AGUI_ENDPOINT_PATH)


__all__ = [
    "AGUI_AGENT_TOOLS",
    "AGUI_ENDPOINT_PATH",
    "create_llm_agent",
    "register_agui",
]
