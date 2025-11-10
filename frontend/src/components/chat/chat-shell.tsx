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
    <div className="flex h-full flex-col p-4 md:p-8">
      <div className="mx-auto flex h-full w-full max-w-5xl flex-col gap-6">
        {!hasMessages && (
          <div className="space-y-4">
            <div className="space-y-2">
              <h1 className="font-semibold text-2xl">Conversation Studio</h1>
              <p className="text-muted-foreground text-sm">
                Plan, research, and ship faster with CopilotKit and AG-UI.
              </p>
            </div>
            <QuickActions
              actions={quickActions}
              onSelect={onQuickAction}
              isLoading={isLoading}
            />
          </div>
        )}

        <div className="flex flex-1 flex-col overflow-hidden rounded-lg border bg-card">
          <div className="flex-1 overflow-auto p-4">
            {hasMessages ? (
              <MessageList messages={messages} isLoading={isLoading} />
            ) : (
              <EmptyState actions={quickActions} onSelect={onQuickAction} isLoading={isLoading} />
            )}
          </div>

          <div className="border-t p-4">
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
