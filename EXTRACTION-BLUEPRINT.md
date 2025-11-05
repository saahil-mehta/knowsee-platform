# THE COMPLETE ONYX EXTRACTION BLUEPRINT
## From 100,000 Lines to Your Lean 10,000-Line Knowsee Platform

**Your Mission:** Cherry-pick brilliance, discard bloat, ship in 2 weeks.

---

# TABLE OF CONTENTS

1. [Extraction Priority & Timeline](#extraction-priority)
2. [Component 1: Connector Framework](#component-1-connector-framework)
3. [Component 2: Document Processing](#component-2-document-processing)
4. [Component 3: OAuth & Credentials](#component-3-oauth-credentials)
5. [Component 4: Vector Search](#component-4-vector-search)
6. [Component 5: LLM/Chat Interface](#component-5-llm-chat)
7. [Component 6: Background Jobs](#component-6-background-jobs)
8. [Component 7: Database Models](#component-7-database-models)
9. [Component 8: API Structure](#component-8-api-structure)
10. [What to IGNORE (Enterprise Bloat)](#what-to-ignore)
11. [The 7-Day Extraction Plan](#7-day-extraction-plan)
12. [Knowsee vs Onyx: Architecture Comparison](#architecture-comparison)

---

<a name="extraction-priority"></a>
# 📊 EXTRACTION PRIORITY & TIMELINE

## Week 1: Foundation (Days 1-5)

| Day | Component | Files to Extract | LOC | Result |
|-----|-----------|------------------|-----|--------|
| **1** | Base Connector Interface | 1 file | ~300 | Connector framework |
| **2** | Document Model & Chunking | 2 files | ~500 | Document processing |
| **3** | OAuth Flow | 3 files | ~400 | OAuth working |
| **4** | Credential Storage | 2 files | ~200 | Secure credentials |
| **5** | Database Models (simplified) | 3 files | ~600 | Data layer |

**Total Week 1: ~2,000 lines extracted**

## Week 2: Features (Days 6-10)

| Day | Component | Files to Extract | LOC | Result |
|-----|-----------|------------------|-----|--------|
| **6** | DLT Wrapper | 1 file | ~300 | Marketing connectors |
| **7** | Search Logic | 2 files | ~400 | Vector search ready |
| **8** | LLM Streaming | 2 files | ~300 | Chat interface |
| **9** | Background Jobs | 1 file | ~200 | Task queue |
| **10** | Polish & Deploy | - | - | MVP live |

**Total Week 2: ~1,200 lines + integration**

**Grand Total: ~3,200 lines** (vs Onyx's 100,000+)

---

<a name="component-1-connector-framework"></a>
# 🔌 COMPONENT 1: CONNECTOR FRAMEWORK

## What It Does
Universal interface for connecting to any data source (Google Drive, Ads, CRM, etc.)

## Onyx's Implementation

### Files (Exact Paths):

```python
backend/onyx/connectors/
├── interfaces.py                    # ⭐ BASE INTERFACES (EXTRACT THIS)
│   ├── BaseConnector               # Abstract base (validate, load creds)
│   ├── LoadConnector               # Full data load
│   ├── PollConnector               # Incremental updates
│   ├── CheckpointedConnector       # Stateful sync
│   ├── OAuthConnector              # OAuth flow
│   └── SlimConnector               # Pruning (IDs only)
│
├── models.py                        # ⭐ DOCUMENT MODEL (EXTRACT THIS)
│   ├── Document                    # Universal doc format
│   ├── Section                     # Text/link sections
│   ├── DocumentSource              # Source enum
│   └── ConnectorCheckpoint         # State management
│
├── connector_runner.py              # ❌ TOO COMPLEX (Don't extract)
├── factory.py                       # ⚠️ PARTIAL (Extract registry pattern)
└── registry.py                      # ⚠️ PARTIAL (Extract mapping concept)
```

### Extraction Strategy:

#### Step 1: Extract Base Interface (100 lines)

```python
# knowsee/backend/connectors/base.py

from abc import ABC, abstractmethod
from typing import Any, Iterator

class BaseConnector(ABC):
    """Base interface for all connectors"""

    @abstractmethod
    def load_credentials(self, credentials: dict[str, Any]) -> None:
        """Load and validate credentials"""
        raise NotImplementedError

    def validate(self) -> bool:
        """Validate connector settings (optional override)"""
        return True


class LoadConnector(BaseConnector):
    """Connector that loads full dataset"""

    @abstractmethod
    def load_from_state(self) -> Iterator[list['Document']]:
        """Yield batches of documents"""
        raise NotImplementedError


class PollConnector(BaseConnector):
    """Connector that supports incremental updates"""

    @abstractmethod
    def poll_source(self, start: float, end: float) -> Iterator[list['Document']]:
        """Yield documents modified between start and end"""
        raise NotImplementedError
```

**Onyx Complexity:** 350 lines across multiple inheritance hierarchies
**Your Simplified Version:** 100 lines, 3 simple classes

#### Step 2: Extract Document Model (150 lines)

```python
# knowsee/backend/models/document.py

from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel


class DocumentSource(str, Enum):
    """Data source types"""
    GOOGLE_DRIVE = "google_drive"
    GOOGLE_ADS = "google_ads"
    FACEBOOK_ADS = "facebook_ads"
    HUBSPOT = "hubspot"
    # Add as needed


class Section(BaseModel):
    """A section of a document"""
    text: str
    link: Optional[str] = None


class Document(BaseModel):
    """Universal document format"""
    id: str                                 # Unique ID
    source: DocumentSource                  # Where it came from
    title: str                              # Display title
    sections: list[Section]                 # Content sections
    metadata: dict[str, Any] = {}          # Extra data
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def get_text(self) -> str:
        """Get all text content"""
        return "\n\n".join(s.text for s in self.sections)
```

**Onyx Complexity:** 500 lines with tons of optional fields
**Your Version:** 150 lines, essential fields only

#### Step 3: Connector Registry (50 lines)

```python
# knowsee/backend/connectors/registry.py

from typing import Type, Dict
from .base import BaseConnector

# Simple dict mapping source -> connector class
CONNECTOR_MAP: Dict[str, Type[BaseConnector]] = {}

def register_connector(source: str):
    """Decorator to register a connector"""
    def decorator(cls: Type[BaseConnector]):
        CONNECTOR_MAP[source] = cls
        return cls
    return decorator

def get_connector(source: str, **config) -> BaseConnector:
    """Get connector instance"""
    connector_class = CONNECTOR_MAP.get(source)
    if not connector_class:
        raise ValueError(f"Unknown connector: {source}")
    return connector_class(**config)
```

**Onyx Complexity:** 200 lines with lazy loading, module imports, etc.
**Your Version:** 50 lines, simple dict

---

## Example Usage (Your Simplified Version)

```python
# Define a connector
from knowsee.backend.connectors.base import LoadConnector
from knowsee.backend.connectors.registry import register_connector
from knowsee.backend.models.document import Document, DocumentSource

@register_connector("google_ads")
class GoogleAdsConnector(LoadConnector):
    def __init__(self, customer_id: str):
        self.customer_id = customer_id
        self.credentials = None

    def load_credentials(self, credentials: dict):
        self.credentials = credentials

    def load_from_state(self):
        # Fetch campaigns, ad groups, ads
        campaigns = self._fetch_campaigns()
        docs = [
            Document(
                id=c["id"],
                source=DocumentSource.GOOGLE_ADS,
                title=c["name"],
                sections=[Section(text=c["description"])],
                metadata={"status": c["status"]}
            )
            for c in campaigns
        ]
        yield docs

# Use it
connector = get_connector("google_ads", customer_id="123")
connector.load_credentials({"access_token": "..."})
for batch in connector.load_from_state():
    print(f"Fetched {len(batch)} documents")
```

---

## Onyx vs Knowsee Comparison

| Feature | Onyx | Knowsee (Your Version) |
|---------|------|------------------------|
| **Files** | 10 files, 2000+ LOC | 3 files, 300 LOC |
| **Connector Types** | 7 base classes | 2 base classes |
| **Document Fields** | 30+ fields | 10 essential fields |
| **Registry** | Lazy-loading with imports | Simple dict |
| **Validation** | Complex multi-step | Optional override |
| **Checkpointing** | Built-in state management | Add if needed |
| **Permission Sync** | Enterprise feature | Skip (not needed) |

---

<a name="component-2-document-processing"></a>
# 🧠 COMPONENT 2: DOCUMENT PROCESSING

## What It Does
Chunks long documents, extracts metadata, prepares for embedding.

## Onyx's Implementation

### Files:

```python
backend/onyx/indexing/
├── chunker.py                      # ⭐ EXTRACT (Chunking logic)
│   ├── chunk_document()           # Main chunking function
│   ├── _split_by_sep()            # Recursive splitting
│   └── _chunk_large_section()    # Handle oversized sections
│
├── embedder.py                     # ⚠️ PARTIAL (API call logic only)
│   └── DefaultIndexingEmbedder    # Send to embedding API
│
└── preprocessor.py                 # ❌ TOO COMPLEX (Skip)
```

### Extraction Strategy:

#### Onyx's Chunking Algorithm (300 lines)

**Key Insight:** Onyx uses **recursive splitting with overlap**

```python
# Onyx's approach (simplified):
1. Split by paragraph ("\n\n")
2. If chunk > max_size:
   - Split by sentence
3. If still > max_size:
   - Split by character
4. Add overlap between chunks
```

#### Your Simplified Version (100 lines):

```python
# knowsee/backend/processing/chunker.py

from typing import List
from ..models.document import Document, Section


class DocumentChunker:
    """Simple chunking with overlap"""

    def __init__(
        self,
        max_chunk_size: int = 512,      # tokens
        overlap: int = 50,               # tokens overlap
    ):
        self.max_chunk_size = max_chunk_size
        self.overlap = overlap

    def chunk_document(self, doc: Document) -> List[Section]:
        """Split document into chunks"""
        # Get all text
        full_text = doc.get_text()

        # Simple word-based chunking (or use tiktoken for tokens)
        words = full_text.split()
        chunks = []

        i = 0
        while i < len(words):
            # Take chunk
            chunk_words = words[i:i + self.max_chunk_size]
            chunk_text = " ".join(chunk_words)

            chunks.append(Section(
                text=chunk_text,
                link=doc.sections[0].link if doc.sections else None
            ))

            # Move forward with overlap
            i += (self.max_chunk_size - self.overlap)

        return chunks


# Or use LangChain (even simpler):
from langchain.text_splitter import RecursiveCharacterTextSplitter

def chunk_with_langchain(text: str, chunk_size: int = 1000):
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=200,
    )
    return splitter.split_text(text)
```

**Onyx Complexity:** 300 lines, custom recursive algorithm
**Your Version (DIY):** 100 lines, simple overlap
**Your Version (LangChain):** 10 lines, battle-tested

#### Embedding (50 lines)

```python
# knowsee/backend/processing/embedder.py

import openai

class Embedder:
    """Generate embeddings for text"""

    def __init__(self, api_key: str, model: str = "text-embedding-3-small"):
        self.client = openai.OpenAI(api_key=api_key)
        self.model = model

    def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Embed multiple texts at once"""
        response = self.client.embeddings.create(
            model=self.model,
            input=texts
        )
        return [e.embedding for e in response.data]
```

**Onyx Complexity:** 400 lines (self-hosted model server support, batching, retries)
**Your Version:** 50 lines (just use OpenAI API)

---

<a name="component-3-oauth-credentials"></a>
# 🔐 COMPONENT 3: OAUTH & CREDENTIALS

## What It Does
Handles OAuth flows, stores credentials securely.

## Onyx's Implementation

### Files:

```python
backend/onyx/server/documents/
├── standard_oauth.py                # ⭐ EXTRACT (OAuth endpoints)
│   ├── /connector/oauth/authorize  # Start OAuth flow
│   ├── /connector/oauth/callback   # Handle callback
│   └── State management (Redis)    # Temporary state storage
│
backend/onyx/db/
├── credentials.py                   # ⭐ EXTRACT (CRUD operations)
│   ├── create_credential()
│   ├── fetch_credentials()
│   └── update_credential()
│
└── models.py                        # ⭐ EXTRACT (Credential model)
    └── Credential                   # DB model with encryption
```

### Extraction Strategy:

#### OAuth Flow (150 lines)

**Onyx's Approach:**
1. User clicks "Connect"
2. Backend generates `state` UUID, stores in Redis (10 min TTL)
3. Redirect to provider (Google, LinkedIn, etc.)
4. Provider redirects back with `code` + `state`
5. Backend validates `state`, exchanges `code` for tokens
6. Store encrypted credentials in Postgres

**Your Simplified Version:**

```python
# knowsee/backend/api/oauth.py

from fastapi import APIRouter, HTTPException, Depends
from uuid import uuid4
import httpx
from ..database import get_db
from ..models import Credential
from ..auth import get_current_user

router = APIRouter(prefix="/oauth")

# Simple in-memory state storage (or use Redis)
_oauth_states = {}

@router.get("/authorize/{source}")
async def start_oauth(source: str, user=Depends(get_current_user)):
    """Start OAuth flow"""
    # Generate state
    state = str(uuid4())
    _oauth_states[state] = {
        "user_id": user.id,
        "source": source,
    }

    # Get OAuth config for source
    config = get_oauth_config(source)  # Your config dict

    # Build authorization URL
    auth_url = (
        f"{config['auth_url']}"
        f"?client_id={config['client_id']}"
        f"&redirect_uri={config['redirect_uri']}"
        f"&response_type=code"
        f"&state={state}"
        f"&scope={config['scope']}"
    )

    return {"authorization_url": auth_url}


@router.get("/callback/{source}")
async def oauth_callback(
    source: str,
    code: str,
    state: str,
    db=Depends(get_db)
):
    """Handle OAuth callback"""
    # Validate state
    if state not in _oauth_states:
        raise HTTPException(400, "Invalid state")

    state_data = _oauth_states.pop(state)
    user_id = state_data["user_id"]

    # Exchange code for token
    config = get_oauth_config(source)
    async with httpx.AsyncClient() as client:
        response = await client.post(
            config["token_url"],
            data={
                "code": code,
                "client_id": config["client_id"],
                "client_secret": config["client_secret"],
                "redirect_uri": config["redirect_uri"],
                "grant_type": "authorization_code",
            }
        )

    tokens = response.json()

    # Save credential
    credential = Credential(
        user_id=user_id,
        source=source,
        access_token=encrypt(tokens["access_token"]),  # Your encryption
        refresh_token=encrypt(tokens.get("refresh_token")),
    )
    db.add(credential)
    db.commit()

    return {"success": True, "credential_id": credential.id}


def get_oauth_config(source: str) -> dict:
    """OAuth configs per source"""
    configs = {
        "google_drive": {
            "auth_url": "https://accounts.google.com/o/oauth2/v2/auth",
            "token_url": "https://oauth2.googleapis.com/token",
            "client_id": os.getenv("GOOGLE_CLIENT_ID"),
            "client_secret": os.getenv("GOOGLE_CLIENT_SECRET"),
            "redirect_uri": "http://localhost:3000/oauth/callback/google_drive",
            "scope": "https://www.googleapis.com/auth/drive.readonly",
        },
        # Add more sources
    }
    return configs[source]
```

**Onyx Complexity:** 230 lines + Redis dependency
**Your Version:** 150 lines, in-memory state (or Redis if needed)

#### Credential Storage (100 lines)

```python
# knowsee/backend/models/credential.py

from sqlalchemy import Column, String, Integer, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from cryptography.fernet import Fernet
from datetime import datetime
import os

# Encryption key (store in env)
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY").encode()
cipher = Fernet(ENCRYPTION_KEY)


class Credential(Base):
    __tablename__ = "credentials"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    source = Column(String, nullable=False)          # "google_drive", etc.

    # Encrypted fields
    _access_token = Column("access_token", String)
    _refresh_token = Column("refresh_token", String)

    metadata_json = Column(JSON, default={})         # Extra data
    created_at = Column(DateTime, default=datetime.utcnow)

    # Encryption properties
    @property
    def access_token(self):
        return cipher.decrypt(self._access_token.encode()).decode()

    @access_token.setter
    def access_token(self, value):
        self._access_token = cipher.encrypt(value.encode()).decode()

    # Same for refresh_token
```

**Onyx Complexity:** 200 lines with SQLAlchemy custom types
**Your Version:** 100 lines with properties

---

<a name="component-4-vector-search"></a>
# 🔍 COMPONENT 4: VECTOR SEARCH

## Decision Point: Extract Vespa or Use Hosted Alternative?

### Option A: Extract Onyx's Vespa Integration

**Pros:**
- Self-hosted (no API costs)
- Production-ready
- Onyx's integration is solid

**Cons:**
- Vespa is COMPLEX (8GB RAM, complex config)
- 2000+ lines of integration code
- Requires deep understanding

**Extraction Difficulty:** ⚠️ VERY HIGH (3-5 days)

### Option B: Use Pinecone/Qdrant/Weaviate

**Pros:**
- Simple API (100 lines vs 2000)
- Managed service (Pinecone) or simple Docker (Qdrant)
- Well-documented

**Cons:**
- API costs (Pinecone: ~$70/month for 1M vectors)
- Dependency on external service

**Implementation Time:** ✅ LOW (1 day)

### Recommended: Option B (Pinecone)

```python
# knowsee/backend/search/vector_store.py

import pinecone
from typing import List, Dict, Any

class VectorStore:
    """Simple vector search with Pinecone"""

    def __init__(self, api_key: str, index_name: str = "knowsee"):
        self.pc = pinecone.Pinecone(api_key=api_key)
        self.index = self.pc.Index(index_name)

    def upsert(self, doc_id: str, embedding: List[float], metadata: Dict):
        """Add/update a document"""
        self.index.upsert(vectors=[{
            "id": doc_id,
            "values": embedding,
            "metadata": metadata
        }])

    def search(self, query_embedding: List[float], top_k: int = 10):
        """Search for similar documents"""
        results = self.index.query(
            vector=query_embedding,
            top_k=top_k,
            include_metadata=True
        )
        return results.matches


# Usage
store = VectorStore(api_key="...")
store.upsert("doc123", embedding=[0.1, 0.2, ...], metadata={"title": "..."})
results = store.search(query_embedding=[0.1, 0.2, ...])
```

**Pinecone Complexity:** 100 lines
**Vespa Complexity:** 2000+ lines

**Recommendation:** Start with Pinecone. If costs become issue later, can always switch to self-hosted Qdrant (also simple).

---

<a name="component-5-llm-chat"></a>
# 💬 COMPONENT 5: LLM/CHAT INTERFACE

## What It Does
Streaming chat with LLM, context from documents, citation handling.

## Onyx's Implementation

### Files:

```python
backend/onyx/chat/
├── chat_utils.py                    # ⚠️ PARTIAL (Context assembly)
├── stream_processing/              # ⭐ EXTRACT (Streaming logic)
│   └── citation_processing.py      # Citation extraction
│
backend/onyx/llm/
├── interfaces.py                    # ⭐ EXTRACT (LLM interface)
└── answering/                       # ❌ TOO COMPLEX (Skip)
```

### Extraction Strategy:

#### Streaming Chat (200 lines)

**Onyx's Complexity:** 800 lines handling citations, quotes, tool calls, etc.

**Your Simplified Version:**

```python
# knowsee/backend/chat/stream.py

from openai import OpenAI
from typing import Iterator

class ChatService:
    """Streaming chat with context"""

    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)

    def chat_stream(
        self,
        message: str,
        context_docs: List[Dict],  # Retrieved from vector search
        history: List[Dict] = None
    ) -> Iterator[str]:
        """Stream chat response with context"""

        # Build context from retrieved docs
        context = "\n\n".join([
            f"Document {i+1}:\n{doc['text']}"
            for i, doc in enumerate(context_docs)
        ])

        # Build messages
        messages = [
            {
                "role": "system",
                "content": f"""You are a helpful assistant. Answer based on the provided context.

Context:
{context}

If the answer isn't in the context, say so."""
            }
        ]

        # Add history
        if history:
            messages.extend(history)

        # Add current message
        messages.append({"role": "user", "content": message})

        # Stream response
        stream = self.client.chat.completions.create(
            model="gpt-4",
            messages=messages,
            stream=True
        )

        for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content


# Usage
chat = ChatService(api_key="...")
for text_chunk in chat.chat_stream(
    message="What are our Google Ads campaigns?",
    context_docs=[{"text": "Campaign 1: ..."}],
):
    print(text_chunk, end="", flush=True)
```

**Onyx Complexity:** 800 lines
**Your Version:** 200 lines
**LangChain Version:** 50 lines (use ConversationalRetrievalChain)

---

<a name="component-6-background-jobs"></a>
# ⚙️ COMPONENT 6: BACKGROUND JOBS

## What It Does
Index documents in background, poll connectors, etc.

## Onyx's Approach: Celery (9 workers, 3000+ lines)

### Your Simplified Approach: ONE worker or Bull (Node.js)

#### Option A: Python with Celery (Minimal)

```python
# knowsee/backend/tasks/celery_app.py

from celery import Celery

app = Celery('knowsee', broker='redis://localhost:6379/0')

@app.task
def index_connector(connector_id: int):
    """Index a connector's documents"""
    # 1. Get connector from DB
    # 2. Fetch documents
    # 3. Chunk and embed
    # 4. Store in vector DB
    pass

@app.task
def poll_connector(connector_id: int):
    """Poll connector for updates"""
    # Similar to above but incremental
    pass

# Run worker:
# celery -A tasks.celery_app worker --loglevel=info
```

**Complexity:** 100 lines (vs Onyx's 3000)

#### Option B: Node.js with Bull (Even Simpler)

```typescript
// knowsee/backend/queues/tasks.ts

import Bull from 'bull';

const indexQueue = new Bull('index', 'redis://localhost:6379');

indexQueue.process(async (job) => {
  const { connectorId } = job.data;

  // 1. Fetch documents
  // 2. Chunk and embed
  // 3. Store in vector DB

  return { success: true };
});

// Add job
await indexQueue.add({ connectorId: 123 });
```

**Recommendation:** If your frontend is Next.js, use Bull (Node.js) for consistency.

---

<a name="component-7-database-models"></a>
# 🗄️ COMPONENT 7: DATABASE MODELS

## Onyx's Models (Relevant Ones)

### Files:

```python
backend/onyx/db/models.py (2000+ lines, 30+ models)

Key Models to Extract:
├── User                    # ⭐ EXTRACT (Basic auth)
├── Credential              # ⭐ EXTRACT (OAuth tokens)
├── Connector               # ⭐ EXTRACT (Connector config)
├── ConnectorCredentialPair # ⚠️ SIMPLIFY (Link connector + credential)
└── Document                # ⭐ EXTRACT (Indexed documents)

Skip (Enterprise Bloat):
├── UserGroup               # ❌ SKIP
├── Tenant                  # ❌ SKIP (Multi-tenant)
├── SlackBot                # ❌ SKIP
└── 20+ other models        # ❌ SKIP
```

### Your Simplified Schema (500 lines):

```python
# knowsee/backend/database/models.py

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    credentials = relationship("Credential", back_populates="user")
    connectors = relationship("Connector", back_populates="user")


class Credential(Base):
    __tablename__ = "credentials"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    source = Column(String, nullable=False)

    # Encrypted tokens
    access_token_encrypted = Column(String)
    refresh_token_encrypted = Column(String)

    metadata = Column(JSON, default={})
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)

    user = relationship("User", back_populates="credentials")


class Connector(Base):
    __tablename__ = "connectors"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    credential_id = Column(Integer, ForeignKey("credentials.id"))

    source = Column(String, nullable=False)
    name = Column(String)
    config = Column(JSON, default={})  # Source-specific config

    status = Column(String, default="active")  # active, paused, error
    last_indexed = Column(DateTime)
    next_index = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="connectors")


class IndexedDocument(Base):
    __tablename__ = "indexed_documents"

    id = Column(Integer, primary_key=True)
    external_id = Column(String, nullable=False)  # ID from source
    connector_id = Column(Integer, ForeignKey("connectors.id"))

    title = Column(String)
    source = Column(String)
    url = Column(String)

    # Stored in vector DB, this is just metadata
    vector_id = Column(String)  # Pinecone/Qdrant ID

    metadata = Column(JSON, default={})
    indexed_at = Column(DateTime, default=datetime.utcnow)
```

**Onyx Complexity:** 2000 lines, 30+ models
**Your Version:** 500 lines, 4 models

---

<a name="component-8-api-structure"></a>
# 🌐 COMPONENT 8: API STRUCTURE

## Onyx's API Organization

```python
backend/onyx/server/
├── documents/
│   ├── connector.py        # ⭐ EXTRACT (Connector CRUD)
│   ├── credential.py       # ⭐ EXTRACT (Credential CRUD)
│   └── standard_oauth.py   # ⭐ EXTRACT (OAuth endpoints)
│
├── query_and_chat/
│   ├── chat_backend.py     # ⚠️ PARTIAL (Chat endpoint)
│   └── search_backend.py   # ⚠️ PARTIAL (Search endpoint)
│
└── manage/                 # ❌ SKIP (Admin CRUD for enterprise features)
```

### Your Simplified API (400 lines):

```python
# knowsee/backend/api/

├── auth.py                 # Login, register, get user
├── oauth.py                # OAuth flow (/authorize, /callback)
├── connectors.py           # CRUD connectors
├── credentials.py          # CRUD credentials
├── chat.py                 # Chat endpoint (streaming)
├── search.py               # Search endpoint
└── index.py                # Trigger indexing jobs
```

#### Example: Connector API (100 lines)

```python
# knowsee/backend/api/connectors.py

from fastapi import APIRouter, Depends, HTTPException
from ..database import get_db
from ..models import Connector, User
from ..auth import get_current_user
from ..tasks import index_connector  # Background task

router = APIRouter(prefix="/connectors")


@router.post("/")
async def create_connector(
    source: str,
    credential_id: int,
    config: dict,
    user: User = Depends(get_current_user),
    db = Depends(get_db)
):
    """Create a new connector"""
    # Validate credential belongs to user
    credential = db.query(Credential).filter(
        Credential.id == credential_id,
        Credential.user_id == user.id
    ).first()

    if not credential:
        raise HTTPException(404, "Credential not found")

    # Create connector
    connector = Connector(
        user_id=user.id,
        credential_id=credential_id,
        source=source,
        config=config,
        status="indexing"
    )
    db.add(connector)
    db.commit()

    # Trigger background indexing
    index_connector.delay(connector.id)

    return {"id": connector.id, "status": "indexing"}


@router.get("/")
async def list_connectors(
    user: User = Depends(get_current_user),
    db = Depends(get_db)
):
    """List user's connectors"""
    connectors = db.query(Connector).filter(
        Connector.user_id == user.id
    ).all()

    return {"connectors": connectors}


@router.delete("/{connector_id}")
async def delete_connector(
    connector_id: int,
    user: User = Depends(get_current_user),
    db = Depends(get_db)
):
    """Delete a connector"""
    connector = db.query(Connector).filter(
        Connector.id == connector_id,
        Connector.user_id == user.id
    ).first()

    if not connector:
        raise HTTPException(404, "Connector not found")

    # Delete from DB and vector store
    db.delete(connector)
    db.commit()

    return {"success": True}
```

---

<a name="what-to-ignore"></a>
# ❌ WHAT TO IGNORE (ENTERPRISE BLOAT)

## Complete List of Files/Features to SKIP

### 1. Multi-Tenancy (10,000+ lines)

```python
backend/onyx/configs/multi_tenant.py
backend/shared_configs/contextvars.py
backend/alembic/versions/schema_private/*
backend/ee/onyx/db/tenant.py

# All schema_private migrations
# All tenant-aware middleware
# All per-tenant Redis namespacing
```

**Why Skip:** You're building single-org. Multi-tenancy adds massive complexity.

### 2. Enterprise SSO (3,000+ lines)

```python
backend/ee/onyx/server/saml.py
backend/ee/onyx/server/oidc.py
backend/ee/onyx/auth/oauth_ext.py

# All SAML integration
# All advanced OIDC features
```

**Why Skip:** Use simple NextAuth.js for auth. SSO is enterprise-only feature.

### 3. User Groups & Advanced Permissions (5,000+ lines)

```python
backend/onyx/db/models.py:
  - UserGroup
  - UserGroup__ConnectorCredentialPair
  - User__UserGroup

backend/ee/onyx/db/user_group.py
backend/ee/onyx/server/user_group/
```

**Why Skip:** Your use case is per-user connectors. No shared groups needed.

### 4. Permission Sync (AccessType.SYNC) (4,000+ lines)

```python
backend/ee/onyx/background/celery/tasks/perm_sync/
backend/ee/onyx/external_permissions/
backend/ee/onyx/db/external_perm.py
```

**Why Skip:** Requires Google Workspace admin. You can't set up for clients. Per-user OAuth is simpler.

### 5. Federated Search (2,000+ lines)

```python
backend/onyx/federated_connectors/
  - Bing connector
  - AWS Kendra connector
  - Glean connector
```

**Why Skip:** You're building internal search, not external API aggregation.

### 6. SlackBot Integration (3,000+ lines)

```python
backend/onyx/bots/slack/
backend/onyx/db/slack_bot.py
```

**Why Skip:** Not needed for your MVP.

### 7. Admin Analytics & Monitoring (2,000+ lines)

```python
backend/onyx/background/celery/tasks/monitoring/
backend/ee/onyx/server/analytics/
```

**Why Skip:** Use external monitoring (Sentry, Datadog) if needed.

### 8. Document Set Management (1,500+ lines)

```python
backend/onyx/db/document_set.py
backend/onyx/server/documents/document_set.py
```

**Why Skip:** Over-engineered feature for organizing docs. Not needed initially.

### 9. Custom LLM Providers (2,000+ lines)

```python
backend/onyx/llm/answering/
backend/onyx/llm/custom_llm.py
```

**Why Skip:** Just use OpenAI API. Don't need 10 LLM providers.

### 10. Advanced Vespa Features (3,000+ lines)

```python
backend/onyx/document_index/vespa/
  - Schemas
  - Deployment configs
  - Advanced querying
```

**Why Skip:** If using Pinecone, all this is irrelevant.

---

**Total Lines SKIPPED: ~35,000 lines of enterprise bloat**

---

<a name="7-day-extraction-plan"></a>
# 📅 THE 7-DAY EXTRACTION PLAN

## Day 1: Foundation

### Morning (3 hours)
- [ ] Set up new repo: `knowsee-platform`
- [ ] Create FastAPI backend structure
- [ ] Set up Postgres + SQLAlchemy
- [ ] Extract base connector interfaces (300 LOC)

### Afternoon (4 hours)
- [ ] Extract Document model (150 LOC)
- [ ] Extract connector registry pattern (50 LOC)
- [ ] Test: Create a dummy connector that works

**End of Day 1:** You have connector framework skeleton

---

## Day 2: Document Processing

### Morning (3 hours)
- [ ] Extract chunking logic OR use LangChain (100 LOC)
- [ ] Set up OpenAI embeddings (50 LOC)
- [ ] Test: Chunk and embed a document

### Afternoon (4 hours)
- [ ] Set up Pinecone account
- [ ] Write vector store wrapper (100 LOC)
- [ ] Test: Index a document, search it

**End of Day 2:** You can index and search documents

---

## Day 3: OAuth & Credentials

### Morning (3 hours)
- [ ] Extract OAuth flow (150 LOC)
- [ ] Extract credential model (100 LOC)
- [ ] Set up encryption

### Afternoon (4 hours)
- [ ] Test OAuth with Google Drive
- [ ] Verify credentials stored securely
- [ ] Test credential refresh

**End of Day 3:** OAuth working end-to-end

---

## Day 4: Real Connector

### Morning (3 hours)
- [ ] Copy Linear connector as template
- [ ] Adapt for Google Drive OR
- [ ] Use dlthub wrapper

### Afternoon (4 hours)
- [ ] Test connector: Auth → Fetch → Index
- [ ] Verify documents searchable
- [ ] Fix bugs

**End of Day 4:** ONE connector fully working

---

## Day 5: Background Jobs

### Morning (3 hours)
- [ ] Set up Celery or Bull
- [ ] Create indexing task (100 LOC)
- [ ] Create polling task (100 LOC)

### Afternoon (4 hours)
- [ ] Test background indexing
- [ ] Set up periodic polling
- [ ] Error handling

**End of Day 5:** Background indexing working

---

## Day 6: Chat Interface

### Morning (3 hours)
- [ ] Extract streaming chat logic (200 LOC)
- [ ] Create API endpoint
- [ ] Test with hardcoded context

### Afternoon (4 hours)
- [ ] Integrate vector search → chat
- [ ] Build simple frontend chat UI
- [ ] Test end-to-end: Search → Context → LLM

**End of Day 6:** Chat working with document context

---

## Day 7: Polish & Deploy

### Morning (3 hours)
- [ ] Add auth (NextAuth.js)
- [ ] Create simple connector setup UI
- [ ] Test full user flow

### Afternoon (4 hours)
- [ ] Deploy to Vercel + Railway/Render
- [ ] Set up environment variables
- [ ] Test in production

**End of Day 7:** MVP LIVE**

---

<a name="architecture-comparison"></a>
# 🏗️ KNOWSEE VS ONYX: ARCHITECTURE COMPARISON

## Component-by-Component

| Component | Onyx | Knowsee | Savings |
|-----------|------|---------|---------|
| **Connector Framework** | 2,000 LOC, 10 files | 500 LOC, 3 files | 75% |
| **Document Processing** | 1,000 LOC | 200 LOC (or 10 with LangChain) | 80-99% |
| **OAuth & Credentials** | 500 LOC | 250 LOC | 50% |
| **Vector Search** | 2,000 LOC (Vespa) | 100 LOC (Pinecone) | 95% |
| **Chat Interface** | 800 LOC | 200 LOC | 75% |
| **Background Jobs** | 3,000 LOC (9 workers) | 200 LOC (1 worker) | 93% |
| **Database Models** | 2,000 LOC (30 models) | 500 LOC (4 models) | 75% |
| **API Endpoints** | 3,000 LOC | 400 LOC | 87% |
| **Multi-Tenancy** | 10,000 LOC | 0 LOC (skipped) | 100% |
| **Enterprise Features** | 20,000 LOC | 0 LOC (skipped) | 100% |

**Total:**
- **Onyx:** ~100,000 lines
- **Knowsee:** ~3,000 lines
- **Reduction:** 97%

---

## Architecture Diagram

### Onyx (Complex):

```
User
  ↓
NextJS (Web)
  ↓
FastAPI (API)
  ↓
┌──────────────┬──────────────┬──────────────┐
│   9 Celery   │  Multi-      │   Federated  │
│   Workers    │  Tenancy     │   Search     │
│              │  Middleware  │              │
└──────────────┴──────────────┴──────────────┘
  ↓              ↓              ↓
Postgres ← Redis ← Vespa (Complex)
  ↓
User Groups, Permissions, Tenants, etc.
```

### Knowsee (Simple):

```
User
  ↓
Next.js (Web + API Routes)
  ↓
┌──────────────┐
│   1 Worker   │
│   (Bull/     │
│   Celery)    │
└──────────────┘
  ↓
Postgres ← Redis ← Pinecone (Hosted)
  ↓
Users, Credentials, Connectors only
```

---

## Tech Stack Comparison

| Layer | Onyx | Knowsee |
|-------|------|---------|
| **Frontend** | Next.js 15 | Next.js 15 (same) |
| **Backend** | FastAPI (Python) | Next.js API Routes (TypeScript) |
| **Database** | Postgres | Postgres (same) |
| **Vector DB** | Vespa (self-hosted) | Pinecone (hosted) |
| **Queue** | Celery (Python) | Bull (Node.js) |
| **Auth** | Custom OAuth | NextAuth.js |
| **LLM** | Custom + LiteLLM | OpenAI API direct |
| **Embeddings** | Self-hosted model server | OpenAI API |

**Key Simplification:** TypeScript fullstack (Next.js) vs Python backend + JS frontend

---

# 🎯 EXTRACTION CHECKLIST

## Week 1: Core Extraction

- [ ] Day 1: Connector framework (interfaces, models, registry)
- [ ] Day 2: Document processing (chunking, embedding, vector store)
- [ ] Day 3: OAuth & credentials (flow, storage, encryption)
- [ ] Day 4: First working connector (Google Drive or dlthub)
- [ ] Day 5: Background jobs (indexing, polling)

## Week 2: Features & Launch

- [ ] Day 6: Chat interface (streaming, context, LLM)
- [ ] Day 7: Polish & deploy

## Post-Launch: Iteration

- [ ] Week 3: Add more connectors (Facebook Ads, Google Ads, HubSpot)
- [ ] Week 4: Marketing-specific features (dashboards, reports)
- [ ] Week 5: Scale & optimize

---

# 💡 KEY INSIGHTS FOR SUCCESSFUL EXTRACTION

## 1. Don't Extract Everything At Once

**Bad:** "I'll extract the entire connector framework, then test"
**Good:** "I'll extract BaseConnector interface, test with dummy connector"

Start small, validate, iterate.

## 2. Use Modern Alternatives When Simpler

- Don't extract Vespa → Use Pinecone
- Don't extract custom auth → Use NextAuth.js
- Don't extract custom chunking → Use LangChain

## 3. Your Advantage: AI-Assisted Development

You have Claude Code and Codex CLI. Use them to:
- Generate boilerplate based on Onyx patterns
- Adapt Onyx code to your simpler architecture
- Debug extraction issues

## 4. MIT License Means You Can Copy Freely

But:
- ✅ DO copy clever algorithms (chunking, OAuth flow)
- ✅ DO copy document models
- ❌ DON'T copy enterprise complexity
- ❌ DON'T copy over-engineered patterns

## 5. Focus on Your Use Case

**Onyx is for:** Enterprise with 1000+ users, shared drives, admin-managed
**Knowsee is for:** Marketing agencies, per-user connectors, self-service

Build for Knowsee, not Onyx v2.

---

# 🚀 START HERE

## Step 1: Clone This Document

Save this locally. Reference it during extraction.

## Step 2: Set Up New Repo

```bash
mkdir knowsee-platform
cd knowsee-platform

# Backend (Python or TypeScript?)
mkdir backend
mkdir frontend

# Or use Next.js fullstack
npx create-next-app@latest knowsee --typescript
```

## Step 3: Start Day 1 Extraction

Focus on connector framework first. Everything else depends on it.

## Step 4: Use This Checklist Daily

Come back here, check off completed items, stay on track.

---

# 📞 WHEN YOU GET STUCK

## Stuck on Extraction:

1. Find the Onyx file in this blueprint
2. Read the "Extraction Strategy" section
3. Copy the simplified version
4. Test before moving on

## Stuck on Integration:

1. Draw the data flow on paper
2. Test each step independently
3. Use AI to generate glue code

## Stuck on Complexity:

1. Remember: If Onyx does it in 1000 lines, you can do it in 100
2. Check if a library exists (LangChain, NextAuth, Pinecone)
3. Ask: "Do I really need this feature?"

---

# ✅ SUCCESS METRICS

## Week 1:
- [ ] ONE connector working (auth → fetch → index)
- [ ] Documents searchable via API
- [ ] Background indexing running

## Week 2:
- [ ] Chat interface with context
- [ ] Simple UI for connector setup
- [ ] Deployed and accessible

## Week 3:
- [ ] 3+ connectors working
- [ ] Marketing-specific features starting
- [ ] Users testing

---

**You've got this. The blueprint is complete. Now go cherry-pick brilliance and discard bloat.**

**Your lean, mean Knowsee platform awaits.**

🚀
