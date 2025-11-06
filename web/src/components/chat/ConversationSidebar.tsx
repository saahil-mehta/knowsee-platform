'use client'

import { useConversations } from '@/hooks/useConversations'

export default function ConversationSidebar() {
  const {
    conversations,
    currentId,
    selectConversation,
    createConversation,
    deleteConversation,
  } = useConversations()

  return (
    <aside className="hidden w-72 flex-shrink-0 border-r border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-950 md:flex md:flex-col">
      <div className="flex items-center justify-between px-4 py-3">
        <h2 className="text-sm font-semibold uppercase tracking-wide text-gray-600 dark:text-gray-300">
          Conversations
        </h2>
        <button
          onClick={() => createConversation()}
          className="rounded-md border border-gray-300 px-2 py-1 text-xs font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-gray-800"
        >
          New
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto px-2 pb-3">
        {conversations.length === 0 ? (
          <div className="rounded-md border border-dashed border-gray-300 p-4 text-xs text-gray-500 dark:border-gray-700 dark:text-gray-400">
            Start a conversation to see it here.
          </div>
        ) : (
          <ul className="space-y-1">
            {conversations.map((conversation) => {
              const isActive = conversation.id === currentId
              return (
                <li key={conversation.id}>
                  <button
                    onClick={() => selectConversation(conversation.id)}
                    className={`w-full rounded-md border px-3 py-2 text-left text-sm transition-colors ${
                      isActive
                        ? 'border-primary-500 bg-primary-50 text-primary-700 dark:border-primary-400 dark:bg-primary-900 dark:text-primary-100'
                        : 'border-transparent bg-gray-50 text-gray-700 hover:border-gray-200 hover:bg-white dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800'
                    }`}
                  >
                    <div className="truncate font-medium">
                      {conversation.title || 'Untitled conversation'}
                    </div>
                    <div className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      {new Date(conversation.updatedAt).toLocaleString()}
                    </div>
                  </button>
                  {isActive && (
                    <div className="mt-1 flex justify-end">
                      <button
                        onClick={() => deleteConversation(conversation.id)}
                        className="text-xs text-red-600 hover:underline dark:text-red-400"
                      >
                        Delete
                      </button>
                    </div>
                  )}
                </li>
              )
            })}
          </ul>
        )}
      </nav>
    </aside>
  )
}
