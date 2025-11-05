# ONYX COMPLETE KNOWLEDGE GRAPH - MERMAID MINDMAP

```mermaid
mindmap
  root((🌐 ONYX<br/>Enterprise AI Search))
    🔐 **AUTH & ACCESS**
      Authentication
        JWT Tokens
          generate_jwt_token()
          verify_jwt_token()
        OAuth2
          oauth_authorization_url()
          oauth_code_to_token()
          OAuthConnector interface
        SAML SSO EE
          saml_auth_flow()
          saml_metadata_handler()
        API Keys
          create_api_key()
          validate_api_key()
        FastAPI-Users
          UserManager
          get_user_db()
          current_user dependency
      Authorization
        Access Control
          _get_access_for_documents()
          _get_acl_for_user()
          check_user_access()
        User Roles
          ADMIN
          CURATOR
          BASIC
          GLOBAL_CURATOR
        Document Permissions
          DocumentAccess model
          ExternalAccess model
          ACL filtering
        EE: User Groups
          UserGroup model
          User__UserGroup mapping
          Group-based access
          Curator privileges
        EE: External Permissions
          Permission Sync
            confluence_doc_sync()
            gdrive_doc_sync()
            jira_doc_sync()
          External Groups
            _perform_external_group_sync()
            User__ExternalUserGroupId
            PublicExternalUserGroup
          Salesforce Censoring
            censor_salesforce_chunks()

    🔌 **CONNECTORS 50+**
      Framework
        Base Interfaces
          BaseConnector
            load_credentials()
            validate_connector_settings()
          LoadConnector
            load_from_state()
          PollConnector
            poll_source()
          CheckpointedConnector
            retrieve_all_source_docs()
          OAuthConnector
            oauth_id()
            oauth_authorization_url()
          SlimConnector
            retrieve_all_slim_documents()
        Factory & Registry
          identify_connector_class()
          instantiate_connector()
          CONNECTOR_CLASS_MAP
        Models
          Document
          Section
          DocumentSource enum
          ConnectorCheckpoint
      Document Management
        Google Drive
          GoogleDriveConnector
          Batch retrieval
          Shared drives
          Permission sync
        SharePoint
          SharePointConnector
          Site traversal
          Permission sync
        Confluence
          ConfluenceConnector
          Space indexing
          Page attachments
          Permission sync
        Notion
          NotionConnector
          Workspace sync
          Database pages
        Guru
          GuruConnector
        Slab
          SlabConnector
        Bookstack
          BookstackConnector
      Cloud Storage
        Google Cloud Storage
        S3
        R2
        OCI Storage
      Communication
        Slack
          SlackConnector
          Channel indexing
          Thread retrieval
          Permission by channel
        Gmail
          GmailConnector
        Outlook
          OutlookConnector
        Discord
          DiscordConnector
        Zulip
          ZulipConnector
      Code Repositories
        GitHub
          GithubConnector
          Repo indexing
          PR/Issue sync
        GitLab
          GitlabConnector
        Bitbucket
          BitbucketConnector
      Ticketing & Project
        Jira
          JiraConnector
          Project filtering
          Permission sync
        Linear
          LinearConnector
          OAuth support
        Asana
          AsanaConnector
        ClickUp
          ClickUpConnector
        Productboard
          ProductboardConnector
      CRM & Sales
        HubSpot
          HubspotConnector
        Salesforce
          SalesforceConnector
          Object-level access
        Freshdesk
          FreshdeskConnector
        Zendesk
          ZendeskConnector
      Documentation
        GitBook
          GitbookConnector
        ReadMe
          ReadmeConnector
        Document360
          Document360Connector
        MediaWiki
          MediaWikiConnector
      Knowledge Bases
        Guru
        Slite
        Axero
        RequestTracker
      File Types
        File
          Generic file upload
        Google Sites
        Loopio
        Zotero
      Web & Feeds
        Web
          WebConnector
          Sitemap crawling
        Fireflies
          FirefliesConnector
      Specialized
        Wikipedia
          WikipediaConnector
        Gong
          GongConnector
        Egnyte
          EgnyteConnector
          OAuth support
        Dropbox
          DropboxConnector
        Box
          BoxConnector
        OneDrive
          OneDriveConnector
        Airtable
          AirtableConnector
      DLT Integration NEW
        DltGenericConnector
          Marketing sources
          Google Ads
          Facebook Ads
          LinkedIn Ads

    📄 **DOCUMENT PROCESSING**
      Indexing Pipeline
        Document Ingestion
          ConnectorRunner
            run_connector()
            _validate_connector()
          BatchIndexingRunner
        Chunking
          Chunker
            chunk_document()
            _split_by_sep()
            _chunk_large_section()
          Strategies
            By paragraph
            By sentence
            By character
            With overlap
        Embedding
          DefaultIndexingEmbedder
            embed_chunks()
            embed_batch()
          Models
            text-embedding-3-small
            voyage-context-3
            Custom models
        Content Processing
          Text Extraction
            extract_pdf_text()
            extract_docx_text()
            extract_file_text()
          Image Processing
            extract_image_content()
            get_unstructured_api_key()
          OCR
            OCR integration
        Classification
          ContentClassifier
            classify_chunks()
          Categorization
      Metadata
        Extraction
          extract_metadata()
          parse_metadata()
        Enrichment
          add_context()
          semantic_identifier
      File Storage
        Abstraction Layer
          get_default_file_store()
          FileStore interface
        Implementations
          S3 MinIO
            upload_file()
            download_file()
          Local filesystem
          GCS
          Azure Blob

    🔍 **VECTOR SEARCH Vespa**
      Document Index
        Vespa Client
          VespaIndex
            index_chunks()
            delete_documents()
            get_document()
        Schema Management
          DocumentConfig
          ChunkSchema
          Deploy schema
        Indexing Operations
          Chunk Insertion
            index()
            batch_index()
          Document Deletion
            delete()
            delete_by_connector()
          Updates
            update_metadata()
      Search & Retrieval
        Query Processing
          build_vespa_query()
          add_filters()
          add_boosting()
        Search Types
          Keyword Search
            BM25 ranking
          Semantic Search
            Vector similarity
          Hybrid Search
            RRF fusion
        Filtering
          Time decay
          Access control ACLs
          Source filtering
          Document set filtering
        Ranking
          Primary ranking
          Reranking
            Cross-encoder rerank
          Score fusion
      Knowledge Graph
        Entity Extraction
          extract_entities()
        Relationship Mapping
          build_relationships()
        Graph Queries
          traverse_graph()

    💬 **CHAT & LLM**
      Chat Pipeline
        Main Entry
          process_message()
          StreamingChatHandler
        Components
          Prompt Builder
            build_system_prompt()
            build_user_prompt()
            add_context()
          Turn Management
            ChatTurn model
            Turn tracking
          Stream Processing
            stream_chat_response()
            Citation extraction
            Quote processing
          User Files
            attach_files()
            process_uploads()
      LLM Integration
        Providers
          OpenAI
            OpenAIProvider
            gpt-4 gpt-3.5
          Anthropic
            AnthropicProvider
            claude-3-opus sonnet
          Google
            GoogleProvider
            gemini-pro
          Cohere
            CohereProvider
          Azure
            AzureProvider
          Custom
            LiteLLM support
        Interfaces
          LLM base interface
            stream()
            invoke()
          Streaming
            StreamingLLM
            handle_stream_tokens()
          Non-streaming
            StandardLLM
        Configuration
          Model selection
          Temperature
          Max tokens
          Stop sequences
        Token Management
          count_tokens()
          truncate_context()
          EE: Rate limiting
            check_token_limit()
            TokenRateLimit__UserGroup
      Context Assembly
        Search Integration
          retrieve_documents()
          rank_by_relevance()
        Context Window
          fit_to_context()
          prioritize_chunks()
        Citation Handling
          extract_citations()
          map_to_sources()
      Tools Framework
        Tool Interface
          BaseTool
            execute()
        Implementations
          Search Tool
            search()
          Image Tool
            analyze_image()
          Web Search
            web_search()
          Knowledge Graph
            graph_query()
          MCP Tools
            mcp_execute()
      Personas Assistants
        Management
          Persona model
          create_persona()
          update_persona()
        Configuration
          System prompt
          Search settings
          Tool access
          LLM selection
        EE: Private Personas
          Persona__UserGroup

    ⚙️ **BACKGROUND JOBS Celery**
      Architecture
        Message Broker
          Redis
            Queue management
            State storage
        Worker Types LIGHTWEIGHT MODE
          Unified Worker
            All tasks combined
            20 threads
        Worker Types STANDARD MODE
          Primary Worker
            Coordination
            4 threads
          Docfetching Worker
            Fetch from connectors
            Configurable concurrency
          Docprocessing Worker
            Index pipeline
            Configurable concurrency
          Light Worker
            Fast operations
            Higher concurrency
          Heavy Worker
            Resource-intensive
            4 threads
          KG Processing Worker
            Knowledge graph
          Monitoring Worker
            Health checks
            Single thread
          User File Processing Worker
            User uploads
          Beat Scheduler
            Periodic tasks
            DynamicTenantScheduler
      Task Categories
        Indexing
          Connector Indexing
            run_connector_index()
            Index job coordination
          Document Sync
            sync_vespa()
            Vespa operations
          Pruning
            prune_documents()
            Remove stale docs
        Connector Management
          Deletion
            delete_connector()
            Cleanup
          Validation
            validate_connector()
        Permission Syncing EE
          Document Permissions
            sync_doc_permissions()
          Group Syncing
            sync_external_groups()
        Monitoring
          Health Checks
            check_celery_queues()
            check_process_memory()
          System Status
            collect_metrics()
        Cleanup
          Periodic cleanup
            cleanup_old_data()
          User file sync
            sync_user_files()
      Task Management
        Scheduling
          Beat schedule
            Periodic intervals
            Per-task config
        Priority Queues
          High priority
          Medium priority
          Low priority
        State Tracking
          Task status
          Retry logic
          Failure handling
      Multi-Tenancy
        Tenant Awareness
          DynamicTenantScheduler
          Per-tenant tasks
        Isolation
          Schema routing
          Redis namespacing

    🗄️ **DATABASE PostgreSQL**
      Core Models
        User Management
          User
            email password
            role is_active
          User__UserGroup EE
          User__ExternalUserGroupId EE
        Connector System
          Connector
            source config
            status
          Credential
            credential_json encrypted
            source user_id
          ConnectorCredentialPair
            access_type
            auto_sync_options
        Document Models
          Document
            external_id
            metadata
          DocumentByConnectorCredentialPair
          DocumentSet
          DocumentSet__ConnectorCredentialPair
        Chat System
          ChatSession
          ChatMessage
          ChatMessageFeedback
          Persona
          Prompt
        Search & Retrieval
          SearchDoc
          QueryEvent
          DocumentRetrievalFeedback
      EE Models
        Access Control
          UserGroup
          UserGroup__ConnectorCredentialPair
          ExternalAccess
          DocExternalAccess
          PublicExternalUserGroup
        Knowledge Management
          StandardAnswer
          StandardAnswerCategory
          StandardAnswer__StandardAnswerCategory
          ChatMessage__StandardAnswer
        Rate Limiting
          TokenRateLimit__UserGroup
        Analytics
          UsageReportMetadata
          ChatSessionSnapshot
        Permission Syncing
          DocPermissionSyncAttempt
          ExternalGroupPermissionSyncAttempt
      Operations
        CRUD Operations
          50+ operation files
          User ops
          Connector ops
          Document ops
          Chat ops
        Migrations
          Alembic
            100+ migrations
            Schema evolution
          Multi-tenant
            schema_private
      Custom Types
        Encryption
          EncryptedString
          EncryptedJson
        Enums
          AccessType
          UserRole
          QAFeedbackType

    🌐 **API SERVER FastAPI**
      Endpoint Categories
        Authentication
          /auth/login
          /auth/logout
          /auth/register
          /auth/verify
        Query & Chat
          /query
            Search endpoint
          /chat/send-message
            Chat endpoint
          /chat/stream
            Streaming chat
          EE: /query/oneshot-qa
            Advanced API
        Document Management
          /manage/admin/connector
            CRUD connectors
          /manage/admin/credential
            CRUD credentials
          /connector/oauth
            OAuth flow
            /authorize
            /callback
        Admin Features
          /manage/admin/user
            User management
          /manage/admin/user-group EE
            Group management
          /manage/admin/standard-answer EE
            Standard answers
          /manage/admin/token-rate-limits EE
            Rate limit config
        Analytics EE
          /admin/analytics/usage
            Usage reports
          /admin/query-history
            Query logs
        Settings
          /manage/admin/settings
          /manage/admin/enterprise-settings EE
      Middleware
        Authentication
          JWT verification
          API key check
        Rate Limiting
          Per-user limits
          Per-endpoint limits
        Tenant Routing EE
          Tenant detection
          Schema switching
        Logging
          Latency tracking
          Error logging
      Dependencies
        Database Session
          get_session()
        Current User
          current_user()
          current_admin()
        Feature Flags
          check_feature_enabled()

    📊 **EE FEATURES ENTERPRISE**
      Permission System
        User Groups
          Group Management
            create_user_group()
            add_users_to_group()
            assign_connectors()
          Curator Roles
            Group curators
            Permission delegation
          Integration Points
            43 files integrate
            fetch_versioned_implementation()
        External Permissions
          Document Sync
            Confluence
            Google Drive
            Jira
            SharePoint
            Salesforce
            Slack
          Group Sync
            Google Workspace
            Azure AD
            External IDP
          Access Mapping
            External ID mapping
            User email mapping
        Access Control
          ACL System
            prefix_user_email()
            prefix_user_group()
            prefix_external_group()
          Filtering
            Search result filtering
            Document access checks
          Censoring
            Salesforce censoring
            Fine-grained filtering
      Analytics & Reporting
        Query History
          ChatSessionMinimal
          ChatSessionSnapshot
          Feedback tracking
        Usage Analytics
          Usage metrics
          Per-persona stats
          Token usage
        Reporting
          CSV export
          Usage reports
          Audit logs
        Dashboards
          Admin analytics
          Usage charts
          Feedback visualization
      Knowledge Management
        Standard Answers
          Answer Database
            StandardAnswer model
            Category organization
          Matching
            Keyword matching
            Regex matching
            match_any_keywords flag
          Integration
            Slack auto-response
            Chat pipeline integration
          CRUD Operations
            Create answer
            Update answer
            Delete answer
      Resource Management
        Token Rate Limiting
          Per-Group Limits
            TokenRateLimit__UserGroup
            Quota enforcement
          Usage Tracking
            Token counting
            Usage aggregation
          Limit Enforcement
            Query pipeline checks
            Alert on approaching limit
      Multi-Tenancy
        Tenant Isolation
          Schema separation
          Per-tenant DB
        Tenant Routing
          get_tenant_id_for_email()
          Middleware routing
        Configuration
          Per-tenant settings
          Multi-tenant scheduler
      Advanced Features
        Feature Flags
          PostHog integration
          A/B testing
          Gradual rollouts
        Billing EE
          Subscription management
          Usage tracking
          Payment integration
        White-Labeling EE
          Custom branding
          Logo upload
          Theme customization

    🎨 **FRONTEND Next.js**
      Pages Structure
        Public Pages
          /login
          /register
          /search
          /chat
        Admin Pages
          /admin/connectors
            Connector setup
            OAuth flows
          /admin/indexing
            Index status
          /admin/users
            User management
        EE Admin Pages
          /ee/admin/groups
            Group management
          /ee/admin/performance
            Analytics dashboards
            Query history
            Usage reports
          /ee/admin/standard-answer
            Answer management
          /ee/admin/billing
            Subscription
          /ee/admin/whitelabeling
            Branding config
      Components
        Chat Interface
          ChatWindow
          MessageList
          InputBox
          Streaming display
        Search UI
          SearchBar
          ResultsList
          Filters
          Citations
        Connector Setup
          ConnectorForm
          OAuth flows
          Credential forms
        Admin Components
          UserTable
          GroupEditor EE
          AnalyticsCharts EE
      State Management
        SWR for data fetching
        React hooks
        User context
      API Integration
        /api routes
          Next.js API routes
        Backend proxy
          INTERNAL_URL routing

    🛠️ **INFRASTRUCTURE**
      Configuration
        App Config
          Constants
          Feature flags
          Environment vars
        LLM Config
          Model settings
          Provider config
        Embedding Config
          Model selection
          Dimension settings
      Redis
        Use Cases
          Celery broker
          State storage
          OAuth state
          Caching
        Namespacing
          Per-tenant
          Per-feature
        Operations
          redis_connector
          redis_usergroup
      Monitoring
        Logging
          setup_logger()
          Structured logging
        Tracing
          Request tracing
          Span tracking
        Telemetry
          Usage metrics
          Error tracking
        Health Checks
          /health endpoint
          Service status
      Utilities
        NLP
          Tokenization
          Text processing
        Encryption
          encrypt_string()
          decrypt_string()
        Versioning
          OnyxVersion
          EE detection
          fetch_versioned_implementation()
      Deployment
        Docker
          Backend Dockerfile
          Web Dockerfile
          Model server
        Docker Compose
          10+ compose files
          9-10 services
        Kubernetes
          Helm charts
          Multi-replica
      Testing
        Unit Tests
          Component isolation
        Integration Tests
          Full stack tests
          Connector tests
        Daily Tests
          Connector validation
          Permission tests
        Regression Tests
          Search quality
          Answer quality
```

