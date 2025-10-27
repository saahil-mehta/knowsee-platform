"use client";

import { CopilotChat } from "@copilotkit/react-ui";

export default function KnowseeChatPage() {
  return (
    <main className="chat-page">
      <div className="chat-shell">
        <header className="chat-header">
          <h1>Knowsee Assistant</h1>
          <p>Chat with the RAG agent powered by the Google Agent Development Kit.</p>
        </header>
        <CopilotChat className="chat-surface" />
      </div>
    </main>
  );
}
