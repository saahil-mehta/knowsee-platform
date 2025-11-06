'use client'

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Conversation, Message } from '@/types/chat'

const makeId = (prefix: string) => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return `${prefix}-${crypto.randomUUID()}`
  }
  const random = Math.random().toString(16).slice(2)
  return `${prefix}-${Date.now()}-${random}`
}

const updateTimestamp = (conversation: Conversation): Conversation => ({
  ...conversation,
  updatedAt: Date.now(),
})

const sortByUpdatedAt = (conversations: Conversation[]) =>
  [...conversations].sort((a, b) => b.updatedAt - a.updatedAt)

type ChatStore = {
  conversations: Conversation[]
  activeConversationId: string | null
  isStreaming: boolean
  error: string | null
  createConversation: (payload?: { title?: string; messages?: Message[] }) => string
  setActiveConversation: (id: string | null) => void
  addMessages: (id: string, messages: Message[]) => void
  updateMessage: (id: string, messageId: string, updater: (msg: Message) => Message) => void
  removeMessage: (id: string, messageId: string) => void
  renameConversation: (id: string, title: string) => void
  deleteConversation: (id: string) => void
  setStreaming: (status: boolean) => void
  setError: (message: string | null) => void
  clearAll: () => void
}

export const useChatStore = create<ChatStore>()(
  persist<ChatStore>(
    (set) => ({
      conversations: [],
      activeConversationId: null,
      isStreaming: false,
      error: null,
      createConversation: (payload) => {
        const now = Date.now()
        const id = makeId('conv')
        const conversation: Conversation = {
          id,
          title: payload?.title ?? 'New chat',
          messages: payload?.messages ?? [],
          createdAt: now,
          updatedAt: now,
        }

        set((state) => ({
          conversations: sortByUpdatedAt([conversation, ...state.conversations]),
          activeConversationId: id,
        }))

        return id
      },
      setActiveConversation: (id) => {
        set({ activeConversationId: id })
      },
      addMessages: (id, messages) => {
        if (!messages.length) return
        set((state) => {
          const conversations = state.conversations.map((conversation) => {
            if (conversation.id !== id) return conversation
            const updatedConversation = updateTimestamp({
              ...conversation,
              messages: [...conversation.messages, ...messages],
            })
            return updatedConversation
          })
          return { conversations: sortByUpdatedAt(conversations) }
        })
      },
      updateMessage: (id, messageId, updater) => {
        set((state) => {
          const conversations = state.conversations.map((conversation) => {
            if (conversation.id !== id) return conversation
            const updatedConversation = updateTimestamp({
              ...conversation,
              messages: conversation.messages.map((message) =>
                message.id === messageId ? updater(message) : message
              ),
            })
            return updatedConversation
          })
          return { conversations: sortByUpdatedAt(conversations) }
        })
      },
      removeMessage: (id, messageId) => {
        set((state) => {
          const conversations = state.conversations.map((conversation) => {
            if (conversation.id !== id) return conversation
            const updatedConversation = updateTimestamp({
              ...conversation,
              messages: conversation.messages.filter((message) => message.id !== messageId),
            })
            return updatedConversation
          })
          return { conversations: sortByUpdatedAt(conversations) }
        })
      },
      renameConversation: (id, title) => {
        set((state) => {
          const conversations = state.conversations.map((conversation) => {
            if (conversation.id !== id) return conversation
            return updateTimestamp({ ...conversation, title })
          })
          return { conversations: sortByUpdatedAt(conversations) }
        })
      },
      deleteConversation: (id) => {
        set((state) => {
          const remaining = state.conversations.filter((conversation) => conversation.id !== id)
          const activeConversationId =
            state.activeConversationId === id ? (remaining[0]?.id ?? null) : state.activeConversationId
          return {
            conversations: remaining,
            activeConversationId,
          }
        })
      },
      setStreaming: (status) => set({ isStreaming: status }),
      setError: (message) => set({ error: message }),
      clearAll: () => set({ conversations: [], activeConversationId: null }),
    }),
    {
      name: 'knowsee-chat-store',
      onRehydrateStorage: () => (state) => {
        if (!state) return
        state.error = null
        state.isStreaming = false
      },
    }
  )
)