## **LEGEND**

- 🔐 **AUTH & ACCESS**: Authentication, Authorization, Permissions
- 🔌 **CONNECTORS**: 50+ data source integrations
- 📄 **DOCUMENT PROCESSING**: Chunking, Embedding, Indexing
- 🔍 **VECTOR SEARCH**: Vespa integration, Search & Retrieval
- 💬 **CHAT & LLM**: Chat pipeline, LLM providers, Tools
- ⚙️ **BACKGROUND JOBS**: Celery workers, Task management
- 🗄️ **DATABASE**: PostgreSQL models, Operations
- 🌐 **API SERVER**: FastAPI endpoints, Middleware
- 📊 **EE FEATURES**: Enterprise Edition features
- 🎨 **FRONTEND**: Next.js UI components
- 🛠️ **INFRASTRUCTURE**: Config, Redis, Monitoring

## **EE ENTERPRISE EDITION HIGHLIGHTS**

Features marked with **EE** require `ENABLE_PAID_ENTERPRISE_EDITION_FEATURES=true`:

- User Groups & Group-based access control
- External permission syncing (Google Drive, Confluence, etc.)
- Standard Answers for FAQ automation
- Query History & Analytics dashboards
- Token Rate Limiting per group
- Multi-tenancy support
- Billing & White-labeling
- Advanced query models (OneShotQA)

