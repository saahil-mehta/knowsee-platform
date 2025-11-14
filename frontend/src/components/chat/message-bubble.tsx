"use client";

import { MessageRole, TextMessage } from "@copilotkit/runtime-client-gql";

type MessageBubbleProps = {
  message: TextMessage;
};

export function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === MessageRole.User;
  const label = isUser ? "You" : "Knowsee";

  return (
    <div
      className={`flex animate-scale-in ${
        isUser ? "justify-end" : "justify-start"
      }`}
    >
      <div
        className={`relative max-w-[85%] rounded-3xl px-5 py-4 text-sm leading-relaxed shadow-[0_14px_40px_rgba(0,0,0,0.45)] ${
          isUser
            ? "bg-white text-slate-900"
            : "border border-white/5 bg-[#07090f] text-slate-100"
        }`}
      >
        <div
          className={`mb-2 text-[11px] uppercase tracking-[0.4em] ${
            isUser ? "text-slate-500" : "text-slate-400"
          }`}
        >
          {label}
        </div>
        <div className="whitespace-pre-wrap break-words text-[15px] leading-relaxed">
          {message.content}
        </div>
      </div>
    </div>
  );
}
