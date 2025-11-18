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

"""Unit tests for agent creation and configuration."""

from google.adk.agents import Agent

from app.agent import create_agent


def test_create_agent_with_default_tools() -> None:
    """Test creating an agent with default tools."""
    # Act
    agent = create_agent()

    # Assert
    assert isinstance(agent, Agent)
    assert agent.name == "root_agent"
    assert agent.model == "gemini-2.0-flash"
    assert len(agent.tools) > 0  # Should have retrieve_docs by default


def test_create_agent_with_custom_tools() -> None:
    """Test creating an agent with custom (mocked) tools."""

    # Arrange
    def mock_tool(query: str) -> str:
        """Mock tool for testing"""
        return "mock result"

    # Act
    agent = create_agent(tools=[mock_tool])

    # Assert
    assert isinstance(agent, Agent)
    assert len(agent.tools) == 1
    assert agent.tools[0] == mock_tool


def test_create_agent_with_empty_tools_list() -> None:
    """Test creating an agent with explicitly empty tools list."""
    # Act
    agent = create_agent(tools=[])

    # Assert
    assert isinstance(agent, Agent)
    assert len(agent.tools) == 0


def test_create_agent_with_multiple_tools() -> None:
    """Test creating an agent with multiple custom tools."""

    # Arrange
    def tool1(query: str) -> str:
        """Tool 1"""
        return "result1"

    def tool2(query: str) -> str:
        """Tool 2"""
        return "result2"

    # Act
    agent = create_agent(tools=[tool1, tool2])

    # Assert
    assert isinstance(agent, Agent)
    assert len(agent.tools) == 2


def test_create_agent_has_correct_instruction() -> None:
    """Test that created agent has the expected instruction."""
    # Act
    agent = create_agent()

    # Assert
    assert agent.instruction is not None
    instruction_str = str(agent.instruction)
    assert "AI assistant" in instruction_str
    assert "question-answering" in instruction_str