## **KEY INTEGRATION PATTERNS**

1. **Dynamic EE Loading**: `fetch_versioned_implementation()` in 43 files
2. **Connector Framework**: Base interfaces → 50+ implementations
3. **Document Pipeline**: Ingest → Chunk → Embed → Index → Search
4. **Chat Flow**: Query → Retrieve → Context → LLM → Stream → Citations
5. **Permission Model**: User/Group → ACLs → Vespa filters → Secure results
6. **Background Processing**: Celery tasks → 9 workers OR 1 unified worker

## **DATA FLOW EXAMPLES**

### **OAuth Flow**:
```
User clicks "Connect" → /oauth/authorize → State in Redis
→ Redirect to Provider → User authorizes → /oauth/callback
→ Exchange code for token → Store encrypted credential → Done
```

### **Document Indexing**:
```
Connector fetches docs → Chunking → Embedding (OpenAI/custom)
→ Vespa indexing → ACL attachment → Searchable
```

### **Chat Query**:
```
User message → Search Vespa (with ACL filter) → Retrieve top chunks
→ Build context → LLM (OpenAI/Claude) → Stream response → Extract citations
```

### **Permission Sync (EE)**:
```
Celery task → Connector fetches permissions (Google API)
→ Map external users to Onyx users → Store in ExternalAccess
→ Update Vespa ACLs → Filtered search results
```

