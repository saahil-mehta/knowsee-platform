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

  return (
    <div className="flex h-full flex-col" data-testid="message-list">
      {messages.length === 0 ? (
        <div
          className="flex flex-1 items-center justify-center px-6 text-center text-sm text-gray-500 dark:text-gray-400"
          data-testid="message-empty-state"
        >
          Start a conversation to see messages here.
        </div>
      ) : (
        <div className="flex-1 space-y-4 overflow-y-auto px-4 py-6">
          {messages.map((message) => (
            <Message key={message.id} message={message} />
          ))}

          {isStreaming && (
            <div className="flex justify-start">
              <div className="flex items-center gap-2 rounded-2xl bg-gray-100 px-4 py-3 dark:bg-gray-800">
                <div className="flex gap-1">
                  <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500 [animation-delay:-0.3s]" />
                  <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500 [animation-delay:-0.15s]" />
                  <div className="h-2 w-2 animate-bounce rounded-full bg-gray-500" />
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      <div ref={bottomRef} />
    </div>
  )
}
