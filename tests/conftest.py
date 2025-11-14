# ==============================================================================
# Pytest Configuration and Fixtures
# ==============================================================================
# Purpose: Global test configuration and fixtures for unit and integration tests
#
# Technical Context:
# This file is automatically loaded by pytest before running any tests.
# It provides:
# 1. Mock external dependencies (GCS, GCP auth, LLM) to enable offline testing
# 2. Common fixtures shared across test modules
# 3. Test environment configuration
#
# Best Practice: Mock external dependencies at the module level to prevent
# tests from requiring live credentials or network access.
# ==============================================================================

from collections.abc import AsyncGenerator
from typing import Any
from unittest.mock import MagicMock, patch

import pytest
from google.genai import types

# ==============================================================================
# Mock LLM Response Generator
# ==============================================================================
# Problem: Integration tests call Gemini LLM APIs which require credentials
# and cost money per call.
#
# Solution: Mock the LLM client to return realistic streaming responses
# without making actual API calls.
# ==============================================================================


async def mock_generate_content_stream(
    *args: Any, **kwargs: Any
) -> AsyncGenerator[Any, None]:
    """
    Mock Gemini streaming response for testing.

    Yields realistic streaming events that match Gemini's actual response format
    as documented in googleapis/python-genai.

    Technical: Gemini streaming responses yield multiple chunks with text, candidates,
    and finish_reason. We simulate a simple single-chunk response for testing.
    """
    # Create a mock response object that matches genai response structure
    mock_response = MagicMock()
    mock_response.text = "This is a mock response from the AI assistant."

    # Create candidates list with proper structure
    mock_candidate = MagicMock()
    mock_candidate.content = types.Content(
        role="model",
        parts=[
            types.Part.from_text(text="This is a mock response from the AI assistant.")
        ],
    )
    mock_candidate.finish_reason = 1  # STOP
    mock_response.candidates = [mock_candidate]

    # Yield the response as an async generator (streaming)
    yield mock_response


# ==============================================================================
# Mock External Dependencies at pytest startup
# ==============================================================================
# Problem: app/fast_api_app.py calls create_bucket_if_not_exists() at module
# import time, which requires GCP credentials. This breaks unit tests.
#
# Solution: Use pytest_configure hook to mock external services before any
# test modules are imported.
# ==============================================================================


def pytest_configure(config: pytest.Config) -> None:
    """
    pytest hook that runs before test collection.

    This is the earliest hook where we can set up mocks before any test
    modules import app code that requires GCP credentials.

    Technical: app/agent.py and app/fast_api_app.py have module-level code that:
    1. Calls google.auth.default() to get GCP credentials
    2. Initialises VertexAI embedding models (calls Vertex AI APIs)
    3. Creates GCS buckets (calls Storage APIs)
    4. Sets up Cloud Logging clients

    All of these must be mocked before importing any app modules.
    """
    # Mock google.auth.default() to prevent GCP credential lookups
    # Important: Use real values for credential properties to avoid serialization errors
    mock_credentials = MagicMock()
    mock_credentials.quota_project_id = None  # Must be None or string, not MagicMock
    mock_credentials.token = "mock-token"
    mock_project_id = "test-project-id"

    # Mock agent engine (used in fast_api_app.py:53)
    mock_agent_engine = MagicMock()
    mock_agent_engine.resource_name = (
        "projects/test-project-id/locations/europe-west2/reasoningEngines/test-agent"
    )

    # Mock Gemini LLM client for integration tests
    mock_genai_client = MagicMock()
    mock_genai_client.aio.models.generate_content_stream = mock_generate_content_stream

    # Set up persistent mocks that will be active for all tests
    # These must be in place BEFORE any app modules are imported
    patch(
        "google.auth.default", return_value=(mock_credentials, mock_project_id)
    ).start()
    patch("vertexai.init", return_value=None).start()
    patch(
        "langchain_google_vertexai.VertexAIEmbeddings", return_value=MagicMock()
    ).start()
    patch("google.cloud.logging.Client", return_value=MagicMock()).start()
    patch("google.cloud.storage.Client", return_value=MagicMock()).start()
    patch("vertexai.agent_engines.list", return_value=[mock_agent_engine]).start()
    patch("vertexai.agent_engines.create", return_value=mock_agent_engine).start()
    patch("google.genai.Client", return_value=mock_genai_client).start()


@pytest.fixture(autouse=True, scope="session")
def mock_gcp_services() -> None:
    """
    Session-scoped fixture to mock GCP services.

    This fixture runs once at the start of the test session and ensures
    that all GCP-related external calls are mocked.
    """
    # These are already patched in pytest_configure, but we keep this fixture
    # for documentation and potential future use
    yield
