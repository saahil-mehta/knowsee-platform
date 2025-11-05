'use client'

import { useChat } from '@/hooks/useChat'
import { useConversations } from '@/hooks/useConversations'
import MessageList from './MessageList'
import ChatInput from './ChatInput'
import ConversationSidebar from './ConversationSidebar'

export default function ChatInterface() {
  const { createConversation } = useConversations()
  const { messages, isStreaming, error, sendMessage } = useChat()

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-950">
      <ConversationSidebar />

      <section className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-gray-200 bg-white px-6 py-4 dark:border-gray-800 dark:bg-gray-900">
          <div>
            <h1 className="text-lg font-semibold text-gray-900 dark:text-gray-100">Knowsee</h1>
            <p className="text-sm text-gray-600 dark:text-gray-400">LLM chat workspace</p>
          </div>

          <button
            onClick={() => createConversation()}
            className="rounded-md bg-primary-500 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-600"
          >
            New chat
          </button>
        </header>

        {error && (
          <div className="border-b border-red-200 bg-red-50 px-6 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-200">
            {error}
          </div>
        )}

        <div className="flex-1 overflow-hidden">
          <div className="mx-auto h-full w-full max-w-3xl">
            <MessageList messages={messages} isStreaming={isStreaming} />
          </div>
        </div>

        <ChatInput onSend={sendMessage} disabled={isStreaming} />
      </section>
    </div>
  )
}
