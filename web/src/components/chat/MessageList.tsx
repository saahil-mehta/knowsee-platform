'use client'

import { useEffect, useRef } from 'react'
import Message from './Message'
import type { Message as MessageType } from '@/types/chat'
import { SparklesIcon } from '@/components/icons'

interface MessageListProps {
  messages: MessageType[]
  isStreaming: boolean
  quickPrompts?: string[]
  onPromptSelect?: (prompt: string) => void
}

export default function MessageList({ messages, isStreaming, quickPrompts, onPromptSelect }: MessageListProps) {
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isStreaming])

  if (messages.length === 0) {
    return (
      <div className="mt-10 flex flex-1 flex-col items-center justify-center gap-10 text-center text-sm text-zinc-500 dark:text-zinc-400">
        <div className="mx-auto max-w-2xl space-y-8">
          <div className="space-y-4 text-center">
            <div className="inline-flex items-center gap-2 rounded-full border border-primary-200/60 bg-white/70 px-3 py-1 text-xs font-medium text-primary-600 shadow-sm dark:border-primary-500/40 dark:bg-zinc-900/50 dark:text-primary-200">
              <SparklesIcon className="h-3.5 w-3.5" />
              Knowsee Agent Studio
            </div>
            <div className="space-y-2">
              <h1 className="text-3xl font-semibold text-zinc-900 dark:text-zinc-50 sm:text-4xl">
                Hello there!
              </h1>
              <p className="text-base text-zinc-600 dark:text-zinc-300 sm:text-lg">
                How can I help you today?
              </p>
            </div>
            <p className="text-sm text-zinc-500 dark:text-zinc-400">
              Ask the agent for product deep dives, structured analysis, or connect live data artifacts.
            </p>
          </div>
          {quickPrompts && quickPrompts.length > 0 && (
            <div className="grid gap-3 sm:grid-cols-2">
              {quickPrompts.map((prompt) => (
                <button
                  key={prompt}
                  onClick={() => onPromptSelect?.(prompt)}
                  className="group flex items-center justify-between gap-4 rounded-3xl border border-zinc-200/70 bg-white/70 px-4 py-4 text-left text-sm font-medium text-zinc-700 transition hover:-translate-y-1 hover:border-zinc-300 hover:bg-white hover:text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900/60 dark:text-zinc-200 dark:hover:border-zinc-600"
                >
                  <span className="flex-1 leading-5">{prompt}</span>
                  <span className="inline-flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full border border-zinc-200 bg-white text-zinc-400 transition group-hover:border-primary-500 group-hover:text-primary-500 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-500">
                    ↗
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="mt-6 flex flex-1 flex-col" data-testid="message-list">
      <div className="flex-1 space-y-6 overflow-y-auto px-2 py-4">
        {messages.map((message) => (
          <Message key={message.id} message={message} />
        ))}

        {isStreaming && (
          <div className="flex justify-start">
            <div className="flex items-center gap-2 rounded-3xl border border-zinc-200 bg-white/60 px-4 py-3 text-sm text-zinc-600 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/50 dark:text-zinc-300">
              <span className="flex gap-2">
                <span className="h-2 w-2 animate-bounce rounded-full bg-zinc-400 [animation-delay:-0.3s]" />
                <span className="h-2 w-2 animate-bounce rounded-full bg-zinc-400 [animation-delay:-0.15s]" />
                <span className="h-2 w-2 animate-bounce rounded-full bg-zinc-400" />
              </span>
              Thinking…
            </div>
          </div>
        )}
      </div>

      <div ref={bottomRef} />
    </div>
  )
}
