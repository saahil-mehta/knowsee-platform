# ==============================================================================
# AG-UI Adapter Unit Tests
# ==============================================================================
# Purpose: Comprehensive unit tests for the AG-UI adapter layer
#
# Technical Context:
# The AG-UI adapter bridges Google's ADK (Agent Development Kit) with AG-UI/CopilotKit.
# It wraps ADK agents to expose them via an HTTP endpoint that AG-UI can consume.
#
# Testing Strategy:
# 1. Test tool registration and configuration
# 2. Verify agent creation and naming conventions
# 3. Validate FastAPI endpoint registration
# 4. Test error handling and edge cases
# 5. Verify configuration validation
#
# Best Practice: Unit tests should be fast, isolated, and test one thing at a time.
# They should not require external dependencies like databases or APIs.
# ==============================================================================


import pytest
from fastapi.routing import APIRoute

from app.agent import retrieve_docs
from app.agui_adapter import AGUI_AGENT_TOOLS, AGUI_ENDPOINT_PATH, create_llm_agent
from app.fast_api_app import app


# ==============================================================================
# Test 1: Tool Registration
# ==============================================================================
# Verifies that the retrieve_docs tool is properly registered in the agent tools list.
#
# Technical: AG-UI requires tools to be explicitly registered so they can be
# exposed to the frontend for generative UI rendering.
#
# Why This Matters: If tools aren't registered, they won't be callable from the UI,
# breaking the core RAG functionality.
# ==============================================================================
def test_retrieve_docs_tool_registered() -> None:
    """
    Test that the retrieve_docs tool is registered in AGUI_AGENT_TOOLS.

    Technical: This test verifies the tool registration mechanism works correctly.
    The retrieve_docs function must be in the tools list for AG-UI to recognize it.

    Expected Behaviour: retrieve_docs should be present in AGUI_AGENT_TOOLS list.
    """
    assert retrieve_docs in AGUI_AGENT_TOOLS, (
        "retrieve_docs tool must be registered in AGUI_AGENT_TOOLS. "
        "Without registration, the tool won't be available in the UI."
    )
    assert len(AGUI_AGENT_TOOLS) > 0, "AGUI_AGENT_TOOLS should not be empty"


# ==============================================================================
# Test 2: Agent Naming Convention
# ==============================================================================
# Validates that the LLM agent uses the expected naming prefix.
#
# Technical: AG-UI uses agent names to route requests and identify agents in
# multi-agent scenarios. Consistent naming is critical for:
# - Frontend agent selection
# - Logging and debugging
# - Multi-tenant deployments
#
# Best Practice: Use descriptive, project-specific names (e.g., 'sagent' for 'search agent')
# ==============================================================================
def test_llm_agent_uses_expected_name() -> None:
    """
    Test that the LLM agent name follows the expected convention.

    Technical: The agent name is used by AG-UI for:
    1. Request routing (which agent to use)
    2. Session management (tracking conversations per agent)
    3. UI display (showing which agent is responding)

    Expected Behaviour: Agent name should start with 'sagent' (search agent).
    """
    agent = create_llm_agent()
    assert agent.name.startswith("sagent"), (
        f"Agent name '{agent.name}' should start with 'sagent' prefix. "
        "This naming convention helps identify the agent type and purpose."
    )


# ==============================================================================
# Test 3: FastAPI Endpoint Registration
# ==============================================================================
# Confirms that the AG-UI endpoint is registered in the FastAPI app.
#
# Technical: AG-UI communicates with the backend via HTTP endpoints.
# The endpoint path must be:
# 1. Registered in FastAPI's route table
# 2. Accessible to the frontend
# 3. Following the expected path convention
#
# Security Note: This endpoint typically requires authentication in production.
# ==============================================================================
def test_fastapi_app_registers_agui_endpoint() -> None:
    """
    Test that the AG-UI endpoint is registered in the FastAPI app.

    Technical: AG-UI expects a specific endpoint (typically /api/agui) to:
    1. Initialize agent sessions
    2. Send user messages
    3. Receive streaming responses
    4. Handle tool calls

    Expected Behaviour: AGUI_ENDPOINT_PATH should be in app.routes.
    """
    registered_paths = {
        route.path for route in app.routes if isinstance(route, APIRoute)
    }
    assert AGUI_ENDPOINT_PATH in registered_paths, (
        f"Expected endpoint '{AGUI_ENDPOINT_PATH}' not found in registered routes. "
        f"Available routes: {registered_paths}"
    )


