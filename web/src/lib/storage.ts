/**
 * LocalStorage wrapper for conversation persistence
 */

import type { Conversation } from '@/types/chat'

const STORAGE_KEY = 'knowsee-conversations'

export const storage = {
  /**
   * Get all conversations
   */
  getConversations(): Conversation[] {
    if (typeof window === 'undefined') return []

    try {
      const data = localStorage.getItem(STORAGE_KEY)
      return data ? JSON.parse(data) : []
    } catch (error) {
      console.error('Failed to load conversations:', error)
      return []
    }
  },

  /**
   * Save conversations
   */
  saveConversations(conversations: Conversation[]): void {
    if (typeof window === 'undefined') return

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(conversations))
    } catch (error) {
      console.error('Failed to save conversations:', error)
    }
  },

  /**
   * Get a single conversation by ID
   */
  getConversation(id: string): Conversation | undefined {
    return this.getConversations().find((conv) => conv.id === id)
  },

  /**
   * Save or update a conversation
   */
  saveConversation(conversation: Conversation): void {
    const conversations = this.getConversations()
    const index = conversations.findIndex((conv) => conv.id === conversation.id)

    if (index >= 0) {
      conversations[index] = conversation
    } else {
      conversations.push(conversation)
    }

    this.saveConversations(conversations)
  },

  /**
   * Delete a conversation
   */
  deleteConversation(id: string): void {
    const conversations = this.getConversations().filter((conv) => conv.id !== id)
    this.saveConversations(conversations)
  },

  /**
   * Clear all conversations
   */
  clearAll(): void {
    if (typeof window === 'undefined') return
    localStorage.removeItem(STORAGE_KEY)
  },
}
