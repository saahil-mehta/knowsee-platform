"use client";

import { useEffect, useRef } from "react";
import { TextMessage } from "@copilotkit/runtime-client-gql";
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

  return (
    <div className="mask-fade-bottom relative h-full overflow-y-auto px-4 py-8 sm:px-8">
      <div className="mx-auto flex max-w-3xl flex-col gap-6">
        {messages.map((message) => (
          <MessageBubble key={message.id} message={message} />
        ))}

        {isLoading && <TypingIndicator />}
        <div ref={endRef} />
      </div>
    </div>
  );
}
