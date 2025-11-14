"use client";

import { useCallback, useMemo, useState } from "react";
import { useCopilotChat } from "@copilotkit/react-core";
import { MessageRole, TextMessage } from "@copilotkit/runtime-client-gql";
import { ChatShell } from "../components/chat/chat-shell";

const QUICK_ACTIONS = [
  "What are the advantages of using Next.js?",
  "Write code to demonstrate Dijkstra's algorithm",
  "Help me write an essay about Silicon Valley",
  "What is the weather in San Francisco?",
];

export default function Page() {
  const [inputValue, setInputValue] = useState("");
  const { visibleMessages, appendMessage, stopGeneration, isLoading } = useCopilotChat();

  const messages = useMemo(
    () =>
      visibleMessages.filter(
        (message): message is TextMessage =>
          message instanceof TextMessage && message.role !== MessageRole.System
      ),
    [visibleMessages]
  );

  const handleSendMessage = useCallback(
    async (content?: string) => {
      const messageContent = (content ?? inputValue).trim();
      if (!messageContent || isLoading) return;

      try {
        await appendMessage(
          new TextMessage({
            role: MessageRole.User,
            content: messageContent,
          })
        );

        if (!content) {
          setInputValue("");
        }
      } catch (error) {
        console.error("Failed to send message:", error);
      }
    },
    [appendMessage, inputValue, isLoading]
  );

  const handleQuickAction = useCallback(
    (value: string) => {
      void handleSendMessage(value);
    },
    [handleSendMessage]
  );

  const handleReset = useCallback(() => {
    window.location.reload();
  }, []);

  return (
    <ChatShell
      messages={messages}
      isLoading={isLoading}
      inputValue={inputValue}
      onInputChange={setInputValue}
      onSend={() => {
        void handleSendMessage();
      }}
      onStop={stopGeneration}
      quickActions={QUICK_ACTIONS}
      onQuickAction={handleQuickAction}
      onReset={handleReset}
    />
  );
}
