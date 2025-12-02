"""LangGraph chatbot implementation using Vertex AI.

Uses direct LLM binding for proper streaming support with astream_events().
"""

import os
from typing import Annotated

from dotenv import load_dotenv
from langchain_core.messages import BaseMessage
from langchain_google_vertexai import ChatVertexAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from langgraph.graph.state import CompiledStateGraph
from typing_extensions import TypedDict

from backend.src.observability import get_logger

# Load environment variables from root .env
load_dotenv()

logger = get_logger(__name__)


class ChatState(TypedDict):
    """State container for the chatbot.

    The messages field uses add_messages reducer to automatically
    append new messages rather than replacing the entire list.
    """

    messages: Annotated[list[BaseMessage], add_messages]


# Create LLM instance at module level for reuse
_chat_llm = ChatVertexAI(
    model="gemini-2.5-flash",
    project=os.getenv("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development"),
    location=os.getenv("GOOGLE_CLOUD_LOCATION", "europe-west2"),
    temperature=0.7,
    streaming=True,  # Explicitly enable streaming
)


def create_chatbot_graph() -> CompiledStateGraph:
    """Create and compile the chatbot graph.

    Returns:
        Compiled LangGraph application ready for invocation.
    """

    async def chatbot_node(state: ChatState) -> ChatState:
        """Process messages and generate a response.

        Uses async invocation to allow LangGraph's astream_events()
        to intercept and stream tokens properly.

        Args:
            state: Current conversation state with message history.

        Returns:
            Partial state update containing the new AI message.
        """
        response = await _chat_llm.ainvoke(state["messages"])
        return {"messages": [response]}

    # Build the graph
    graph_builder = StateGraph(ChatState)
    graph_builder.add_node("chatbot", chatbot_node)
    graph_builder.add_edge(START, "chatbot")
    graph_builder.add_edge("chatbot", END)

    return graph_builder.compile()


# Pre-compiled graph instance for reuse
chatbot_graph = create_chatbot_graph()


# Title generation LLM (lighter config, lower temperature for consistency)
# Note: Gemini 2.5 Flash uses "thinking" tokens internally, so max_output_tokens
# must be high enough to cover both thinking overhead (~50-100) and actual output.
_title_llm = ChatVertexAI(
    model="gemini-2.5-flash",
    project=os.getenv("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development"),
    location=os.getenv("GOOGLE_CLOUD_LOCATION", "europe-west2"),
    temperature=0.3,
    max_output_tokens=256,
)

TITLE_PROMPT = """Generate a short, concise title (max 6 words) for this chat.
Return ONLY the title, no quotes or punctuation at the end.

Message: {message}"""


async def generate_title(message: str) -> str:
    """Generate a chat title from the first user message.

    Args:
        message: The user's first message in the chat.

    Returns:
        A short title string (max ~6 words).
    """
    try:
        response = await _title_llm.ainvoke(TITLE_PROMPT.format(message=message))
        title = response.content if isinstance(response.content, str) else str(response.content)
        # Clean up and truncate
        title = title.strip().strip('"').strip("'")
        return title[:80] if len(title) > 80 else title
    except Exception as e:
        logger.warning("Title generation failed, using fallback", error=str(e))
        # Fallback: use first 50 chars of message
        return message[:50] + "..." if len(message) > 50 else message
