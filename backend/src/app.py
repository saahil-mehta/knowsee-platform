"""FastAPI application exposing the LangGraph chatbot."""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_core.messages import AIMessage, HumanMessage
from pydantic import BaseModel

from backend.src.graph import chatbot_graph

app = FastAPI(
    title="Knowsee Chatbot API",
    description="Simple LangGraph chatbot powered by Gemini 2.5 Flash",
    version="0.1.0",
)

# CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    """Request model for chat endpoint."""

    message: str


class ChatResponse(BaseModel):
    """Response model for chat endpoint."""

    response: str


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    """Process a chat message and return the response.

    Args:
        request: Chat request containing the user message.

    Returns:
        ChatResponse with the AI-generated response.
    """
    try:
        # Invoke the graph with the user message
        result = chatbot_graph.invoke({
            "messages": [HumanMessage(content=request.message)]
        })

        # Extract the AI response from the messages
        ai_messages = [
            msg for msg in result["messages"]
            if isinstance(msg, AIMessage)
        ]

        if not ai_messages:
            raise HTTPException(
                status_code=500,
                detail="No response generated"
            )

        return ChatResponse(response=ai_messages[-1].content)

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing request: {str(e)}"
        ) from e
