'use client'

import { useChat } from '@/hooks/useChat'
import { useConversations } from '@/hooks/useConversations'
import MessageList from './MessageList'
import ChatInput from './ChatInput'

export default function ChatInterface() {
  const { currentId, createConversation } = useConversations()
  const { messages, isStreaming, error, sendMessage, loadConversation } = useChat(currentId)

  const handleSend = async (message: string) => {
    // If no current conversation, create one
    if (!currentId) {
      const newId = createConversation()
      loadConversation(newId)
    }

    await sendMessage(message)
  }

  return (
    <div className="flex h-screen flex-col bg-gray-50 dark:bg-gray-950">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white px-4 py-4 dark:border-gray-800 dark:bg-gray-900">
        <div className="mx-auto flex max-w-4xl items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900 dark:text-gray-100">
              Shadow Knowsee
            </h1>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Powered by GPT-OSS-120B
            </p>
          </div>

          <button
            onClick={() => {
              const newId = createConversation()
              loadConversation(newId)
            }}
            className="rounded-lg bg-primary-500 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-600"
          >
            New Chat
          </button>
        </div>
      </header>

      {/* Error banner */}
      {error && (
        <div className="border-b border-red-200 bg-red-50 px-4 py-3 dark:border-red-900 dark:bg-red-950">
          <div className="mx-auto max-w-4xl">
            <p className="text-sm text-red-800 dark:text-red-200">
              <span className="font-semibold">Error:</span> {error}
            </p>
          </div>
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-hidden">
        <div className="mx-auto h-full max-w-4xl">
          <MessageList messages={messages} isStreaming={isStreaming} />
        </div>
      </div>

      {/* Input */}
      <ChatInput onSend={handleSend} disabled={isStreaming} />
    </div>
  )
}
