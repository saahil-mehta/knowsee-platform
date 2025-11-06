'use client'

import { useMemo } from 'react'
import { useConversations } from '@/hooks/useConversations'
import { BotIcon, PlusIcon, SparklesIcon, TrashIcon } from '@/components/icons'
import { ThemeToggle } from '@/components/theme/ThemeToggle'

export default function ConversationSidebar() {
  const {
    conversations,
    currentId,
    selectConversation,
    createConversation,
    deleteConversation,
  } = useConversations()

  const sortedConversations = useMemo(
    () => conversations.slice().sort((a, b) => b.updatedAt - a.updatedAt),
    [conversations]
  )

  return (
    <aside className="relative hidden h-screen w-80 flex-shrink-0 flex-col border-r border-zinc-200/60 bg-white/70 px-6 py-6 text-zinc-600 shadow-soft-lg backdrop-blur-xl supports-[backdrop-filter]:bg-white/50 dark:border-zinc-800/60 dark:bg-zinc-950/40 dark:text-zinc-300 md:flex">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 via-purple-500 to-sky-500 text-base font-semibold text-white shadow-soft-lg">
            KS
          </span>
          <div>
            <p className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Knowsee</p>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">Agent workspace</p>
          </div>
        </div>
        <button
          onClick={() => createConversation()}
          className="flex h-10 w-10 items-center justify-center rounded-xl border border-zinc-200/70 bg-white text-zinc-600 transition hover:-translate-y-0.5 hover:border-zinc-300 hover:text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300"
          aria-label="Create conversation"
        >
          <PlusIcon className="h-4 w-4" />
        </button>
      </div>

      <div className="mt-6 rounded-3xl border border-zinc-200/70 bg-card p-4 shadow-soft-lg dark:border-zinc-800/70">
        <div className="flex items-start gap-3">
          <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary-500/10 text-primary-600 dark:bg-primary-500/20 dark:text-primary-200">
            <SparklesIcon className="h-5 w-5" />
          </span>
          <div className="space-y-1">
            <p className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Deploy to production</p>
            <p className="text-xs leading-5 text-zinc-500 dark:text-zinc-400">
              Connect your Vertex-powered agent, stream tokens instantly, and hand-off artifacts to your team.
            </p>
          </div>
        </div>
        <a
          href="https://vercel.com/new"
          target="_blank"
          rel="noreferrer"
          className="mt-4 inline-flex items-center justify-center rounded-full bg-zinc-900 px-4 py-2 text-xs font-semibold text-white shadow-soft-lg transition hover:-translate-y-0.5 hover:bg-zinc-800 dark:bg-white dark:text-zinc-900"
        >
          Deploy with Vercel
        </a>
      </div>

      <div className="mt-8 space-y-3">
        <div className="flex items-center justify-between text-[11px] font-semibold uppercase tracking-[0.3em] text-zinc-500 dark:text-zinc-500">
          <span>History</span>
          <span className="rounded-full bg-zinc-200/70 px-2 py-0.5 text-[10px] font-medium text-zinc-600 dark:bg-zinc-800/60 dark:text-zinc-300">
            {sortedConversations.length}
          </span>
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto pr-1 scrollbar-hide">
          {sortedConversations.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-zinc-300/70 bg-white/60 p-6 text-center text-xs text-zinc-500 dark:border-zinc-700/70 dark:bg-zinc-900/40 dark:text-zinc-400">
              You have not created any chats yet. Start one to build your local history.
            </div>
          ) : (
            sortedConversations.map((conversation) => {
              const isActive = conversation.id === currentId
              return (
                <button
                  key={conversation.id}
                  onClick={() => selectConversation(conversation.id)}
                  className={`group flex w-full items-center gap-3 rounded-2xl border px-3 py-3 text-left transition-all ${
                    isActive
                      ? 'border-primary-500/70 bg-primary-500/10 text-primary-700 shadow-sm dark:border-primary-500/40 dark:bg-primary-500/20 dark:text-primary-100'
                      : 'border-transparent bg-white/60 text-zinc-600 hover:-translate-y-0.5 hover:border-zinc-200 hover:bg-white dark:bg-zinc-900/40 dark:text-zinc-300 dark:hover:border-zinc-700'
                  }`}
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
                    <BotIcon className="h-5 w-5" />
                  </span>
                  <span className="flex-1">
                    <p className="truncate text-sm font-medium text-zinc-900 dark:text-zinc-100">
                      {conversation.title || 'Untitled conversation'}
                    </p>
                    <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
                      {new Date(conversation.updatedAt).toLocaleString()}
                    </p>
                  </span>
                  <button
                    type="button"
                    className="ml-auto flex h-8 w-8 items-center justify-center rounded-xl border border-transparent text-zinc-400 opacity-0 transition group-hover:opacity-100 hover:border-red-300 hover:text-red-500 dark:text-zinc-500 dark:hover:border-red-500/30 dark:hover:text-red-300"
                    onClick={(event) => {
                      event.stopPropagation()
                      deleteConversation(conversation.id)
                    }}
                    aria-label="Delete conversation"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </button>
              )
            })
          )}
        </nav>
      </div>

      <div className="mt-auto space-y-4 pt-6">
        <ThemeToggle showLabel className="w-full justify-center" />
        <div className="rounded-3xl border border-dashed border-zinc-300/70 bg-white/40 p-4 text-xs leading-relaxed text-zinc-500 dark:border-zinc-700/70 dark:bg-zinc-900/40 dark:text-zinc-400">
          <p className="text-sm font-semibold text-zinc-700 dark:text-zinc-200">Guest session</p>
          <p>Your conversations stay on this device. Use the Deploy action to sync your agent.</p>
        </div>
      </div>
    </aside>
  )
}