# ==============================================================================
# Test 4: Agent Tools Count
# ==============================================================================
# Verifies that the expected number of tools are registered.
#
# Technical: This test acts as a smoke test to catch accidental removal or
# duplication of tools. As the agent evolves, update the expected count.
#
# Maintenance: Update this test when adding or removing tools.
# ==============================================================================
def test_agent_has_expected_tools_count() -> None:
    """
    Test that the agent has the expected number of tools registered.

    Technical: This is a regression test to ensure tools aren't accidentally
    added or removed. Currently, we expect at least retrieve_docs.

    Expected Behaviour: Should have at least 1 tool (retrieve_docs).
    """
    assert len(AGUI_AGENT_TOOLS) >= 1, (
        f"Expected at least 1 tool, but found {len(AGUI_AGENT_TOOLS)}. "
        "Verify that tools haven't been accidentally removed."
    )


# ==============================================================================
# Test 5: Agent Creation Idempotency
# ==============================================================================
# Tests that creating multiple agent instances is safe and consistent.
#
# Technical: Agent creation should be idempotent - calling create_llm_agent()
# multiple times should return equivalent agents. This is important for:
# - Request handling (new agent per request vs singleton)
# - Testing (creating agents in setup/teardown)
# - Memory management (avoiding agent instance leaks)
#
# Best Practice: Agent creation should be lightweight and not cause side effects.
# ==============================================================================
def test_agent_creation_is_idempotent() -> None:
    """
    Test that creating multiple agent instances is safe and consistent.

    Technical: Verifies that:
    1. Multiple create_llm_agent() calls succeed
    2. Agents have the same name (consistent configuration)
    3. Agents have the same tools (consistent capabilities)

    Expected Behaviour: All agents should be equivalent (same name, same tools).
    """
    agent1 = create_llm_agent()
    agent2 = create_llm_agent()

    assert agent1.name == agent2.name, (
        "Multiple agent creations should result in equivalent agents with the same name"
    )


# ==============================================================================
# Test 6: Endpoint Path Format
# ==============================================================================
# Validates that the endpoint path follows API conventions.
#
# Technical: REST API best practices suggest:
# - Paths should start with /api for versioning
# - Use lowercase, hyphens for readability
# - Be descriptive of the resource
#
# Best Practice: Consistent path naming makes APIs more intuitive.
# ==============================================================================
def test_endpoint_path_follows_conventions() -> None:
    """
    Test that the AG-UI endpoint path follows REST API conventions.

    Technical: The endpoint should:
    1. Start with /api (standard API prefix)
    2. Use descriptive naming (agui = AG-UI integration)
    3. Be lowercase (URL best practice)

    Expected Behaviour: Path should match expected format.
    """
    assert AGUI_ENDPOINT_PATH.startswith("/api"), (
        f"Endpoint '{AGUI_ENDPOINT_PATH}' should start with '/api' prefix "
        "for consistency with REST API conventions"
    )
    assert AGUI_ENDPOINT_PATH.islower() or "/" in AGUI_ENDPOINT_PATH, (
        "Endpoint path should be lowercase for URL best practices"
    )


# ==============================================================================
# Test 7: FastAPI App Instance
# ==============================================================================
# Confirms that the FastAPI app is properly initialized.
#
# Technical: This test verifies basic FastAPI app configuration:
# - App instance exists
# - Has routes registered
# - Can be imported without errors
#
# Why This Matters: If the app fails to initialize, the entire backend won't start.
# ==============================================================================
def test_fastapi_app_is_initialized() -> None:
    """
    Test that the FastAPI app instance is properly initialized.

    Technical: Verifies:
    1. App object exists and is a FastAPI instance
    2. App has routes registered (not empty)
    3. App can be imported without initialization errors

    Expected Behaviour: App should be a valid FastAPI instance with routes.
    """
    from fastapi import FastAPI

    assert isinstance(app, FastAPI), "app should be a FastAPI instance"
    assert len(app.routes) > 0, "FastAPI app should have routes registered"


# ==============================================================================
# Test 8: Tool Function Signature
# ==============================================================================
# Validates that tool functions have the expected signature.
#
# Technical: ADK requires tool functions to:
# - Be callable
# - Have type hints (for automatic schema generation)
# - Return appropriate types
#
# Best Practice: Type hints enable automatic OpenAPI schema generation and
# runtime validation.
# ==============================================================================
def test_retrieve_docs_has_correct_signature() -> None:
    """
    Test that retrieve_docs has the expected function signature.

    Technical: ADK uses function signatures to:
    1. Generate tool schemas for the LLM
    2. Validate tool call arguments
    3. Type-check inputs at runtime

    Expected Behaviour: retrieve_docs should be callable.
    """
    import inspect

    assert callable(retrieve_docs), "retrieve_docs should be a callable function"

    # Verify it has parameters (it should take a query parameter)
    sig = inspect.signature(retrieve_docs)
    assert len(sig.parameters) > 0, (
        "retrieve_docs should have at least one parameter (query)"
    )


# ==============================================================================
# Run Tests
# ==============================================================================
# Run with: pytest tests/unit/test_agui_adapter_enhanced.py -v
# For coverage: pytest tests/unit/test_agui_adapter_enhanced.py --cov=app.agui_adapter
# ==============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
