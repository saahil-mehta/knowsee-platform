# Data Ingestion Pipeline

Automated Vertex AI Pipelines workflow for ingesting documents into Vertex AI Search. Orchestrates document loading, chunking, embedding generation, and import to enable RAG capabilities.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│ Pipeline Orchestration (Vertex AI Pipelines / Kubeflow)            │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
       ┌───────────┴───────────┐
       │                       │
       ▼                       ▼
┌─────────────┐         ┌─────────────┐
│  Component  │         │  Component  │
│   1: Load   │────────▶│  2: Process │
│  Documents  │         │  & Chunk    │
└─────────────┘         └─────────────┘
       │                       │
       │ GCS Bucket            │ Chunked Documents
       ▼                       ▼
┌─────────────┐         ┌─────────────┐
│   Source    │         │  Component  │
│  Documents  │         │  3: Embed   │
│  (PDF,TXT)  │         │  Documents  │
└─────────────┘         └─────────────┘
                               │
                               │ Embeddings + Metadata
                               ▼
                        ┌─────────────┐
                        │  Component  │
                        │  4: Import  │
                        │ to Datastore│
                        └─────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │  Vertex AI  │
                        │   Search    │
                        │  Datastore  │
                        └─────────────┘
```

## Pipeline Components

### 1. Load Documents (`components/ingest_data.py`)
- Reads documents from configured GCS bucket
- Supports multiple formats: PDF, TXT, HTML, DOCX
- Extracts metadata (filename, upload date, content type)
- Outputs document list with content and metadata

### 2. Process and Chunk (`components/process_data.py`)
- Splits documents into manageable chunks
- Default chunk size: 1000 characters with 200 character overlap
- Preserves document context across chunks
- Maintains source references for citation

### 3. Embed Documents (Built-in Vertex AI)
- Generates embeddings using text-embedding-005
- 768-dimensional vectors for semantic search
- Batch processing for efficiency
- Handles rate limiting and retries

### 4. Import to Datastore (Built-in Vertex AI)
- Uploads processed documents to Vertex AI Search
- Indexes embeddings for fast retrieval
- Updates existing documents if already indexed
- Triggers re-indexing automatically

## Configuration

### Environment Variables

The pipeline uses environment variables for configuration:

```bash
# Required
PROJECT_ID="your-gcp-project-id"
DATA_STORE_ID="knowsee-datastore"
DATA_STORE_REGION="eu"

# Optional
REGION="europe-west2"
SERVICE_ACCOUNT="knowsee-rag@${PROJECT_ID}.iam.gserviceaccount.com"
PIPELINE_ROOT="gs://${PROJECT_ID}-knowsee-rag"
PIPELINE_NAME="data-ingestion-pipeline"
```

### Pipeline Parameters

Configured in `submit_pipeline.py`:

```python
pipeline_params = {
    "project_id": PROJECT_ID,
    "data_store_id": DATA_STORE_ID,
    "data_store_region": DATA_STORE_REGION,
    "chunk_size": 1000,              # Characters per chunk
    "chunk_overlap": 200,            # Overlap between chunks
    "embedding_model": "text-embedding-005",
    "batch_size": 100,               # Documents per batch
}
```

## Prerequisites

### Infrastructure Setup

Ensure infrastructure is deployed:

```bash
make setup-dev-env
```

This creates:
- GCS bucket for pipeline artifacts (`{project}-knowsee-rag`)
- Service account with required permissions (`knowsee-rag`)
- Vertex AI Search datastore
- IAM bindings for pipeline execution

### Service Account Permissions

The pipeline service account requires:
- `roles/aiplatform.user` - Execute Vertex AI Pipelines
- `roles/storage.admin` - Access GCS buckets
- `roles/discoveryengine.editor` - Import to datastore

## Running the Pipeline

### One-Time Execution

Run immediately for initial data load:

```bash
make data-ingestion
```

This command:
1. Reads configuration from `gcloud config get-value project`
2. Submits pipeline to Vertex AI Pipelines
3. Prints execution link for monitoring
4. Returns immediately (pipeline runs asynchronously)

### Scheduled Execution

For periodic updates, configure cron schedule:

```bash
# Edit deployment/terraform/vars/dev.tfvars
pipeline_cron_schedule = "0 0 * * 0"  # Weekly on Sunday at midnight
```

Apply terraform to create Cloud Scheduler job:

```bash
make setup-dev-env
```

### Manual Execution with Custom Parameters

```bash
cd data_ingestion
uv run data_ingestion_pipeline/submit_pipeline.py \
  --project-id="your-project-id" \
  --region="europe-west2" \
  --data-store-id="custom-datastore" \
  --data-store-region="eu" \
  --service-account="custom-sa@project.iam.gserviceaccount.com" \
  --pipeline-root="gs://custom-bucket/pipelines" \
  --pipeline-name="custom-pipeline"
```

## Monitoring

### Vertex AI Pipelines Console

1. Navigate to [Vertex AI Pipelines](https://console.cloud.google.com/vertex-ai/pipelines)
2. Select your project
3. Find the pipeline execution by name
4. Click to view detailed logs and metrics

### Pipeline Execution Details

Each execution shows:
- Start time and duration
- Component status (running, succeeded, failed)
- Logs for each component
- Artifacts (intermediate outputs)
- Error messages if failed

### Cloud Logging

Pipeline logs are exported to Cloud Logging:

```bash
# View pipeline logs
gcloud logging read "resource.type=aiplatform.googleapis.com/PipelineJob" \
  --project=<project-id> \
  --limit=50 \
  --format=json
