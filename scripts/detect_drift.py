#!/usr/bin/env python3
"""Detect GCP resources not managed by Terraform."""

import argparse
import sys
from datetime import datetime, timezone

import google.auth
from google.cloud import aiplatform_v1


def get_project_id() -> str:
    """Get current GCP project."""
    _, project_id = google.auth.default()
    return str(project_id) if project_id else ""


def scan_agent_engines(project_id: str, regions: list[str], environment: str | None = None) -> list[dict]:
    """Scan for Agent Engines across regions."""
    resources = []
    for region in regions:
        try:
            client = aiplatform_v1.ReasoningEngineServiceClient(
                client_options={"api_endpoint": f"{region}-aiplatform.googleapis.com"}
            )
            request = aiplatform_v1.ListReasoningEnginesRequest(
                parent=f"projects/{project_id}/locations/{region}"
            )
            for engine in client.list_reasoning_engines(request=request):
                engine_name = engine.display_name or "unnamed"

                # Filter by environment if specified
                if environment:
                    # Check if resource name contains environment identifier
                    env_patterns = [f"-{environment}-", f"_{environment}_", f"{environment}-", f"-{environment}"]
                    if not any(pattern in engine_name.lower() for pattern in env_patterns):
                        continue

                age_days = (datetime.now(timezone.utc) - engine.create_time).days
                resources.append({
                    "type": "Agent Engine",
                    "name": engine_name,
                    "region": region,
                    "id": engine.name.split("/")[-1],
                    "created": engine.create_time.strftime("%Y-%m-%d"),
                    "age_days": age_days,
                })
        except Exception as e:
            print(f"Warning: Failed to scan region {region}: {e}", file=sys.stderr)
    return resources


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Detect GCP resources not managed by Terraform")
    parser.add_argument(
        "--environment", "-e",
        choices=["cicd", "dev", "staging", "prod"],
        help="Filter resources by environment (cicd, dev, staging, prod)"
    )
    args = parser.parse_args()

    project_id = get_project_id()
    if not project_id:
        print("Error: Could not determine GCP project")
        sys.exit(1)

    regions = ["us-central1", "europe-west2", "asia-northeast1"]

    print("Drift Detection Report")
    print("=" * 80)
    print(f"Project: {project_id}")
    if args.environment:
        print(f"Environment: {args.environment}")
    else:
        print("Environment: all (use --environment to filter)")
    print()

    # Scan Agent Engines
    agent_engines = scan_agent_engines(project_id, regions, args.environment)

    if not agent_engines:
        env_msg = f" in {args.environment} environment" if args.environment else ""
        print(f"No unmanaged resources detected{env_msg}")
        return

    env_msg = f" in {args.environment} environment" if args.environment else ""
    print(f"Found {len(agent_engines)} resource(s) not in Terraform{env_msg}:\n")

    for resource in sorted(agent_engines, key=lambda r: r["created"]):
        print(f"{resource['type']:20} | "
              f"{resource['name']:20} | "
              f"{resource['region']:15} | "
              f"{resource['created']} ({resource['age_days']}d ago)")

    print("\n" + "=" * 80)
    print(f"Total drift: {len(agent_engines)} resource(s)")
    sys.exit(1)


if __name__ == "__main__":
    main()
