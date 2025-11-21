/**
 * Vertex AI Agent Engine Configuration
 *
 * Uses existing Agent Engine "sagent" in the project.
 * Agent Engine provides session management and memory bank services.
 */

# Get the existing Agent Engine resource using asset search
data "external" "agent_engine" {
  program = ["bash", "-c", <<-EOT
    set -e

    PROJECT_ID="${var.project_id}"
    LOCATION="${var.region}"

    # Find any Agent Engine in the project and region using asset search
    ASSET_NAME=$(gcloud asset search-all-resources \
      --scope=projects/$PROJECT_ID \
      --asset-types=aiplatform.googleapis.com/ReasoningEngine \
      --query="location=$LOCATION" \
      --format="value(name)" \
      --limit=1 2>/dev/null)

    if [ -z "$ASSET_NAME" ]; then
      echo '{"error": "No Agent Engine found in project. Create one manually first."}' >&2
      exit 1
    fi

    # Extract resource name from asset name
    # Asset name format: //aiplatform.googleapis.com/projects/PROJECT/locations/LOCATION/reasoningEngines/ID
    # We need: projects/PROJECT/locations/LOCATION/reasoningEngines/ID
    RESOURCE_NAME=$(echo "$ASSET_NAME" | sed 's|^//aiplatform.googleapis.com/||')

    # Extract ID
    ENGINE_ID=$(echo "$RESOURCE_NAME" | awk -F'/' '{print $NF}')

    echo "{\"resource_name\": \"$RESOURCE_NAME\", \"id\": \"$ENGINE_ID\"}"
  EOT
  ]
}
