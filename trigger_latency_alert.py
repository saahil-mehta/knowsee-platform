#!/usr/bin/env python3
"""
Trigger HIGH LATENCY alert (easiest to test).
Just sends 20 slow, complex queries that take >3 seconds each.
"""

import subprocess
import time
import requests


def get_access_token():
    """Get gcloud access token."""
    result = subprocess.run(
        ["gcloud", "auth", "print-access-token"],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()


def trigger_latency_alert():
    """Trigger latency alert with 20 slow requests."""

    PROJECT_ID = "sp-data-platform-dev"
    REGION = "us-central1"
    ENGINE_ID = "8477239048199471104"

    print("🐌 Triggering HIGH LATENCY alert (easiest to test)")
    print(f"Sending 20 complex queries that take >3 seconds each")
    print("Threshold: P95 latency > 3000ms")
    print("This will take ~3-4 minutes\n")

    # Get access token
    token = get_access_token()

    url = f"https://{REGION}-aiplatform.googleapis.com/v1/projects/{PROJECT_ID}/locations/{REGION}/reasoningEngines/{ENGINE_ID}:query"

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Complex query designed to be slow
    payload = {
        "input": {
            "query": (
                "Please provide an extremely detailed, comprehensive analysis of "
                "quantum field theory, general relativity, string theory, loop quantum gravity, "
                "and M-theory. Include all mathematical foundations, experimental evidence, "
                "historical development, current debates, and future research directions. "
                "Be as thorough and detailed as possible, covering every aspect in depth."
            )
        }
    }

    for i in range(1, 21):
        print(f"[{i}/20] Sending slow query...", end="", flush=True)
        start = time.time()

        try:
            response = requests.post(url, json=payload, headers=headers, timeout=60)
            elapsed = time.time() - start
            print(f" ✓ Completed in {elapsed:.1f}s")
        except requests.Timeout:
            print(f" ✓ Timeout (>60s)")
        except Exception as e:
            elapsed = time.time() - start
            print(f" ✓ {elapsed:.1f}s ({type(e).__name__})")

        # Brief pause
        time.sleep(5)

    print("\n✅ Done! Alert should fire within 5-10 minutes\n")
    print("📧 Check inbox for: Google Cloud Monitoring <noreply@google.com>")
    print("   Subject: 'test-alerting-2 - High P95 Latency opened'\n")
    print(f"🔍 Monitor in console:")
    print(f"   https://console.cloud.google.com/monitoring/alerting/incidents?project={PROJECT_ID}")


if __name__ == "__main__":
    trigger_latency_alert()