---

## **TECHNOLOGY STACK SUMMARY**

| Layer | Technology |
|-------|------------|
| **Backend** | Python 3.11, FastAPI, SQLAlchemy, Alembic |
| **Database** | PostgreSQL 15 |
| **Vector DB** | Vespa 8.5 |
| **Cache/Queue** | Redis 7 |
| **Task Queue** | Celery with Redis broker |
| **Frontend** | Next.js 15, React 18, TypeScript, Tailwind |
| **Auth** | FastAPI-Users, JWT, OAuth2, SAML (EE) |
| **LLM** | OpenAI, Anthropic, Google, Cohere, Azure (via LiteLLM) |
| **Embedding** | OpenAI, Voyage, Custom model server |
| **Storage** | MinIO/S3, Local, GCS, Azure Blob |
| **Deployment** | Docker, Docker Compose, Kubernetes (Helm) |

---

## **COMPLEXITY METRICS**

- **Total Backend Files**: ~1,000+ Python files
- **Lines of Code**: ~100,000 LOC (backend)
- **Database Tables**: 50+ models (30+ core, 20+ EE)
- **API Endpoints**: 100+ routes
- **Connectors**: 50+ implementations
- **Celery Workers**: 9 specialized (or 1 unified in lightweight mode)
- **Background Tasks**: 50+ task types
- **Docker Services**: 9-10 containers
- **Frontend Pages**: 50+ routes
- **Tests**: 1,000+ test files

