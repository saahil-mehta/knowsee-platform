"use client";

import { useState } from "react";
import { useCopilotChat } from "@copilotkit/react-core";
import { TextMessage, MessageRole } from "@copilotkit/runtime-client-gql";

const SUGGESTIONS = [
  "What are the advantages of using Next.js?",
  "Write code to demonstrate Dijkstra's algorithm",
  "Help me write an essay about Silicon Valley",
  "What is the weather in San Francisco?",
];

export default function Page() {
  const [inputValue, setInputValue] = useState("");

  const {
    visibleMessages,
    appendMessage,
    stopGeneration,
    isLoading,
  } = useCopilotChat();

  const handleSendMessage = async (content?: string) => {
    const messageContent = content || inputValue.trim();
    if (!messageContent || isLoading) return;

    try {
      await appendMessage(
        new TextMessage({
          role: MessageRole.User,
          content: messageContent,
        })
      );
      setInputValue("");
    } catch (error) {
      console.error("Failed to send message:", error);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const hasMessages = visibleMessages.length > 0;

  return (
    <main className="flex h-screen w-full overflow-hidden bg-gradient-to-br from-black via-slate-900 to-blue-950 animate-gradient">
      <div className="flex h-full w-full flex-col">
        {/* Messages Container */}
        <div className="flex-1 w-full overflow-y-auto">
          <div className="h-full flex flex-col">
            {!hasMessages ? (
              /* Welcome Screen - Centered */
              <div className="flex-1 flex items-center justify-center px-6 animate-fade-in">
                <div className="w-full max-w-2xl mx-auto text-center space-y-10">
                  <div className="space-y-4">
                    <h1 className="text-5xl font-semibold text-white tracking-tight">
                      Hello there!
                    </h1>
                    <p className="text-xl text-slate-400 font-light">
                      How can I help you today?
                    </p>
                  </div>

                  {/* Suggestion Pills */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {SUGGESTIONS.map((suggestion, index) => (
                      <button
                        key={index}
                        onClick={() => handleSendMessage(suggestion)}
                        disabled={isLoading}
                        style={{ animationDelay: `${index * 75}ms` }}
                        className="animate-slide-up group relative rounded-2xl border border-slate-700/50 bg-slate-800/20 hover:bg-slate-800/40 backdrop-blur-sm p-4 text-left transition-all duration-200 hover:border-slate-600/80 hover:shadow-lg hover:shadow-blue-500/5 hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
                      >
                        <span className="text-[15px] leading-relaxed text-slate-300 group-hover:text-white transition-colors duration-200">
                          {suggestion}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              /* Messages List */
              <div className="flex-1 px-6 py-8">
                <div className="mx-auto max-w-3xl space-y-4">
                  {visibleMessages
                    .filter((message): message is TextMessage =>
                      message instanceof TextMessage && message.role !== MessageRole.System
                    )
                    .map((message, index) => {
                      const isUser = message.role === MessageRole.User;
                      return (
                        <div
                          key={message.id}
                          style={{ animationDelay: `${index * 50}ms` }}
                          className={`flex animate-scale-in ${isUser ? "justify-end" : "justify-start"}`}
                        >
                          <div
                            className={`max-w-[85%] rounded-2xl px-5 py-3.5 shadow-lg transition-all duration-200 ${
                              isUser
                                ? "bg-blue-600 hover:bg-blue-700 text-white shadow-blue-600/20"
                                : "bg-slate-800/80 hover:bg-slate-800/90 text-slate-100 border border-slate-700/50 shadow-black/20"
                            }`}
                          >
                            <div className="whitespace-pre-wrap break-words text-[15px] leading-relaxed">
                              {message.content}
                            </div>
                          </div>
                        </div>
                      );
                    })}

                  {isLoading && (
                    <div className="flex justify-start animate-fade-in">
                      <div className="max-w-[85%] rounded-2xl px-5 py-3.5 bg-slate-800/80 border border-slate-700/50 shadow-lg shadow-black/20">
                        <div className="flex items-center space-x-2">
                          <div className="flex space-x-1.5">
                            <div className="h-2 w-2 rounded-full bg-slate-400 animate-bounce" style={{ animationDelay: "0ms" }}></div>
                            <div className="h-2 w-2 rounded-full bg-slate-400 animate-bounce" style={{ animationDelay: "150ms" }}></div>
                            <div className="h-2 w-2 rounded-full bg-slate-400 animate-bounce" style={{ animationDelay: "300ms" }}></div>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Input Container - Fixed at Bottom */}
        <div className="w-full border-t border-slate-700/50 bg-slate-900/90 backdrop-blur-xl shadow-2xl">
          <div className="mx-auto max-w-3xl px-6 py-5">
            <div className="relative group">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Send a message..."
                disabled={isLoading}
                className="w-full rounded-3xl border border-slate-700/50 bg-slate-800/50 pl-6 pr-14 py-4 text-[15px] text-white placeholder-slate-500 outline-none transition-all duration-200 focus:border-slate-600 focus:bg-slate-800/80 focus:shadow-lg focus:shadow-blue-500/10 disabled:opacity-50 disabled:cursor-not-allowed hover:border-slate-600/80"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                {isLoading ? (
                  <button
                    onClick={stopGeneration}
                    className="rounded-full p-2 hover:bg-slate-700/60 transition-all duration-150 active:scale-95"
                    title="Stop generation"
                  >
                    <svg className="w-5 h-5 text-slate-400" fill="currentColor" viewBox="0 0 24 24">
                      <rect x="6" y="6" width="12" height="12" rx="2" />
                    </svg>
                  </button>
                ) : (
                  <button
                    onClick={() => handleSendMessage()}
                    disabled={!inputValue.trim()}
                    className="rounded-full p-2 transition-all duration-150 hover:bg-blue-600/20 disabled:opacity-30 disabled:hover:bg-transparent active:scale-95 group/send"
                    title="Send message"
                  >
                    <svg className="w-5 h-5 text-slate-400 group-hover/send:text-blue-400 transition-colors duration-150" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
                    </svg>
                  </button>
                )}
              </div>
            </div>
            <p className="mt-4 text-center text-xs text-slate-600 font-medium tracking-wide">
              Powered by Google ADK • AG-UI Protocol • CopilotKit
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}
