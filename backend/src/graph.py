"""LangGraph chatbot implementation using Gemini 2.5 Flash via Vertex AI."""

import os
from typing import Annotated

from dotenv import load_dotenv
from langchain_core.messages import BaseMessage
from langchain_google_vertexai import ChatVertexAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict

# Load environment variables from root .env
load_dotenv()


class ChatState(TypedDict):
    """State container for the chatbot.

    The messages field uses add_messages reducer to automatically
    append new messages rather than replacing the entire list.
    """

    messages: Annotated[list[BaseMessage], add_messages]


def create_chatbot_graph() -> StateGraph:
    """Create and compile the chatbot graph.

    Returns:
        Compiled LangGraph application ready for invocation.
    """
    # Initialise Gemini 2.5 Flash via Vertex AI (uses ADC auth)
    llm = ChatVertexAI(
        model="gemini-2.5-flash",
        project=os.getenv("GOOGLE_CLOUD_PROJECT", "knowsee-platform-development"),
        location=os.getenv("GOOGLE_CLOUD_LOCATION", "europe-west2"),
        temperature=0.7,
    )

    def chatbot_node(state: ChatState) -> ChatState:
        """Process messages and generate a response.

        Args:
            state: Current conversation state with message history.

        Returns:
            Partial state update containing the new AI message.
        """
        response = llm.invoke(state["messages"])
        return {"messages": [response]}

    # Build the graph
    graph_builder = StateGraph(ChatState)
    graph_builder.add_node("chatbot", chatbot_node)
    graph_builder.add_edge(START, "chatbot")
    graph_builder.add_edge("chatbot", END)

    return graph_builder.compile()


# Pre-compiled graph instance for reuse
chatbot_graph = create_chatbot_graph()
