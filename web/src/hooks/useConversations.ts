'use client'

import { useState, useEffect, useCallback } from 'react'
import { storage } from '@/lib/storage'
import type { Conversation } from '@/types/chat'

export function useConversations() {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [currentId, setCurrentId] = useState<string | null>(null)

  // Load conversations on mount
  useEffect(() => {
    const loaded = storage.getConversations()
    setConversations(loaded)
  }, [])

  // Create new conversation
  const createConversation = useCallback(() => {
    const newConversation: Conversation = {
      id: `conv-${Date.now()}`,
      title: 'New Chat',
      messages: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
    }

    storage.saveConversation(newConversation)
    setConversations((prev) => [newConversation, ...prev])
    setCurrentId(newConversation.id)

    return newConversation.id
  }, [])

  // Load conversation
  const loadConversation = useCallback((id: string) => {
    setCurrentId(id)
  }, [])

  // Delete conversation
  const deleteConversation = useCallback((id: string) => {
    storage.deleteConversation(id)
    setConversations((prev) => prev.filter((conv) => conv.id !== id))

    if (currentId === id) {
      setCurrentId(null)
    }
  }, [currentId])

  // Update conversation title
  const updateTitle = useCallback((id: string, title: string) => {
    const conversation = storage.getConversation(id)
    if (conversation) {
      conversation.title = title
      conversation.updatedAt = Date.now()
      storage.saveConversation(conversation)
      setConversations((prev) =>
        prev.map((conv) => (conv.id === id ? { ...conv, title } : conv))
      )
    }
  }, [])

  // Get current conversation
  const currentConversation = conversations.find((conv) => conv.id === currentId)

  return {
    conversations,
    currentId,
    currentConversation,
    createConversation,
    loadConversation,
    deleteConversation,
    updateTitle,
  }
}
