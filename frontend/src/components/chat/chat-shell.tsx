"use client";

import type { TextMessage } from "@copilotkit/runtime-client-gql";
import { ChatComposer } from "./chat-composer";
import { EmptyState } from "./empty-state";
import { MessageList } from "./message-list";
import { QuickActions } from "./quick-actions";

type ChatShellProps = {
  messages: TextMessage[];
  isLoading: boolean;
  inputValue: string;
  onInputChange: (value: string) => void;
  onSend: () => void;
  onStop: () => void;
  quickActions: string[];
  onQuickAction: (value: string) => void;
  onReset?: () => void;
};

export function ChatShell({
  messages,
  isLoading,
  inputValue,
  onInputChange,
  onSend,
  onStop,
  quickActions,
  onQuickAction,
}: ChatShellProps) {
  const hasMessages = messages.length > 0;

  return (
    <div className="flex h-full flex-col bg-background">
      <div className="flex h-full w-full flex-col">
        <div className="flex flex-1 flex-col overflow-hidden relative">
          {hasMessages ? (
            <MessageList messages={messages} isLoading={isLoading} />
          ) : (
            <EmptyState />
          )}
        </div>

        {!hasMessages && (
          <div className="mb-6 mt-auto px-4">
            <div className="mx-auto max-w-3xl">
              <QuickActions
                actions={quickActions}
                onSelect={onQuickAction}
                isLoading={isLoading}
              />
            </div>
          </div>
        )}

        <div className="mt-auto p-4 border-t bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="mx-auto max-w-3xl w-full">
            <ChatComposer
              value={inputValue}
              onChange={onInputChange}
              onSend={onSend}
              onStop={onStop}
              isLoading={isLoading}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
