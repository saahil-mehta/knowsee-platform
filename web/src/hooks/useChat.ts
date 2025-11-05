'use client'

import { useState, useCallback, useRef } from 'react'
import { streamChatCompletion } from '@/lib/api'
import { storage } from '@/lib/storage'
import type { Message, Conversation } from '@/types/chat'

export function useChat(conversationId: string | null) {
  const [messages, setMessages] = useState<Message[]>([])
  const [isStreaming, setIsStreaming] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const abortControllerRef = useRef<AbortController | null>(null)

  // Load conversation messages
  const loadConversation = useCallback((id: string) => {
    const conversation = storage.getConversation(id)
    if (conversation) {
      setMessages(conversation.messages)
    }
  }, [])

  // Send a message and stream response
  const sendMessage = useCallback(
    async (content: string) => {
      if (!content.trim() || isStreaming) return

      setError(null)

      // Create user message
      const userMessage: Message = {
        id: `msg-${Date.now()}-user`,
        role: 'user',
        content: content.trim(),
        timestamp: Date.now(),
      }

      // Create assistant message placeholder
      const assistantMessage: Message = {
        id: `msg-${Date.now()}-assistant`,
        role: 'assistant',
        content: '',
        timestamp: Date.now(),
      }

      const newMessages = [...messages, userMessage, assistantMessage]
      setMessages(newMessages)
      setIsStreaming(true)

      try {
        // Prepare request
        const request = {
          messages: [...messages, userMessage].map((msg) => ({
            role: msg.role,
            content: msg.content,
          })),
          stream: true,
          temperature: 0.7,
          max_tokens: 2048,
        }

        // Stream response
        let fullContent = ''
        for await (const chunk of streamChatCompletion(request)) {
          fullContent += chunk

          // Update assistant message
          setMessages((prev) => {
            const updated = [...prev]
            const lastMsg = updated[updated.length - 1]
            if (lastMsg.role === 'assistant') {
              lastMsg.content = fullContent
            }
            return updated
          })
        }

        // Save conversation
        if (conversationId) {
          const conversation = storage.getConversation(conversationId)
          if (conversation) {
            conversation.messages = [...conversation.messages, userMessage, {
              ...assistantMessage,
              content: fullContent,
            }]
            conversation.updatedAt = Date.now()
            storage.saveConversation(conversation)
          }
        } else {
          // Create new conversation
          const newConversation: Conversation = {
            id: `conv-${Date.now()}`,
            title: content.slice(0, 50) + (content.length > 50 ? '...' : ''),
            messages: [userMessage, { ...assistantMessage, content: fullContent }],
            createdAt: Date.now(),
            updatedAt: Date.now(),
          }
          storage.saveConversation(newConversation)
        }
      } catch (err) {
        console.error('Chat error:', err)
        setError(err instanceof Error ? err.message : 'Failed to send message')

        // Remove failed assistant message
        setMessages((prev) => prev.slice(0, -1))
      } finally {
        setIsStreaming(false)
      }
    },
    [messages, conversationId, isStreaming]
  )

  // Stop streaming
  const stopStreaming = useCallback(() => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort()
      abortControllerRef.current = null
    }
    setIsStreaming(false)
  }, [])

  // Clear messages
  const clearMessages = useCallback(() => {
    setMessages([])
  }, [])

  return {
    messages,
    isStreaming,
    error,
    sendMessage,
    stopStreaming,
    clearMessages,
    loadConversation,
  }
}
