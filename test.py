import requests
import time

agent_url = "https://test-111-5994005714.europe-west2.run.app"
for i in range(10):
    try:
        response = requests.post(
              agent_url,
              json={"query": None},  # This should fail validation
              timeout=5
          )
        print(f"Request {i}: {response.status_code}")
    except Exception as e:
        print(f"Request {i} error: {e}")
    time.sleep(1)  # Space them out