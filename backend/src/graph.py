"""LangGraph chatbot implementation using Vertex AI.

Includes resilience patterns with retry logic and timeout handling.
"""

import os
from typing import Annotated

from dotenv import load_dotenv
from langchain_core.messages import BaseMessage
from langchain_google_vertexai import ChatVertexAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from langgraph.graph.state import CompiledStateGraph
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential_jitter,
)
from typing_extensions import TypedDict

from backend.src.observability import VertexAIError, get_logger

# Load environment variables from root .env
load_dotenv()

logger = get_logger(__name__)

# Resilience configuration from environment
LLM_TIMEOUT_SECONDS = int(os.getenv("LLM_TIMEOUT_SECONDS", "30"))
LLM_MAX_RETRIES = int(os.getenv("LLM_MAX_RETRIES", "3"))


class ChatState(TypedDict):
    """State container for the chatbot.

    The messages field uses add_messages reducer to automatically
    append new messages rather than replacing the entire list.
    """

    messages: Annotated[list[BaseMessage], add_messages]


def create_chatbot_graph() -> CompiledStateGraph:
    """Create and compile the chatbot graph.

    Returns:
        Compiled LangGraph application ready for invocation.
    """
    # Initialise Vertex AI LLM (uses ADC auth)
    # Note: Timeout is handled at the retry layer, not the client level
    llm = ChatVertexAI(
        model="gemini-2.5-flash",
        project=os.getenv("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development"),
        location=os.getenv("GOOGLE_CLOUD_LOCATION", "europe-west2"),
        temperature=0.7,
    )

    @retry(
        stop=stop_after_attempt(LLM_MAX_RETRIES),
        wait=wait_exponential_jitter(initial=1, max=10, jitter=2),
        retry=retry_if_exception_type((ConnectionError, TimeoutError)),
        before_sleep=lambda retry_state: logger.warning(
            "LLM call failed, retrying",
            attempt=retry_state.attempt_number,
            wait_seconds=getattr(retry_state.next_action, "sleep", 0),
        ),
        reraise=True,
    )
    def invoke_llm_with_retry(messages: list[BaseMessage]) -> BaseMessage:
        """Invoke LLM with retry logic for transient failures.

        Args:
            messages: Conversation history.

        Returns:
            AI response message.

        Raises:
            VertexAIError: If all retries fail.
        """
        try:
            return llm.invoke(messages)
        except Exception as e:
            error_str = str(e).lower()
            # Check for retryable errors
            if any(code in error_str for code in ["429", "500", "503", "timeout"]):
                logger.warning("Transient LLM error, will retry", error=str(e))
                raise ConnectionError(str(e)) from e
            # Non-retryable error
            logger.error("LLM invocation failed", error=str(e))
            raise VertexAIError(f"LLM invocation failed: {e}") from e

    def chatbot_node(state: ChatState) -> ChatState:
        """Process messages and generate a response.

        Args:
            state: Current conversation state with message history.

        Returns:
            Partial state update containing the new AI message.
        """
        try:
            response = invoke_llm_with_retry(state["messages"])
            return {"messages": [response]}
        except Exception as e:
            logger.error("Chatbot node failed", error=str(e))
            raise

    # Build the graph
    graph_builder = StateGraph(ChatState)
    graph_builder.add_node("chatbot", chatbot_node)
    graph_builder.add_edge(START, "chatbot")
    graph_builder.add_edge("chatbot", END)

    return graph_builder.compile()


# Pre-compiled graph instance for reuse
chatbot_graph = create_chatbot_graph()
