import type { Metadata } from "next";
import { CopilotKit } from "@copilotkit/react-core";

import "./globals.css";
import "@copilotkit/react-ui/styles.css";

export const metadata: Metadata = {
  title: "Knowsee Copilot",
  description: "AG-UI powered CopilotKit frontend wired to ADK backend",
};

const AGENT_IDENTIFIER = process.env.NEXT_PUBLIC_COPILOT_AGENT ?? "sagent_copilot";
const RUNTIME_URL = process.env.NEXT_PUBLIC_COPILOT_RUNTIME_URL ?? "/api/copilotkit";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <CopilotKit runtimeUrl={RUNTIME_URL} agent={AGENT_IDENTIFIER}>
          {children}
        </CopilotKit>
      </body>
    </html>
  );
}
