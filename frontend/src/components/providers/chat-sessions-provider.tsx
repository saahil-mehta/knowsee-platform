"use client"

import * as React from "react"

export interface ChatSession {
  id: string
  title: string
  timestamp: Date
  lastMessage?: string
}

interface ChatSessionsContextValue {
  sessions: ChatSession[]
  activeSessionId: string | null
  createSession: () => Promise<string>
  switchSession: (sessionId: string) => void
  deleteSession: (sessionId: string) => void
  updateSessionTitle: (sessionId: string, title: string) => void
}

const ChatSessionsContext = React.createContext<ChatSessionsContextValue | undefined>(
  undefined
)

export function ChatSessionsProvider({ children }: { children: React.ReactNode }) {
  const [sessions, setSessions] = React.useState<ChatSession[]>([])
  const [activeSessionId, setActiveSessionId] = React.useState<string | null>(null)

  const createSession = React.useCallback(async () => {
    const newSession: ChatSession = {
      id: crypto.randomUUID(),
      title: "New Chat",
      timestamp: new Date(),
    }

    setSessions((prev) => [newSession, ...prev])
    setActiveSessionId(newSession.id)

    // TODO: Call ADK API to create a new session
    // const response = await fetch('/api/sessions', { method: 'POST' })
    // const data = await response.json()

    return newSession.id
  }, [])

  const switchSession = React.useCallback((sessionId: string) => {
    setActiveSessionId(sessionId)

    // TODO: Load session messages from ADK
    // const response = await fetch(`/api/sessions/${sessionId}/messages`)
    // const messages = await response.json()
  }, [])

  const deleteSession = React.useCallback((sessionId: string) => {
    setSessions((prev) => prev.filter((s) => s.id !== sessionId))

    if (activeSessionId === sessionId) {
      setActiveSessionId(null)
    }

    // TODO: Call ADK API to delete session
    // await fetch(`/api/sessions/${sessionId}`, { method: 'DELETE' })
  }, [activeSessionId])

  const updateSessionTitle = React.useCallback((sessionId: string, title: string) => {
    setSessions((prev) =>
      prev.map((s) => (s.id === sessionId ? { ...s, title } : s))
    )

    // TODO: Call ADK API to update session title
    // await fetch(`/api/sessions/${sessionId}`, {
    //   method: 'PATCH',
    //   body: JSON.stringify({ title }),
    // })
  }, [])

  const value = React.useMemo(
    () => ({
      sessions,
      activeSessionId,
      createSession,
      switchSession,
      deleteSession,
      updateSessionTitle,
    }),
    [sessions, activeSessionId, createSession, switchSession, deleteSession, updateSessionTitle]
  )

  return (
    <ChatSessionsContext.Provider value={value}>
      {children}
    </ChatSessionsContext.Provider>
  )
}

export function useChatSessions() {
  const context = React.useContext(ChatSessionsContext)

  if (!context) {
    throw new Error("useChatSessions must be used within ChatSessionsProvider")
  }

  return context
}
