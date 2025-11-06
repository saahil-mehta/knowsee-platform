'use client'

import { useCallback } from 'react'
import { useShallow } from 'zustand/react/shallow'
import { streamChatCompletion } from '@/lib/api'
import type { Message } from '@/types/chat'
import { useChatStore } from '@/state/chat-store'

const snippetFrom = (content: string) => {
  const trimmed = content.trim()
  return trimmed.length > 60 ? `${trimmed.slice(0, 57)}...` : trimmed || 'New chat'
}

const EMPTY_MESSAGES: Message[] = []

type SendOptions = {
  model?: string
}

export function useChat() {
  const {
    conversation,
    conversationId,
    isStreaming,
    error,
    createConversation,
    addMessages,
    updateMessage,
    removeMessage,
    renameConversation,
    setStreaming,
    setError,
  } = useChatStore(
    useShallow((state) => {
      const activeConversation = state.conversations.find(
        (item) => item.id === state.activeConversationId
      )
      return {
        conversation: activeConversation,
        conversationId: state.activeConversationId,
        isStreaming: state.isStreaming,
        error: state.error,
        createConversation: state.createConversation,
        addMessages: state.addMessages,
        updateMessage: state.updateMessage,
        removeMessage: state.removeMessage,
        renameConversation: state.renameConversation,
        setStreaming: state.setStreaming,
        setError: state.setError,
      }
    })
  )

  const messages = conversation?.messages ?? EMPTY_MESSAGES

  const sendMessage = useCallback(
    async (content: string, options?: SendOptions) => {
      const trimmed = content.trim()
      if (!trimmed || isStreaming) {
        return
      }

      let activeId = conversationId
      if (!activeId) {
        activeId = createConversation({ title: snippetFrom(trimmed) })
      }

      const now = Date.now()
      const userMessage: Message = {
        id: `msg-${now}-user`,
        role: 'user',
        content: trimmed,
        timestamp: now,
      }

      const assistantMessage: Message = {
        id: `msg-${now}-assistant`,
        role: 'assistant',
        content: '',
        timestamp: now,
      }

      addMessages(activeId, [userMessage, assistantMessage])
      if (!conversationId) {
        renameConversation(activeId, snippetFrom(trimmed))
      }

      setStreaming(true)
      setError(null)

      const request = {
        model: options?.model,
        messages: [...messages, userMessage].map((message) => ({
          role: message.role,
          content: message.content,
        })),
        stream: true,
        temperature: 0.7,
        max_tokens: 2048,
      }

      try {
        let fullContent = ''
        for await (const chunk of streamChatCompletion(request)) {
          fullContent += chunk
          const contentSnapshot = fullContent
          updateMessage(activeId, assistantMessage.id, (message) => ({
            ...message,
            content: contentSnapshot,
            timestamp: Date.now(),
          }))
        }
      } catch (cause) {
        console.error('Chat error:', cause)
        setError(cause instanceof Error ? cause.message : 'Failed to send message')
        removeMessage(activeId, assistantMessage.id)
      } finally {
        setStreaming(false)
      }
    },
    [
      conversationId,
      createConversation,
      addMessages,
      updateMessage,
      removeMessage,
      renameConversation,
      setStreaming,
      setError,
      isStreaming,
      messages,
    ]
  )

  return {
    conversationId,
    messages,
    isStreaming,
    error,
    sendMessage,
  }
}