```

## Document Management

### Uploading Documents

Place documents in the configured GCS bucket:

```bash
# Upload single file
gcloud storage cp document.pdf gs://${PROJECT_ID}-knowsee-rag/documents/

# Upload directory
gcloud storage cp -r ./docs/* gs://${PROJECT_ID}-knowsee-rag/documents/
```

Supported formats:
- PDF (`.pdf`)
- Plain text (`.txt`)
- HTML (`.html`)
- Markdown (`.md`)
- Microsoft Word (`.docx`)

### Document Structure

For best results, structure documents with:
- Clear headings and sections
- Metadata in filename or document properties
- Consistent formatting
- Reasonable length (prefer multiple smaller documents over single large ones)

### Updating Documents

To update existing documents:
1. Upload new version to GCS with same filename
2. Run pipeline - existing datastore entries will be updated
3. Verify update in Vertex AI Search console

### Deleting Documents

To remove documents from the index:
1. Delete from GCS bucket
2. Run pipeline with `--delete-missing` flag (custom implementation required)
3. Or manually delete from Vertex AI Search console

## Troubleshooting

### Pipeline fails immediately

**Cause**: Missing permissions or configuration

**Solution**:
```bash
# Verify infrastructure exists
terraform state list | grep module.storage_buckets
terraform state list | grep module.discovery_engine

# Check service account permissions
gcloud projects get-iam-policy <project-id> \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:knowsee-rag@*"
```

### Embedding generation errors

**Cause**: API quota exceeded or authentication issues

**Solution**:
```bash
# Check quota
gcloud services quota list --service=aiplatform.googleapis.com \
  --filter="limit_name:requests_per_minute"

# Verify API enabled
gcloud services list --enabled | grep aiplatform
```

### Import to datastore fails

**Error**: `400 The embedding field path: embedding not found in schema`

**Cause**: Datastore not fully initialized

**Solution**: Wait 5-10 minutes after first pipeline run, then retry. Initial datastore setup requires time to propagate schema.

### Documents not appearing in search

**Cause**: Indexing delay or incorrect datastore ID

**Solution**:
```bash
# Verify datastore exists
gcloud discovery-engine data-stores list \
  --location=<data-store-region> \
  --project=<project-id>

# Check datastore ID matches configuration
echo $DATA_STORE_ID
```

### Pipeline runs but no documents processed

**Cause**: Empty GCS bucket or incorrect bucket path

**Solution**:
```bash
# List documents in bucket
gcloud storage ls gs://${PROJECT_ID}-knowsee-rag/documents/

# Verify bucket permissions
gcloud storage buckets get-iam-policy gs://${PROJECT_ID}-knowsee-rag
```

## Performance Optimization

### Batch Size Tuning

Increase batch size for faster processing of large document sets:

```python
# In submit_pipeline.py
pipeline_params = {
    "batch_size": 500,  # Process 500 documents per batch
}
```

Trade-off: Higher batch sizes use more memory but reduce API calls.

### Parallel Execution

Enable parallel component execution for independent steps:

```python
# In pipeline.py
with dsl.ParallelFor(documents) as doc:
    process_component(document=doc)
```

### Chunking Strategy

Adjust chunk size based on document type:

- **Technical docs**: Smaller chunks (500 chars) for precise retrieval
- **Narrative content**: Larger chunks (2000 chars) for context
- **Mixed content**: Default (1000 chars)

## Advanced Configuration

### Custom Embedding Models

Switch to different embedding model:

```python
pipeline_params = {
    "embedding_model": "textembedding-gecko@003",  # Alternative model
}
```

Available models:
- `text-embedding-005` (recommended, 768 dims)
- `textembedding-gecko@003` (768 dims)
- `text-multilingual-embedding-002` (768 dims, multilingual)

### Custom Chunking Logic

Edit `components/process_data.py` to implement custom chunking:

```python
def custom_chunker(text: str, chunk_size: int) -> List[str]:
    """Custom chunking logic based on business requirements."""
    # Example: Split on paragraph boundaries
    paragraphs = text.split('\n\n')
    chunks = []
    current_chunk = ""

    for para in paragraphs:
        if len(current_chunk) + len(para) < chunk_size:
            current_chunk += para + "\n\n"
        else:
            chunks.append(current_chunk.strip())
            current_chunk = para + "\n\n"

    if current_chunk:
        chunks.append(current_chunk.strip())

    return chunks
```

### Metadata Enrichment

Add custom metadata to documents for filtering:

```python
def enrich_metadata(document: Dict) -> Dict:
    """Add custom metadata fields."""
    document["metadata"]["department"] = extract_department(document["source"])
    document["metadata"]["classification"] = classify_document(document["content"])
    return document
```

## Integration with Agent

The agent automatically queries indexed documents via `retrieve_docs` tool in `app/agent.py`:

```python
def retrieve_docs(query: str) -> str:
    retrieved_docs = retriever.invoke(query)  # Queries Vertex AI Search
    ranked_docs = compressor.compress_documents(documents=retrieved_docs, query=query)
    return format_docs.format(docs=ranked_docs)
```

Configuration:
- Retrieves top-10 documents
- Re-ranks to top-5 using Vertex AI Rank API
- Formats for LLM context

## Additional Resources

- [Vertex AI Pipelines Documentation](https://cloud.google.com/vertex-ai/docs/pipelines/introduction)
- [Vertex AI Search Documentation](https://cloud.google.com/generative-ai-app-builder/docs/enterprise-search-introduction)
- [Kubeflow Pipelines SDK](https://www.kubeflow.org/docs/components/pipelines/v2/)
- [Main README](../README.md) - Project overview and quick start
