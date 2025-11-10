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

const serviceAdapter = new ExperimentalEmptyAdapter();

const runtime = new CopilotRuntime({
  agents: {
    [COPILOT_AGENT]: new HttpAgent({ url: AGENT_URL }),
  },
});

export async function POST(req: NextRequest) {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  return handleRequest(req);
}
