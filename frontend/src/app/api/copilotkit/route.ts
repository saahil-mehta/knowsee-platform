import {
  CopilotRuntime,
  ExperimentalEmptyAdapter,
  copilotRuntimeNextJSAppRouterEndpoint,
} from "@copilotkit/runtime";
import { HttpAgent } from "@ag-ui/client";
import { NextRequest } from "next/server";

const AGENT_URL =
  process.env.AGENT_RUNTIME_URL ||
  process.env.NEXT_PUBLIC_AGUI_URL ||
  "http://localhost:8000/api/agui";
const COPILOT_AGENT = process.env.COPILOTKIT_AGENT_NAME || "sagent_copilot";

// Fetch identity token for Cloud Run service-to-service auth
async function getIdToken(): Promise<string | null> {
  // Only fetch token in production (Cloud Run)
  if (process.env.NODE_ENV !== "production") {
    return null;
  }

  try {
    // Extract the backend URL (without path) for the audience
    const backendUrl = AGENT_URL.replace(/\/api\/agui$/, "");
    const metadataUrl = `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience=${backendUrl}`;

    const response = await fetch(metadataUrl, {
      headers: { "Metadata-Flavor": "Google" },
    });

    if (response.ok) {
      return await response.text();
    }
  } catch (error) {
    console.error("Failed to fetch identity token:", error);
  }

  return null;
}

const serviceAdapter = new ExperimentalEmptyAdapter();

export async function POST(req: NextRequest) {
  // Get identity token for authenticated backend calls
  const idToken = await getIdToken();

  // Configure HttpAgent with auth headers if token available
  const agentConfig: { url: string; headers?: Record<string, string> } = {
    url: AGENT_URL,
  };

  if (idToken) {
    agentConfig.headers = {
      Authorization: `Bearer ${idToken}`,
    };
  }

  const runtime = new CopilotRuntime({
    agents: {
      [COPILOT_AGENT]: new HttpAgent(agentConfig),
    },
  });

  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  return handleRequest(req);
}
