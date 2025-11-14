from fastapi.routing import APIRoute

from app.agui_adapter import AGUI_AGENT_TOOLS, AGUI_ENDPOINT_PATH, create_llm_agent
from app.agent import retrieve_docs
from app.fast_api_app import app


def test_retrieve_docs_tool_registered() -> None:
  assert retrieve_docs in AGUI_AGENT_TOOLS


def test_llm_agent_uses_expected_name() -> None:
  agent = create_llm_agent()
  assert agent.name.startswith("sagent"), "Copilot agent should use sagent prefix"


def test_fastapi_app_registers_agui_endpoint() -> None:
  registered_paths = {route.path for route in app.routes if isinstance(route, APIRoute)}
  assert AGUI_ENDPOINT_PATH in registered_paths
