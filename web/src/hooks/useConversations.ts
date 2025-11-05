'use client'

import { useShallow } from 'zustand/react/shallow'
import { useChatStore } from '@/state/chat-store'

export function useConversations() {
  return useChatStore(
    useShallow((state) => ({
      conversations: state.conversations,
      currentId: state.activeConversationId,
      currentConversation: state.conversations.find(
        (conversation) => conversation.id === state.activeConversationId
      ),
      createConversation: state.createConversation,
      selectConversation: state.setActiveConversation,
      deleteConversation: state.deleteConversation,
      renameConversation: state.renameConversation,
    }))
  )
}
