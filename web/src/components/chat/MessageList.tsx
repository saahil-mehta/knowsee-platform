'use client'

import { useEffect, useRef } from 'react'
import Message from './Message'
import type { Message as MessageType } from '@/types/chat'

interface MessageListProps {
  messages: MessageType[]
  isStreaming: boolean
}

export default function MessageList({ messages, isStreaming }: MessageListProps) {
  const bottomRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isStreaming])

  if (messages.length === 0) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="text-center">
          <div className="mb-4 text-6xl">💬</div>
          <h2 className="mb-2 text-2xl font-semibold text-gray-900 dark:text-gray-100">
            Start a Conversation
          </h2>
          <p className="text-gray-600 dark:text-gray-400">
            Ask me anything! I'm powered by GPT-OSS-120B.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 space-y-4 overflow-y-auto px-4 py-6">
      {messages.map((message) => (
        <Message key={message.id} message={message} />
      ))}

      {isStreaming && (
        <div className="flex justify-start">
          <div className="flex items-center gap-2 rounded-2xl bg-gray-100 px-4 py-3 dark:bg-gray-800">
            <div className="flex gap-1">
              <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500 [animation-delay:-0.3s]"></div>
              <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500 [animation-delay:-0.15s]"></div>
              <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500"></div>
            </div>
          </div>
        </div>
      )}

      <div ref={bottomRef} />
    </div>
  )
}