---

## **EXTRACTION GUIDANCE FOR KNOWSEE**

### **EXTRACT (HIGH VALUE)**
- ✅ Connector framework (300 LOC)
- ✅ Document model (150 LOC)
- ✅ OAuth flow (150 LOC)
- ✅ User groups (500 LOC)
- ✅ Standard answers (300 LOC)
- ✅ Query history (200 LOC)
- ✅ Access control basics (400 LOC)

### **REPLACE (SIMPLER ALTERNATIVES)**
- ❌ Vespa → Use Pinecone (2000 LOC → 100 LOC)
- ❌ Custom chunking → Use LangChain (1000 LOC → 10 LOC)
- ❌ 9 Celery workers → 1 worker (3000 LOC → 200 LOC)
- ❌ FastAPI-Users → NextAuth.js (simpler)
- ❌ Custom auth → OAuth only

### **SKIP (ENTERPRISE BLOAT)**
- ❌ Multi-tenancy (10,000 LOC)
- ❌ External permission sync (4,000 LOC)
- ❌ Federated search (2,000 LOC)
- ❌ SlackBot (3,000 LOC)
- ❌ 20+ enterprise features (20,000+ LOC)

**Total Reduction: 100,000 LOC → 3,000 LOC (97% savings)**

---

This mindmap represents the **complete architecture** of Onyx with every major component, function, and relationship. Use this as your reference for understanding, extracting, or building upon Onyx's foundation.
