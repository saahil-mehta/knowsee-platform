'use client'

import { useCallback, useState } from 'react'
import { useChat } from '@/hooks/useChat'
import { useConversations } from '@/hooks/useConversations'
import MessageList from './MessageList'
import ChatInput from './ChatInput'
import ConversationSidebar from './ConversationSidebar'
import { ThemeToggle } from '@/components/theme/ThemeToggle'
import { SparklesIcon } from '@/components/icons'
import ModelSelector from './ModelSelector'

const quickPrompts = [
  'What are the advantages of using Next.js?',
  "Write code to demonstrate Dijkstra's algorithm",
  'Help me write an essay about Silicon Valley',
  'What is the weather in San Francisco?',
  'Draft a launch email for Knowsee platform',
  'Summarize my latest product analytics report',
]

export default function ChatInterface() {
  const { createConversation } = useConversations()
  const { messages, isStreaming, error, sendMessage } = useChat()
  const [model, setModel] = useState('knowsee-vertex-pro')

  const handleSend = useCallback(
    async (content: string) => {
      await sendMessage(content, { model })
    },
    [model, sendMessage]
  )

  const handlePrompt = useCallback(
    (prompt: string) => {
      void handleSend(prompt)
    },
    [handleSend]
  )

  return (
    <div className="relative flex min-h-screen overflow-hidden bg-gradient-to-br from-background via-background to-background">
      <ConversationSidebar />

      <section className="relative flex flex-1 flex-col">
        <div className="pointer-events-none absolute inset-0 -z-10 overflow-hidden">
          <div className="absolute left-[30%] top-[-10%] h-72 w-72 rounded-full bg-primary-500/20 blur-3xl" />
          <div className="absolute right-[-10%] top-[25%] h-80 w-80 rounded-full bg-sky-400/10 blur-3xl" />
          <div className="absolute bottom-[-20%] left-[15%] h-72 w-72 rounded-full bg-purple-500/10 blur-3xl" />
        </div>

        <header className="flex flex-col gap-4 border-b border-zinc-200/70 bg-white/60 px-6 py-5 backdrop-blur-xl supports-[backdrop-filter]:bg-white/40 dark:border-zinc-800/70 dark:bg-zinc-950/40">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-start gap-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 via-indigo-500 to-sky-500 text-white shadow-soft-lg">
                <SparklesIcon className="h-5 w-5" />
              </div>
              <div className="space-y-1">
                <p className="text-xs font-semibold uppercase tracking-[0.25em] text-primary-500 dark:text-primary-200">
                  Knowsee chatbot
                </p>
                <p className="text-xl font-semibold text-zinc-900 dark:text-zinc-100">Conversational workspace</p>
                <p className="text-sm text-zinc-500 dark:text-zinc-400">
                  Streaming responses, resumable history, and artifact previews out of the box.
                </p>
              </div>
            </div>

            <div className="flex flex-col items-stretch gap-3 sm:flex-row sm:items-center">
              <ModelSelector value={model} onChange={setModel} />
              <button
                onClick={() => createConversation()}
                className="inline-flex items-center justify-center gap-2 rounded-full border border-zinc-300/70 bg-white px-4 py-2 text-sm font-medium text-zinc-700 shadow-sm transition hover:-translate-y-0.5 hover:border-zinc-300 hover:text-zinc-900 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200 dark:hover:border-zinc-600"
              >
                Start new chat
              </button>
              <ThemeToggle />
              <a
                href="https://vercel.com/new"
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center rounded-full bg-zinc-900 px-5 py-2 text-sm font-semibold text-white shadow-soft-lg transition hover:-translate-y-0.5 hover:bg-zinc-800 dark:bg-white dark:text-zinc-900"
              >
                Deploy with Vercel
              </a>
            </div>
          </div>
        </header>

        {error && (
          <div className="border-b border-red-300/60 bg-red-100/70 px-6 py-3 text-sm text-red-700 dark:border-red-900/60 dark:bg-red-950/40 dark:text-red-200">
            {error}
          </div>
        )}

        <div className="flex-1 overflow-hidden px-4 pb-4 pt-6 sm:px-10 sm:pb-10">
          <div className="mx-auto flex h-full w-full max-w-3xl flex-col">
            <MessageList
              messages={messages}
              isStreaming={isStreaming}
              quickPrompts={quickPrompts}
              onPromptSelect={handlePrompt}
            />
          </div>
        </div>

        <ChatInput
          onSend={handleSend}
          disabled={isStreaming}
          status={isStreaming ? `Generating with ${model}…` : 'Press Enter to send, Shift+Enter for new line'}
        />
      </section>
    </div>
  )
}
