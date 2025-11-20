"use client";

import { MessageRole, TextMessage } from "@copilotkit/runtime-client-gql";

type MessageBubbleProps = {
  message: TextMessage;
};

export function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === MessageRole.User;

  // Don't render empty assistant messages (prevents blank bubble while thinking)
  if (!isUser && !message.content?.trim()) {
    return null;
  }

  return (
    <div
      className={`flex w-full animate-fade-up ${isUser ? "justify-end" : "justify-start"
        }`}
    >
      <div
        className={`relative max-w-[85%] md:max-w-[75%] lg:max-w-[65%] rounded-2xl px-5 py-3.5 text-[15px] leading-relaxed shadow-sm ${isUser
          ? "bg-primary text-primary-foreground rounded-br-sm"
          : "bg-muted/50 text-foreground border border-border/50 rounded-bl-sm"
          }`}
      >
        <div className="whitespace-pre-wrap break-words">
          {message.content}
        </div>
      </div>
    </div>
  );
}
