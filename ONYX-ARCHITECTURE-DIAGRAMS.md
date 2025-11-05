# ONYX ARCHITECTURE DIAGRAMS - Cloud Architecture Style

Complete system architecture diagrams showing component interactions, data flows, and security boundaries.

---

## 1. OVERALL SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PUBLIC INTERNET                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTPS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          LOAD BALANCER / NGINX                               │
│                          (SSL Termination)                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
        ┌─────────────────────┐           ┌─────────────────────┐
        │   WEB SERVER         │           │   API SERVER        │
        │   Next.js 15         │           │   FastAPI           │
        │   Port: 3000         │           │   Port: 8080        │
        │                      │           │                     │
        │   • SSR/ISR          │◄─────────►│   • REST APIs       │
        │   • React 18         │  Proxied  │   • WebSocket       │
        │   • Auth UI          │  via      │   • Auth/JWT        │
        │   • Chat UI          │  /api/*   │   • Middleware      │
        └──────────┬───────────┘           └──────────┬──────────┘
                   │                                  │
                   │                                  │
                   └──────────────┬───────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌────────────────┐    ┌────────────────────┐    ┌──────────────────┐
│  REDIS         │    │  POSTGRESQL 15     │    │  VESPA 8.5       │
│  Port: 6379    │    │  Port: 5432        │    │  Port: 8081      │
│                │    │                    │    │                  │
│  • Celery      │    │  • User data       │    │  • Vector DB     │
│    broker      │    │  • Connectors      │    │  • Document      │
│  • OAuth state │    │  • Documents       │    │    chunks        │
│  • Cache       │    │  • Chat history    │    │  • Embeddings    │
│  • Sessions    │    │  • Credentials     │    │  • BM25 index    │
└────────┬───────┘    └──────────┬─────────┘    └────────┬─────────┘
         │                       │                       │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │  CELERY WORKERS         │
                    │  (Background Jobs)      │
                    │                         │
                    │  • Docfetching          │
                    │  • Docprocessing        │
                    │  • Indexing             │
                    │  • Permission sync      │
                    │  • Pruning              │
                    └────────┬────────────────┘
                             │
                             │ Fetch data from
                             ▼
                ┌────────────────────────────┐
                │  EXTERNAL DATA SOURCES     │
                │                            │
                │  • Google Drive API        │
                │  • Confluence API          │
                │  • Slack API               │
                │  • GitHub API              │
                │  • 50+ other connectors    │
                └────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│  SUPPORTING SERVICES                                                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│  │  MinIO/S3        │  │  Model Server    │  │  LLM Providers   │   │
│  │  (File Storage)  │  │  (Embeddings)    │  │                  │   │
│  │                  │  │                  │  │  • OpenAI API    │   │
│  │  • User uploads  │  │  • text-embed-3  │  │  • Anthropic     │   │
│  │  • Document PDFs │  │  • voyage-2      │  │  • Google        │   │
│  │  • Attachments   │  │  • Custom models │  │  • Azure         │   │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Key Components:**

| Component | Technology | Purpose | Scalability |
|-----------|-----------|---------|-------------|
| Web Server | Next.js 15 | UI rendering, SSR, client routing | Horizontal (stateless) |
| API Server | FastAPI | Business logic, API endpoints | Horizontal (stateless) |
| PostgreSQL | Postgres 15 | Relational data, metadata | Vertical + read replicas |
| Vespa | Vespa 8.5 | Vector search, document retrieval | Horizontal (content nodes) |
| Redis | Redis 7 | Queue, cache, sessions | Vertical + sentinel |
| Celery Workers | Python/Celery | Async background tasks | Horizontal (worker pools) |

---

## 2. LOGIN FLOW - Step by Step

```
┌──────────────┐
│   Browser    │
└──────┬───────┘
       │
       │ 1. GET /login
       ▼
┌────────────────────────────────────┐
│  Next.js Web Server                │
│  web/src/app/login/page.tsx        │
│                                    │
│  • Renders login form              │
│  • Email + password fields         │
│  • "Sign in" button                │
│  • OAuth buttons (Google, etc)     │
└────────┬───────────────────────────┘
         │
         │ 2. POST /api/auth/login
         │    { email, password }
         ▼
┌────────────────────────────────────────┐
│  API Server - Auth Endpoint            │
│  backend/onyx/server/auth.py           │
│  @router.post("/login")                │
│                                        │
│  Step 1: Validate request              │
│  • Pydantic model validation           │
│  • Check required fields               │
└────────┬───────────────────────────────┘
         │
         │ 3. Query user by email
         ▼
┌────────────────────────────────────────┐
│  Database Layer                        │
│  backend/onyx/db/user.py               │
│  get_user_by_email(email)              │
│                                        │
│  SELECT * FROM "user"                  │
│  WHERE email = ?                       │
└────────┬───────────────────────────────┘
         │
         │ 4. Return User object
         ▼
┌────────────────────────────────────────┐
│  Auth Service                          │
│  backend/onyx/auth/users.py            │
│  UserManager.authenticate()            │
│                                        │
│  Step 2: Verify password               │
│  • bcrypt.checkpw(password, hashed)    │
│  • Return None if invalid              │
│                                        │
│  Step 3: Check user is_active          │
│  • Return 401 if inactive              │
└────────┬───────────────────────────────┘
         │
         │ 5. Password valid
         ▼
┌────────────────────────────────────────┐
│  JWT Token Generation                  │
│  backend/onyx/auth/jwt.py              │
│  generate_jwt_token(user)              │
│                                        │
│  jwt.encode({                          │
│    "sub": user.id,                     │
│    "email": user.email,                │
│    "role": user.role,                  │
│    "exp": now + 7 days                 │
│  }, secret_key, algorithm="HS256")     │
└────────┬───────────────────────────────┘
         │
         │ 6. Return JWT
         │    { "access_token": "eyJ..." }
         ▼
┌────────────────────────────────────────┐
│  Web Server Response Handler          │
│  web/src/lib/auth.ts                   │
│                                        │
│  • Store JWT in httpOnly cookie       │
│  • Set-Cookie: auth_token=eyJ...      │
│  • Redirect to /chat or /search       │
└────────┬───────────────────────────────┘
         │
         │ 7. Redirect to /chat
         ▼
┌────────────────────────────────────────┐
│  Browser                               │
│  • Cookie stored                       │
│  • Redirected to authenticated page    │
│  • All subsequent requests include JWT │
└────────────────────────────────────────┘
```

**Security Considerations:**

1. **Password Storage**: bcrypt with cost factor 12
2. **JWT Secret**: Strong random key (256-bit), rotated periodically
3. **Cookie Security**: httpOnly, Secure, SameSite=Lax
4. **Token Expiry**: 7 days default, refresh token support
5. **Rate Limiting**: 5 login attempts per 15 minutes per IP
6. **HTTPS Only**: All auth endpoints require HTTPS

**Files Involved:**
- `web/src/app/login/page.tsx` - Login UI
- `web/src/lib/auth.ts` - Client-side auth logic
- `backend/onyx/server/auth.py` - Auth endpoints
- `backend/onyx/auth/users.py` - UserManager class
- `backend/onyx/auth/jwt.py` - JWT generation/validation
- `backend/onyx/db/user.py` - User CRUD operations

---

## 3. OAUTH FLOW (Google Drive Example)

```
┌──────────────┐
│  Admin User  │
└──────┬───────┘
       │
       │ 1. Click "Connect Google Drive"
       │    GET /admin/connectors/google_drive
       ▼
┌────────────────────────────────────────────────┐
│  Next.js - Connector Setup Page                │
│  web/src/app/admin/connectors/                 │
│      [connector]/pages/gdrive/                 │
│      GoogleDrivePage.tsx                       │
│                                                │
│  • Shows "Authorize" button                    │
│  • Admin-only check (line 279)                 │
│  • Non-admins see error message                │
└────────┬───────────────────────────────────────┘
         │
         │ 2. Click "Authorize"
         │    POST /api/connector/oauth/authorize/google_drive
         ▼
┌────────────────────────────────────────────────┐
│  API Server - OAuth Start                      │
│  backend/onyx/server/documents/                │
│      standard_oauth.py                         │
│  @router.get("/authorize/{source}")            │
│                                                │
│  Step 1: Generate state token                  │
│  state = uuid.uuid4()                          │
│                                                │
│  Step 2: Store state in Redis                  │
│  redis.set(f"oauth:state:{state}",             │
│            json.dumps({                        │
│              "user_id": current_user.id,       │
│              "source": "google_drive",         │
│              "timestamp": now                  │
│            }),                                 │
│            ex=600)  # 10 min expiry            │
│                                                │
│  Step 3: Build OAuth URL                       │
│  redirect_url = GoogleDriveConnector           │
│    .oauth_authorization_url(                   │
│      state=state,                              │
│      redirect_uri="http://localhost:3000/      │
│                    api/connector/oauth/        │
│                    callback/google_drive"      │
│    )                                           │
│                                                │
│  Returns: {                                    │
│    "redirect_url": "https://accounts.google    │
│      .com/o/oauth2/v2/auth?                    │
│      client_id=XXX&                            │
│      redirect_uri=http://localhost:3000/...&   │
│      response_type=code&                       │
│      scope=https://www.googleapis.com/auth/    │
│            drive.readonly&                     │
│      state=abc-123-def&                        │
│      access_type=offline&                      │
│      prompt=consent"                           │
│  }                                             │
└────────┬───────────────────────────────────────┘
         │
         │ 3. Redirect to Google
         ▼
┌────────────────────────────────────────────────┐
│  Google OAuth Server                           │
│  accounts.google.com                           │
│                                                │
│  • User sees Google consent screen             │
│  • Lists requested permissions:                │
│    - "View and download all your Google        │
│       Drive files"                             │
│  • User clicks "Allow"                         │
└────────┬───────────────────────────────────────┘
         │
         │ 4. User approves
         │    GET /api/connector/oauth/callback/
         │        google_drive?code=AUTH_CODE&
         │        state=abc-123-def
         ▼
┌────────────────────────────────────────────────┐
│  API Server - OAuth Callback                   │
│  backend/onyx/server/documents/                │
│      standard_oauth.py                         │
│  @router.get("/callback/{source}")             │
│                                                │
│  Step 1: Validate state token                  │
│  state_data = redis.get(f"oauth:state:{state}")│
│  if not state_data:                            │
│    return "Invalid or expired state"           │
│                                                │
│  Step 2: Exchange code for tokens              │
│  token_info = GoogleDriveConnector             │
│    .oauth_code_to_token(                       │
│      code=AUTH_CODE,                           │
│      redirect_uri=callback_url                 │
│    )                                           │
│  # Makes POST to Google token endpoint         │
│  # Returns: {                                  │
│  #   "access_token": "ya29.a0...",             │
│  #   "refresh_token": "1//0g...",              │
│  #   "expires_in": 3600,                       │
│  #   "token_type": "Bearer"                    │
│  # }                                           │
│                                                │
│  Step 3: Encrypt tokens                        │
│  encrypted = encrypt_string(                   │
│    json.dumps(token_info)                      │
│  )                                             │
│                                                │
│  Step 4: Store in database                     │
│  credential = Credential(                      │
│    user_id=state_data["user_id"],              │
│    credential_json=encrypted,                  │
│    source=DocumentSource.GOOGLE_DRIVE,         │
│    created_at=now                              │
│  )                                             │
│  db.add(credential)                            │
│  db.commit()                                   │
│                                                │
│  Step 5: Delete state from Redis               │
│  redis.delete(f"oauth:state:{state}")          │
│                                                │
│  Step 6: Redirect back to connector page       │
│  return RedirectResponse(                      │
│    f"/admin/connectors/google_drive?           │
│      credentialId={credential.id}"             │
│  )                                             │
└────────┬───────────────────────────────────────┘
         │
         │ 5. Success! Credential stored
         ▼
┌────────────────────────────────────────────────┐
│  Connector Setup Page                          │
│  web/src/app/admin/connectors/[connector]/     │
│                                                │
│  • Shows success message                       │
│  • Displays credential ID                      │
│  • Admin can now create connector using        │
│    this credential                             │
│  • Next step: POST /api/manage/admin/          │
│              connector with credential_id      │
└────────────────────────────────────────────────┘
```

**Security Considerations:**

1. **State Token**: Prevents CSRF attacks, stored in Redis with 10-min TTL
2. **Redirect URI**: Must match exactly what's registered with Google
3. **Token Encryption**: Access/refresh tokens encrypted at rest (AES-256)
4. **Admin-Only**: Only admin users can set up OAuth (frontend + backend checks)
5. **Token Refresh**: Refresh tokens used to get new access tokens automatically
6. **Scope Minimization**: Only request necessary scopes (drive.readonly)

**Why Test App Publishing Confusion?**

- **Test App** (unverified): Limited to 100 users you manually add as "test users"
- **Published App** (verified): Requires Google verification process, available to anyone
- **For Knowsee**: You need published app OR add each customer as test user
- **Alternative**: Each customer sets up their own OAuth app (not scalable)

---

## 4. DOCUMENT INDEXING FLOW

```
┌──────────────┐
│  Admin User  │
└──────┬───────┘
       │
       │ 1. Create connector with credential
       │    POST /api/manage/admin/connector
       │    {
       │      "name": "Engineering Team Drive",
       │      "source": "google_drive",
       │      "credential_id": 123,
       │      "connector_specific_config": {
       │        "folder_paths": ["/Engineering"],
       │        "include_shared_drives": true
       │      },
       │      "access_type": "PRIVATE",  // Only specific groups
       │      "groups": [5]  // Engineering group
       │    }
       ▼
┌─────────────────────────────────────────────────┐
│  API Server - Connector Creation               │
│  backend/onyx/server/manage/connector.py        │
│                                                 │
│  • Validates connector config                   │
│  • Creates Connector DB record                  │
│  • Creates ConnectorCredentialPair              │
│  • Triggers initial indexing                    │
└────────┬────────────────────────────────────────┘
         │
         │ 2. Trigger indexing job
         │    (Creates Celery task)
         ▼
┌─────────────────────────────────────────────────┐
│  Celery Beat Scheduler                          │
│  backend/background/celery/beat.py              │
│                                                 │
│  • Checks for connectors needing indexing       │
│  • Runs every 15 seconds                        │
│  • Creates indexing task                        │
│  • Sends to docfetching queue                   │
└────────┬────────────────────────────────────────┘
         │
         │ 3. docfetching task
         ▼
┌─────────────────────────────────────────────────────────┐
│  Docfetching Worker                                     │
│  backend/background/celery/tasks/docfetching.py         │
│                                                         │
│  Step 1: Load connector config                          │
│  connector = db.query(Connector).get(connector_id)      │
│  credential = connector.credential                      │
│                                                         │
│  Step 2: Decrypt OAuth tokens                           │
│  tokens = decrypt_string(credential.credential_json)    │
│                                                         │
│  Step 3: Instantiate connector                          │
│  gdrive_connector = GoogleDriveConnector(               │
│    folder_paths=["/Engineering"],                       │
│    include_shared_drives=True                           │
│  )                                                      │
│  gdrive_connector.load_credentials(tokens)              │
│                                                         │
│  Step 4: Fetch documents                                │
│  for doc_batch in gdrive_connector.load_from_state():   │
│    # doc_batch is list of Document objects              │
│    # Each Document has:                                 │
│    #   - id: Google Drive file ID                       │
│    #   - semantic_identifier: file name                 │
│    #   - sections: [Section(text="...", link="...")]    │
│    #   - metadata: {"owner": "...", "modified": "..."}  │
│    #   - source: GOOGLE_DRIVE                           │
│                                                         │
│    Step 5: Spawn docprocessing task for each batch      │
│    docprocessing_task.apply_async(                      │
│      args=[connector_id, doc_batch],                    │
│      queue="docprocessing"                              │
│    )                                                    │
└────────┬────────────────────────────────────────────────┘
         │
         │ 4. Multiple docprocessing tasks in parallel
         │    (One per batch of documents)
         ▼
┌─────────────────────────────────────────────────────────┐
│  Docprocessing Worker                                   │
│  backend/background/celery/tasks/docprocessing.py       │
│                                                         │
│  For each document in batch:                            │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 1: Upsert to PostgreSQL                    │   │
│  │ backend/onyx/db/document.py                     │   │
│  │                                                 │   │
│  │ INSERT INTO document (                          │   │
│  │   id, semantic_identifier, source,              │   │
│  │   metadata, from_ingestion_api                  │   │
│  │ ) VALUES (...)                                  │   │
│  │ ON CONFLICT (id) DO UPDATE ...                  │   │
│  │                                                 │   │
│  │ Result: Document metadata stored in DB          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 2: Chunk document                          │   │
│  │ backend/onyx/chunking/chunk.py                  │   │
│  │                                                 │   │
│  │ chunker = Chunker(                              │   │
│  │   chunk_size=512,  # tokens                     │   │
│  │   overlap=128      # tokens                     │   │
│  │ )                                               │   │
│  │                                                 │   │
│  │ chunks = chunker.chunk_document(doc)            │   │
│  │ # Returns list of DocChunk objects              │   │
│  │ # Each chunk:                                   │   │
│  │ #   - content: "This is a paragraph..."         │   │
│  │ #   - source_links: {"link": "...", "snippet"}  │   │
│  │ #   - chunk_id: 0, 1, 2, ...                    │   │
│  │ #   - metadata: inherited from doc              │   │
│  │                                                 │   │
│  │ Result: Document split into ~500 token chunks   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 3: Add contextual info to chunks          │   │
│  │ backend/onyx/indexing/chunking_utils.py         │   │
│  │                                                 │   │
│  │ for chunk in chunks:                            │   │
│  │   # Add document title                          │   │
│  │   chunk.title_prefix = doc.semantic_identifier  │   │
│  │   # Add metadata as searchable text             │   │
│  │   chunk.metadata_suffix = (                     │   │
│  │     f"Author: {doc.metadata['owner']}"          │   │
│  │     f"Modified: {doc.metadata['modified']}"     │   │
│  │   )                                             │   │
│  │                                                 │   │
│  │ Result: Chunks enriched with context            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 4: Generate embeddings                     │   │
│  │ backend/onyx/indexing/embedder.py               │   │
│  │                                                 │   │
│  │ embedder = DefaultIndexingEmbedder(             │   │
│  │   model_name="text-embedding-3-small"           │   │
│  │ )                                               │   │
│  │                                                 │   │
│  │ # Batch embed chunks (up to 100 at a time)      │   │
│  │ chunk_texts = [                                 │   │
│  │   f"{c.title_prefix} {c.content} {c.meta...}"   │   │
│  │   for c in chunks                               │   │
│  │ ]                                               │   │
│  │                                                 │   │
│  │ embeddings = embedder.embed_batch(chunk_texts)  │   │
│  │ # Calls OpenAI API                              │   │
│  │ # Returns: List of float vectors (1536-dim)     │   │
│  │                                                 │   │
│  │ for chunk, embedding in zip(chunks, embeddings):│   │
│  │   chunk.embedding = embedding                   │   │
│  │                                                 │   │
│  │ Result: Each chunk has embedding vector         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 5: Add ACLs (Access Control Lists)        │   │
│  │ backend/onyx/access/access.py                   │   │
│  │                                                 │   │
│  │ acls = get_access_for_document(                 │   │
│  │   doc_id=doc.id,                                │   │
│  │   connector_id=connector.id,                    │   │
│  │   access_type="PRIVATE"  # From config          │   │
│  │ )                                               │   │
│  │                                                 │   │
│  │ # For PRIVATE access with groups=[5]:           │   │
│  │ acls = [                                        │   │
│  │   "group:engineering_team"  # Group ID 5        │   │
│  │ ]                                               │   │
│  │                                                 │   │
│  │ for chunk in chunks:                            │   │
│  │   chunk.access_control_list = acls              │   │
│  │                                                 │   │
│  │ Result: Chunks tagged with access permissions   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 6: Index to Vespa                          │   │
│  │ backend/onyx/document_index/vespa/index.py      │   │
│  │                                                 │   │
│  │ vespa_index = VespaIndex()                      │   │
│  │                                                 │   │
│  │ for chunk in chunks:                            │   │
│  │   vespa_doc = {                                 │   │
│  │     "id": f"{doc.id}_chunk_{chunk.chunk_id}",   │   │
│  │     "title": doc.semantic_identifier,           │   │
│  │     "content": chunk.content,                   │   │
│  │     "embeddings": chunk.embedding,              │   │
│  │     "source": "google_drive",                   │   │
│  │     "metadata": doc.metadata,                   │   │
│  │     "access": chunk.access_control_list,        │   │
│  │     "created_at": doc.created_at                │   │
│  │   }                                             │   │
│  │                                                 │   │
│  │   # POST to Vespa                               │   │
│  │   response = vespa_client.feed_document(        │   │
│  │     document=vespa_doc                          │   │
│  │   )                                             │   │
│  │                                                 │   │
│  │ Result: Chunks searchable in Vespa              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Step 7: Update indexing status                  │   │
│  │                                                 │   │
│  │ connector.last_successful_index_time = now      │   │
│  │ connector.status = "SUCCESS"                    │   │
│  │ db.commit()                                     │   │
│  │                                                 │   │
│  │ Result: Connector shows as indexed in UI        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**System Considerations:**

1. **Chunking Strategy**:
   - Default: 512 tokens per chunk with 128 token overlap
   - Why overlap? Prevents context loss at chunk boundaries
   - Alternative: Semantic chunking (by paragraph/section)

2. **Embedding Cost**:
   - text-embedding-3-small: $0.02 per 1M tokens
   - For 1000 docs × 10 pages × 500 words = 5M tokens
   - Cost: ~$0.10 for initial indexing
   - Consider: Batch size (100 chunks), retry logic, rate limits

3. **Vespa Indexing**:
   - Batch size: 100 documents at a time
   - Throughput: ~1000 docs/min (single worker)
   - Memory: ~2GB per worker for embeddings
   - Scale: Add more docprocessing workers

4. **Access Control**:
   - ACLs stored with each chunk in Vespa
   - Search queries filtered by user's groups
   - For 10,000 users × 50 groups = efficient with Vespa YQL

5. **Failure Handling**:
   - API failures: Retry 3 times with exponential backoff
   - Celery: Tasks auto-retry on transient failures
   - Monitoring: Check `backend/log/docprocessing_debug.log`

---

## 5. CHAT/SEARCH QUERY FLOW

```
┌──────────────┐
│  User        │
└──────┬───────┘
       │
       │ 1. Type message: "What are our Q4 OKRs?"
       │    Click Send
       │    POST /api/chat/send-message
       │    {
       │      "message": "What are our Q4 OKRs?",
       │      "chat_session_id": 456,
       │      "persona_id": 1,  // "Company Assistant"
       │      "prompt_id": 10    // System prompt
       │    }
       ▼
┌──────────────────────────────────────────────────────────┐
│  API Server - Chat Endpoint                              │
│  backend/onyx/server/query_and_chat/chat_backend.py      │
│  @router.post("/send-message")                           │
│                                                          │
│  Step 1: Authentication check                            │
│  current_user = Depends(current_user)                    │
│  • Validates JWT token                                   │
│  • Gets user ID and role                                 │
│                                                          │
│  Step 2: Rate limiting (EE feature)                      │
│  check_token_rate_limit(user, user.groups)               │
│  • Checks if user/group has exceeded quota               │
│  • Returns 429 if limit exceeded                         │
│                                                          │
│  Step 3: Load chat session                               │
│  chat_session = db.query(ChatSession).get(456)           │
│  • Verify user owns this session                         │
│  • Load previous messages for context                    │
└──────┬───────────────────────────────────────────────────┘
       │
       │ 2. Process query through chat pipeline
       ▼
┌──────────────────────────────────────────────────────────────┐
│  Chat Pipeline - Main Entry                                  │
│  backend/onyx/chat/process_message.py                        │
│  process_message()                                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Phase 1: Document Retrieval                        │     │
│  │ backend/onyx/search/search_runner.py               │     │
│  │                                                    │     │
│  │ Step 1: Build search query                         │     │
│  │ search_query = SearchQuery(                        │     │
│  │   query="What are our Q4 OKRs?",                   │     │
│  │   user_id=current_user.id,                         │     │
│  │   filters=SearchFilters(                           │     │
│  │     access_control_list=get_acls_for_user(user)    │     │
│  │   )                                                │     │
│  │ )                                                  │     │
│  │                                                    │     │
│  │ Step 2: Generate query embedding                   │     │
│  │ query_embedding = embedder.embed(                  │     │
│  │   "What are our Q4 OKRs?"                          │     │
│  │ )                                                  │     │
│  │ # Returns 1536-dim vector                          │     │
│  │                                                    │     │
│  │ Step 3: Build Vespa YQL query                      │     │
│  │ yql = f"""                                         │     │
│  │   SELECT * FROM sources chunk                      │     │
│  │   WHERE (                                          │     │
│  │     ({nearestNeighbor(embeddings, query_embed)}    │     │
│  │      OR userQuery())                               │     │
│  │     AND access CONTAINS "group:engineering_team"   │     │
│  │   )                                                │     │
│  │   ORDER BY bm25(content) + semantic_score          │     │
│  │   LIMIT 50                                         │     │
│  │ """                                                │     │
│  │ # Hybrid search: BM25 (keyword) + vector (semantic)│     │
│  │ # ACL filter: Only docs user has access to         │     │
│  │                                                    │     │
│  │ Step 4: Execute search on Vespa                    │     │
│  │ results = vespa_client.query(yql, query_embedding) │     │
│  │                                                    │     │
│  │ Step 5: Rerank top results                         │     │
│  │ reranked = cross_encoder_rerank(                   │     │
│  │   query="What are our Q4 OKRs?",                   │     │
│  │   chunks=results[:20]  # Top 20                    │     │
│  │ )                                                  │     │
│  │ # Returns chunks sorted by relevance score          │     │
│  │                                                    │     │
│  │ Result: Top 10 most relevant chunks                │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Phase 2: Context Assembly                          │     │
│  │ backend/onyx/chat/context_assembly.py              │     │
│  │                                                    │     │
│  │ Step 1: Extract context from chunks                │     │
│  │ context_docs = []                                  │     │
│  │ for chunk in reranked[:10]:                        │     │
│  │   context_docs.append({                            │     │
│  │     "content": chunk.content,                      │     │
│  │     "source": chunk.semantic_identifier,           │     │
│  │     "link": chunk.source_links[0]["link"],         │     │
│  │     "score": chunk.relevance_score                 │     │
│  │   })                                               │     │
│  │                                                    │     │
│  │ Step 2: Fit to context window                      │     │
│  │ # GPT-4 has 8K context window                      │     │
│  │ # Reserve: 2K for system prompt + chat history     │     │
│  │ #          2K for response                         │     │
│  │ #          4K for retrieved docs                   │     │
│  │ total_tokens = 0                                   │     │
│  │ fitted_docs = []                                   │     │
│  │ for doc in context_docs:                           │     │
│  │   doc_tokens = count_tokens(doc["content"])       │     │
│  │   if total_tokens + doc_tokens > 4000:             │     │
│  │     break                                          │     │
│  │   fitted_docs.append(doc)                          │     │
│  │   total_tokens += doc_tokens                       │     │
│  │                                                    │     │
│  │ Result: 5-10 docs totaling ~4K tokens              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Phase 3: Prompt Building                           │     │
│  │ backend/onyx/chat/prompt_builder.py                │     │
│  │                                                    │     │
│  │ Step 1: Build system prompt                        │     │
│  │ system_prompt = f"""                               │     │
│  │ You are a helpful AI assistant. Answer the user's  │     │
│  │ question using ONLY the provided context documents.│     │
│  │                                                    │     │
│  │ Context Documents:                                 │     │
│  │ {format_context_docs(fitted_docs)}                 │     │
│  │                                                    │     │
│  │ Instructions:                                      │     │
│  │ - Answer based ONLY on the context provided        │     │
│  │ - If the answer isn't in the context, say so       │     │
│  │ - Cite sources using [1], [2], etc.                │     │
│  │ - Be concise and direct                            │     │
│  │ """                                                │     │
│  │                                                    │     │
│  │ Step 2: Build chat history                         │     │
│  │ messages = [                                       │     │
│  │   {"role": "system", "content": system_prompt},    │     │
│  │   {"role": "user", "content": "How do I...?"},     │     │
│  │   {"role": "assistant", "content": "You can..."},  │     │
│  │   {"role": "user", "content": "What are our Q4..."}│     │
│  │ ]                                                  │     │
│  │                                                    │     │
│  │ Result: Full prompt ready for LLM                  │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Phase 4: LLM Streaming                             │     │
│  │ backend/onyx/llm/openai.py                         │     │
│  │                                                    │     │
│  │ Step 1: Call OpenAI streaming API                  │     │
│  │ response = openai.ChatCompletion.create(           │     │
│  │   model="gpt-4",                                   │     │
│  │   messages=messages,                               │     │
│  │   temperature=0.0,  # Deterministic                │     │
│  │   stream=True       # Stream tokens                │     │
│  │ )                                                  │     │
│  │                                                    │     │
│  │ Step 2: Stream tokens back to client               │     │
│  │ for chunk in response:                             │     │
│  │   token = chunk.choices[0].delta.content           │     │
│  │   if token:                                        │     │
│  │     yield f"data: {json.dumps({                    │     │
│  │       'token': token                               │     │
│  │     })}\n\n"                                       │     │
│  │                                                    │     │
│  │ Step 3: Extract citations                          │     │
│  │ # Parse response for [1], [2], etc.                │     │
│  │ citations = extract_citations(                     │     │
│  │   response_text,                                   │     │
│  │   fitted_docs                                      │     │
│  │ )                                                  │     │
│  │                                                    │     │
│  │ Step 4: Send final metadata                        │     │
│  │ yield f"data: {json.dumps({                        │     │
│  │   'citations': citations,                          │     │
│  │   'finished': True                                 │     │
│  │ })}\n\n"                                           │     │
│  │                                                    │     │
│  │ Result: Streamed response with citations           │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Phase 5: Save to Database                          │     │
│  │ backend/onyx/db/chat.py                            │     │
│  │                                                    │     │
│  │ # Save user message                                │     │
│  │ user_msg = ChatMessage(                            │     │
│  │   chat_session_id=456,                             │     │
│  │   message="What are our Q4 OKRs?",                 │     │
│  │   message_type="USER",                             │     │
│  │   token_count=count_tokens("What are..."),         │     │
│  │   created_at=now                                   │     │
│  │ )                                                  │     │
│  │ db.add(user_msg)                                   │     │
│  │                                                    │     │
│  │ # Save assistant response                          │     │
│  │ assistant_msg = ChatMessage(                       │     │
│  │   chat_session_id=456,                             │     │
│  │   message=full_response_text,                      │     │
│  │   message_type="ASSISTANT",                        │     │
│  │   token_count=count_tokens(full_response),         │     │
│  │   citations=citations,                             │     │
│  │   created_at=now                                   │     │
│  │ )                                                  │     │
│  │ db.add(assistant_msg)                              │     │
│  │ db.commit()                                        │     │
│  │                                                    │     │
│  │ # Update usage analytics (EE)                      │     │
│  │ update_usage_report(                               │     │
│  │   user_id=current_user.id,                         │     │
│  │   tokens_used=user_msg.token_count +               │     │
│  │               assistant_msg.token_count            │     │
│  │ )                                                  │     │
│  │                                                    │     │
│  │ Result: Chat history saved for future reference    │     │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

**System Considerations:**

1. **Search Performance**:
   - Vespa query latency: ~50ms for 1M chunks
   - Embedding generation: ~100ms (cached for repeat queries)
   - Total retrieval: ~200ms
   - Scale: Vespa scales horizontally with content nodes

2. **Context Window Management**:
   - GPT-4: 8K tokens (~6K words)
   - GPT-4-32K: 32K tokens (~24K words) - more docs
   - Claude 2: 100K tokens - can use all 50 results
   - Trade-off: More context = slower + more expensive

3. **Token Costs**:
   - GPT-4: $0.03/1K prompt tokens, $0.06/1K completion
   - Typical query: 4K prompt + 1K completion = $0.18
   - For 1000 queries/day = $180/day = $5400/month
   - Optimization: Use GPT-3.5 for simple queries ($0.002/1K)

4. **Access Control**:
   - ACLs checked at search time (not at display time)
   - User sees ONLY docs they have access to
   - Groups resolved once per request
   - For 10,000 users: Use Redis cache for group memberships

5. **Streaming Benefits**:
   - User sees response immediately (perceived performance)
   - No timeout issues for long responses
   - Can show "typing" indicator
   - Lower memory usage (don't buffer full response)

---

## 6. USER GROUPS & ACCESS CONTROL (EE Feature)

```
SCENARIO: Marketing team should only see marketing docs

┌────────────────────────────────────────────────┐
│  Admin Setup                                   │
└────────────────────────────────────────────────┘
       │
       │ 1. Create User Group
       │    POST /api/manage/admin/user-group
       │    {
       │      "name": "Marketing Team",
       │      "user_ids": [10, 11, 12, 13, 14]
       │    }
       ▼
┌────────────────────────────────────────────────┐
│  Database: UserGroup Table                     │
│  ee/onyx/db/models.py                          │
│                                                │
│  INSERT INTO user_group (                      │
│    id: 5,                                      │
│    name: "Marketing Team",                     │
│    created_at: now                             │
│  )                                             │
│                                                │
│  INSERT INTO user__user_group (                │
│    user_id: 10, user_group_id: 5               │
│  )                                             │
│  ... (repeat for users 11, 12, 13, 14)         │
└────────────────────────────────────────────────┘
       │
       │ 2. Create Connector with Group Access
       │    POST /api/manage/admin/connector
       │    {
       │      "name": "Marketing Shared Drive",
       │      "source": "google_drive",
       │      "credential_id": 123,
       │      "access_type": "PRIVATE",
       │      "groups": [5]  // Marketing Team group
       │    }
       ▼
┌────────────────────────────────────────────────┐
│  Database: Connector Tables                    │
│                                                │
│  INSERT INTO connector (...)                   │
│  INSERT INTO connector_credential_pair (       │
│    connector_id: 100,                          │
│    credential_id: 123,                         │
│    access_type: "PRIVATE"                      │
│  )                                             │
│  INSERT INTO user_group__connector_credential_pair (│
│    user_group_id: 5,                           │
│    cc_pair_id: 100                             │
│  )                                             │
└────────────────────────────────────────────────┘
       │
       │ 3. Documents indexed with ACLs
       │    (During indexing pipeline)
       ▼
┌────────────────────────────────────────────────┐
│  Vespa: Chunks with ACLs                       │
│                                                │
│  Each chunk stored as:                         │
│  {                                             │
│    "id": "doc123_chunk_0",                     │
│    "content": "Q3 marketing budget...",        │
│    "embeddings": [0.123, -0.456, ...],         │
│    "access": ["group:marketing_team"],         │
│    ...                                         │
│  }                                             │
│                                                │
│  Note: "access" field contains group ID        │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  User Search Query                             │
└────────────────────────────────────────────────┘
       │
       │ User ID: 10 (member of Marketing Team)
       │ Query: "What's our marketing budget?"
       ▼
┌────────────────────────────────────────────────┐
│  Backend: Resolve User's ACLs                  │
│  ee/onyx/access/access.py                      │
│  get_acl_for_user(user_id=10)                  │
│                                                │
│  Step 1: Get user's groups                     │
│  groups = db.query(                            │
│    UserGroup                                   │
│  ).join(User__UserGroup).filter(               │
│    User__UserGroup.user_id == 10               │
│  ).all()                                       │
│  # Returns: [UserGroup(id=5, name="Marketing")]│
│                                                │
│  Step 2: Build ACL list                        │
│  acls = [                                      │
│    "user:user10@company.com",  // User's email │
│    "group:marketing_team"       // Group ID 5  │
│  ]                                             │
│                                                │
│  Result: User's ACL strings for search         │
└────────────────────────────────────────────────┘
       │
       │ ACLs: ["user:user10@...", "group:marketing_team"]
       ▼
┌────────────────────────────────────────────────┐
│  Vespa Query with ACL Filter                   │
│  backend/onyx/search/search_runner.py          │
│                                                │
│  yql = f"""                                    │
│    SELECT * FROM sources chunk                 │
│    WHERE (                                     │
│      ({nearestNeighbor(embeddings, q_embed)}   │
│       OR userQuery())                          │
│      AND (                                     │
│        access CONTAINS "user:user10@..."       │
│        OR access CONTAINS "group:marketing_team"│
│      )                                         │
│    )                                           │
│  """                                           │
│                                                │
│  Result: ONLY chunks user has access to        │
└────────────────────────────────────────────────┘
       │
       │ Returns: Marketing docs only
       ▼
┌────────────────────────────────────────────────┐
│  User sees response                            │
│  ✓ Q3 marketing budget doc                     │
│  ✓ Marketing campaign results                  │
│  ✗ Engineering docs (no access)                │
│  ✗ Finance docs (no access)                    │
└────────────────────────────────────────────────┘
```

**Access Type Options:**

| Access Type | Meaning | ACL | Use Case |
|-------------|---------|-----|----------|
| **PUBLIC** | Everyone can see | `["__public__"]` | Company wiki, announcements |
| **PRIVATE** | Specific groups only | `["group:marketing_team"]` | Team-specific docs |
| **SYNC** | Sync from external system | External IDs from GDrive/Slack | Preserve existing permissions |

**System Considerations:**

1. **Group Membership Caching**:
   - Query user's groups once per request
   - Cache in Redis: `user:10:groups` → `[5, 8, 12]`
   - TTL: 5 minutes (balance freshness vs performance)
   - Invalidate on group membership change

2. **ACL Storage**:
   - Stored in Vespa with each chunk (not in PostgreSQL)
   - Why? Search must filter before returning results
   - Array field in Vespa allows multiple ACLs per doc
   - Example: Doc shared with 3 groups = 3 ACL entries

3. **Curator Roles**:
   - Curators can manage connectors for their groups
   - Can't see other groups' connectors
   - Implemented via UI checks + API authorization
   - For 50 groups × 10 curators = scalable

4. **Performance Impact**:
   - ACL filtering adds ~10ms to query time
   - Negligible for <10 groups per user
   - For 100+ groups: Use more selective filters
   - Vespa handles billions of ACL checks efficiently

---

## 7. SECURITY BOUNDARIES

```
┌─────────────────────────────────────────────────────────────────┐
│                         PUBLIC ZONE                             │
│  - No authentication required                                   │
│  - Rate limited by IP                                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │
                    ┌───────────┴──────────┐
                    │                      │
                    ▼                      ▼
         ┌──────────────────┐   ┌──────────────────┐
         │  /login          │   │  /register       │
         │  /auth/*         │   │  /health         │
         └──────────────────┘   └──────────────────┘

                                │
                                │ JWT Authentication
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATED ZONE                           │
│  - Valid JWT required                                           │
│  - User role: BASIC / CURATOR / ADMIN                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴──────────┐
                    │                      │
                    ▼                      ▼
         ┌──────────────────┐   ┌──────────────────┐
         │  /chat           │   │  /search         │
         │  /api/query      │   │  /api/persona    │
         └──────────────────┘   └──────────────────┘
                                │
                                │ + ACL Filtering
                                ▼
         ┌──────────────────────────────────────────┐
         │  Search Results Filtered by:             │
         │  - User's email                          │
         │  - User's groups                         │
         │  - Document access_type                  │
         └──────────────────────────────────────────┘

                                │
                                │ Role Check: CURATOR or ADMIN
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CURATOR ZONE                               │
│  - CURATOR or ADMIN role required                               │
│  - Can manage own groups' connectors                            │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴──────────┐
                    │                      │
                    ▼                      ▼
         ┌──────────────────┐   ┌──────────────────┐
         │  /admin/         │   │  /api/manage/    │
         │   connectors     │   │   connector      │
         │   (own groups)   │   │   (own groups)   │
         └──────────────────┘   └──────────────────┘

                                │
                                │ Role Check: ADMIN only
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ADMIN ZONE                                │
│  - ADMIN role required                                          │
│  - Full system access                                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴──────────┬──────────┐
                    │                      │          │
                    ▼                      ▼          ▼
         ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
         │  /admin/     │   │  /admin/     │  │  /ee/admin/  │
         │   users      │   │   connectors │  │   groups     │
         │              │   │   (all)      │  │              │
         └──────────────┘   └──────────────┘  └──────────────┘
```

**Security Layers:**

1. **Network Layer**:
   - HTTPS only (TLS 1.3)
   - Firewall: Only ports 443 (web) and 22 (SSH) exposed
   - DDoS protection via rate limiting

2. **Authentication Layer**:
   - JWT with 7-day expiry
   - httpOnly cookies (prevents XSS)
   - CSRF tokens for state-changing operations

3. **Authorization Layer**:
   - Role-based access control (RBAC)
   - Group-based access control (GBAC) [EE]
   - Document-level ACLs in Vespa

4. **Data Layer**:
   - OAuth tokens encrypted at rest (AES-256)
   - Passwords hashed with bcrypt (cost 12)
   - PostgreSQL connections over SSL
   - Database credentials in environment variables

5. **Application Layer**:
   - Input validation (Pydantic models)
   - SQL injection prevention (SQLAlchemy ORM)
   - XSS prevention (React auto-escaping)

---

## 8. DEPLOYMENT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRODUCTION DEPLOYMENT                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  KUBERNETES CLUSTER                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  INGRESS CONTROLLER (NGINX)                            │    │
│  │  • SSL termination                                     │    │
│  │  • Load balancing                                      │    │
│  │  • Rate limiting                                       │    │
│  └────────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            │                                    │
│         ┌──────────────────┴──────────────────┐                │
│         │                                     │                │
│         ▼                                     ▼                │
│  ┌─────────────────┐                 ┌─────────────────┐      │
│  │  WEB POD        │                 │  API POD        │      │
│  │  Replicas: 3    │                 │  Replicas: 5    │      │
│  │                 │                 │                 │      │
│  │  Resources:     │                 │  Resources:     │      │
│  │  CPU: 500m      │                 │  CPU: 1000m     │      │
│  │  Memory: 512Mi  │                 │  Memory: 2Gi    │      │
│  │                 │                 │                 │      │
│  │  HPA:           │                 │  HPA:           │      │
│  │  Min: 3         │                 │  Min: 5         │      │
│  │  Max: 10        │                 │  Max: 20        │      │
│  │  Target: 70% CPU│                 │  Target: 70% CPU│      │
│  └─────────────────┘                 └─────────────────┘      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  WORKER PODS                                            │  │
│  │                                                         │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│  │  │ Docfetching  │  │ Docprocessing│  │    Light    │  │  │
│  │  │ Replicas: 2  │  │ Replicas: 5  │  │ Replicas: 3 │  │  │
│  │  │ CPU: 500m    │  │ CPU: 2000m   │  │ CPU: 500m   │  │  │
│  │  │ Mem: 1Gi     │  │ Mem: 4Gi     │  │ Mem: 1Gi    │  │  │
│  │  └──────────────┘  └──────────────┘  └─────────────┘  │  │
│  │                                                         │  │
│  │  ┌──────────────┐  ┌──────────────┐                   │  │
│  │  │    Heavy     │  │     Beat     │                   │  │
│  │  │ Replicas: 2  │  │ Replicas: 1  │                   │  │
│  │  │ CPU: 2000m   │  │ CPU: 100m    │                   │  │
│  │  │ Mem: 4Gi     │  │ Mem: 256Mi   │                   │  │
│  │  └──────────────┘  └──────────────┘                   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  MANAGED DATABASES (Outside K8s)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  PostgreSQL     │  │  Redis          │  │  Vespa          ││
│  │  (RDS / Cloud   │  │  (ElastiCache / │  │  (Self-hosted / ││
│  │   SQL)          │  │   MemoryStore)  │  │   Vespa Cloud)  ││
│  │                 │  │                 │  │                 ││
│  │  Instance:      │  │  Instance:      │  │  Cluster:       ││
│  │  db.r5.xlarge   │  │  cache.r5.large │  │  3 content nodes││
│  │  (4 vCPU, 32GB) │  │  (2 vCPU, 13GB) │  │  (8 vCPU, 32GB) ││
│  │                 │  │                 │  │                 ││
│  │  Storage:       │  │  Persistence:   │  │  Storage:       ││
│  │  500GB SSD      │  │  Yes (AOF)      │  │  1TB SSD/node   ││
│  │                 │  │                 │  │                 ││
│  │  Backups:       │  │  Replication:   │  │  Replication:   ││
│  │  Daily          │  │  Multi-AZ       │  │  Factor 2       ││
│  │  30-day retain  │  │                 │  │                 ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  EXTERNAL SERVICES                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │  S3 / MinIO     │  │  OpenAI API     │  │  Monitoring     ││
│  │  (File Storage) │  │  (LLM + Embed)  │  │  (DataDog /     ││
│  │                 │  │                 │  │   Grafana)      ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

**Scaling Considerations:**

| Component | Scale Type | Trigger | Target |
|-----------|-----------|---------|--------|
| Web Server | Horizontal | CPU > 70% | 3-10 pods |
| API Server | Horizontal | CPU > 70% | 5-20 pods |
| Docprocessing | Horizontal | Queue length > 100 | 5-15 pods |
| PostgreSQL | Vertical | CPU > 80% | Upgrade instance |
| Vespa | Horizontal | Disk > 80% | Add content nodes |
| Redis | Vertical | Memory > 80% | Upgrade instance |

**Cost Estimation (for 10,000 users, 1M documents):**

| Service | Specs | Monthly Cost |
|---------|-------|-------------|
| K8s Cluster | 20 nodes (m5.xlarge) | $2,400 |
| PostgreSQL | db.r5.xlarge | $450 |
| Redis | cache.r5.large | $180 |
| Vespa | 3× c5.2xlarge | $900 |
| S3 Storage | 1TB | $25 |
| OpenAI API | 10M tokens/day | $2,000 |
| **Total** | | **$5,955/month** |

---

## SUMMARY OF KEY SYSTEM DECISIONS

### 1. Why Next.js for Frontend?
- **SSR/ISR**: Fast initial page loads
- **API Routes**: Proxy to backend (avoids CORS)
- **React 18**: Streaming SSR, concurrent features
- **TypeScript**: Type safety, better DX

### 2. Why FastAPI for Backend?
- **Async**: Non-blocking I/O for high concurrency
- **Pydantic**: Automatic validation + OpenAPI docs
- **Performance**: 2-3x faster than Flask/Django
- **Type Hints**: Native Python typing

### 3. Why Vespa for Vector Search?
- **Hybrid Search**: BM25 + vector in single query
- **ACL Filtering**: Built-in access control
- **Scalability**: Handles billions of documents
- **Speed**: <100ms for complex queries
- **Alternative**: Pinecone (simpler but no BM25)

### 4. Why PostgreSQL?
- **Relational**: Complex joins for groups/permissions
- **ACID**: Data consistency guarantees
- **JSON Support**: Flexible metadata storage
- **Ecosystem**: Alembic, SQLAlchemy, tooling

### 5. Why Celery for Background Jobs?
- **Distributed**: Scale workers independently
- **Priority Queues**: Critical tasks first
- **Retry Logic**: Automatic failure handling
- **Monitoring**: Flower, built-in status tracking

### 6. Why Redis?
- **Multi-Purpose**: Queue + cache + sessions
- **Speed**: <1ms latency
- **Pub/Sub**: Real-time features
- **Persistence**: AOF for durability

---

## NEXT: Create Simplified Diagrams for Knowsee

Based on this Onyx architecture, I'll create simplified versions showing:
1. **What to keep**: Connector framework, OAuth, User groups
2. **What to replace**: Vespa→Pinecone, Celery→Simple worker
3. **What to skip**: Multi-tenancy, External permissions

Would you like me to create the Knowsee-specific simplified architecture now?
