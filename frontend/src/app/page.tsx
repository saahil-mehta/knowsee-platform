"use client"

import * as React from "react"
import { useCopilotChat } from "@copilotkit/react-core"
import { TextMessage, MessageRole } from "@copilotkit/runtime-client-gql"

import { AppShell } from "@/components/app-shell"
import { AppSidebar } from "@/components/app-sidebar"
import { ChatContainer } from "@/components/chat-container"
import {
  MessageBubble,
  MessageAvatar,
  MessageContent,
  MessageActions,
  LoadingIndicator,
} from "@/components/message"
import { Composer } from "@/components/composer"
import { SidebarProvider } from "@/components/ui/sidebar"

export default function KnowseeChatPage() {
  const [inputValue, setInputValue] = React.useState("")

  const {
    visibleMessages,
    appendMessage,
    stopGeneration,
    reloadMessages,
    isLoading,
  } = useCopilotChat()

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading) return

    try {
      await appendMessage(
        new TextMessage({
          role: MessageRole.User,
          content: inputValue,
        })
      )
      setInputValue("")
    } catch (error) {
      console.error("Failed to send message:", error)
    }
  }

  const handleRegenerate = async (messageId: string) => {
    try {
      await reloadMessages(messageId)
    } catch (error) {
      console.error("Failed to regenerate:", error)
    }
  }

  return (
    <SidebarProvider>
      <div className="flex h-screen w-full overflow-hidden">
        <AppSidebar />
        <AppShell>
          <div className="flex flex-col h-full">
            {/* Chat Container */}
            <ChatContainer.Root className="flex-1">
              <ChatContainer.Content>
                {visibleMessages.length === 0 ? (
                  <div className="flex flex-col items-center justify-center h-full space-y-4 text-center px-4">
                    <div className="h-16 w-16 rounded-2xl bg-primary/10 flex items-center justify-center">
                      <span className="text-4xl">👋</span>
                    </div>
                    <div className="space-y-2">
                      <h2 className="text-2xl font-semibold">Welcome to Knowsee</h2>
                      <p className="text-muted-foreground max-w-md">
                        Your intelligent RAG assistant powered by Google ADK. Ask me anything about your knowledge base!
                      </p>
                    </div>
                  </div>
                ) : (
                  <>
                    {visibleMessages.map((message) => {
                      const role = (message as any).role as "user" | "assistant"
                      const content = (message as any).content as string

                      return (
                        <MessageBubble
                          key={message.id}
                          role={role}
                        >
                          <MessageAvatar role={role} />
                          <div className="flex-1 space-y-2">
                            <MessageContent markdown={true}>
                              {content}
                            </MessageContent>
                            <MessageActions
                              content={content}
                              onRegenerate={
                                role === "assistant"
                                  ? () => handleRegenerate(message.id)
                                  : undefined
                              }
                            />
                          </div>
                        </MessageBubble>
                      )
                    })}

                    {isLoading && (
                      <MessageBubble role="assistant">
                        <MessageAvatar role="assistant" />
                        <div className="flex-1">
                          <LoadingIndicator />
                        </div>
                      </MessageBubble>
                    )}
                    <ChatContainer.ScrollAnchor />
                  </>
                )}
              </ChatContainer.Content>
            </ChatContainer.Root>

            {/* Composer */}
            <Composer
              value={inputValue}
              onChange={setInputValue}
              onSubmit={handleSendMessage}
              onStop={stopGeneration}
              isLoading={isLoading}
              placeholder="Ask me anything about your knowledge base..."
            />
          </div>
        </AppShell>
      </div>
    </SidebarProvider>
  )
}
