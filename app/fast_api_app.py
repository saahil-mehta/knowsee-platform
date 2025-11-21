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

import os
import warnings

# Suppress Pydantic warning from ag-ui/ADK library internals
warnings.filterwarnings(
    "ignore",
    category=UserWarning,
    module="pydantic._internal._generate_schema",
)

import google.auth
from fastapi import FastAPI
from google.adk.cli.fast_api import get_fast_api_app
from google.cloud import logging as google_cloud_logging
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider, export
from vertexai import agent_engines

from app.agui_adapter import register_agui
from app.app_utils.gcs import create_bucket_if_not_exists
from app.app_utils.tracing import CloudTraceLoggingSpanExporter
from app.app_utils.typing import Feedback

_, project_id = google.auth.default()
logging_client = google_cloud_logging.Client()
logger = logging_client.logger(__name__)
allow_origins = (
    os.getenv("ALLOW_ORIGINS", "").split(",") if os.getenv("ALLOW_ORIGINS") else None
)

bucket_name = f"gs://{project_id}-sagent-logs"
create_bucket_if_not_exists(
    bucket_name=bucket_name, project=project_id, location="europe-west2"
)

provider = TracerProvider()
processor = export.BatchSpanProcessor(CloudTraceLoggingSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

AGENT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Agent Engine configuration
# Get Agent Engine resource name from environment variable (set by Terraform)
# Format: projects/{project}/locations/{location}/reasoningEngines/{id}
agent_engine_resource_name = os.environ.get("AGENT_ENGINE_RESOURCE_NAME")

if not agent_engine_resource_name:
    raise ValueError(
        "AGENT_ENGINE_RESOURCE_NAME environment variable is required. "
        "This should be set by Terraform and points to the Agent Engine instance."
    )

try:
    # Get existing Agent Engine by resource name (no dynamic creation)
    agent_engine = agent_engines.get(agent_engine_resource_name)
    logger.log_struct(
        {
            "message": "Successfully connected to Agent Engine",
            "resource_name": agent_engine_resource_name,
            "display_name": agent_engine.display_name,
        },
        severity="INFO",
    )
except Exception as e:
    logger.log_struct(
        {
            "message": "Failed to get Agent Engine",
            "resource_name": agent_engine_resource_name,
            "error": str(e),
        },
        severity="ERROR",
    )
    raise RuntimeError(
        f"Failed to get Agent Engine '{agent_engine_resource_name}'. "
        f"Ensure it exists in your GCP project. Error: {e}"
    ) from e

# Session and Memory service URIs (both point to same Agent Engine)
# The Agent Engine provides both session management and memory bank services
session_service_uri = f"agentengine://{agent_engine.resource_name}"
memory_service_uri = f"agentengine://{agent_engine.resource_name}"

app: FastAPI = get_fast_api_app(
    agents_dir=AGENT_DIR,
    web=True,
    artifact_service_uri=bucket_name,
    allow_origins=allow_origins,
    session_service_uri=session_service_uri,
    memory_service_uri=memory_service_uri,
)
app.title = "sagent"
app.description = "API for interacting with the Agent sagent"

# Mount the AG-UI compatible endpoint CopilotKit talks to
register_agui(app)


@app.post("/feedback")
def collect_feedback(feedback: Feedback) -> dict[str, str]:
    """Collect and log feedback.

    Args:
        feedback: The feedback data to log

    Returns:
        Success message
    """
    logger.log_struct(feedback.model_dump(), severity="INFO")
    return {"status": "success"}


# Main execution
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
