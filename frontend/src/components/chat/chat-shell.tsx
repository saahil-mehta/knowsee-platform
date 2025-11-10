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
    <div className="flex h-full flex-col">
      <div className="mx-auto flex h-full w-full max-w-3xl flex-col px-4 py-8">
        <div className="flex flex-1 flex-col overflow-auto">
          {hasMessages ? (
            <MessageList messages={messages} isLoading={isLoading} />
          ) : (
            <EmptyState />
          )}
        </div>

        {!hasMessages && (
          <div className="mb-6 mt-auto">
            <QuickActions
              actions={quickActions}
              onSelect={onQuickAction}
              isLoading={isLoading}
            />
          </div>
        )}

        <div className="mt-auto pt-4">
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
  );
}
