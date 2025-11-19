"use client";

import { useEffect, useRef } from "react";
import { MessageRole, TextMessage } from "@copilotkit/runtime-client-gql";
import { MessageBubble } from "./message-bubble";
import { TypingIndicator } from "./typing-indicator";

type MessageListProps = {
  messages: TextMessage[];
  isLoading: boolean;
};

export function MessageList({ messages, isLoading }: MessageListProps) {
  const endRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isLoading]);

  const lastMessage = messages[messages.length - 1];
  const isLastMessageAssistant = lastMessage?.role === MessageRole.Assistant;
  const isLastMessageEmpty = !lastMessage?.content?.trim();

  const shouldShowTypingIndicator =
    isLoading && (!isLastMessageAssistant || isLastMessageEmpty);

  return (
    <div className="relative h-full overflow-y-auto px-4 py-8 sm:px-8 scroll-smooth">
      <div className="mx-auto flex w-full max-w-5xl flex-col gap-6 pb-8">
        {messages.map((message) => (
          <MessageBubble key={message.id} message={message} />
        ))}

        {shouldShowTypingIndicator && <TypingIndicator />}
        <div ref={endRef} />
      </div>
    </div>
  );
}
