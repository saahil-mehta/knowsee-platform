"use client"

import * as React from "react"
import { Plus, MessageSquare } from "lucide-react"

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
} from "@/components/ui/sidebar"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import { Separator } from "@/components/ui/separator"

export function AppSidebar() {
  // TODO: Replace with actual chat history from ADK
  const chatHistory: Array<{ id: string; title: string; timestamp: Date }> = []

  const handleNewChat = () => {
    // TODO: Implement new chat functionality
    console.log("New chat clicked")
  }

  return (
    <Sidebar className="border-r border-sidebar-border backdrop-blur-knowsee">
      <SidebarHeader className="border-b border-sidebar-border px-4 py-3 bg-gradient-knowsee">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img
              src="/knowsee-logo.png"
              alt="Knowsee"
              className="h-8 w-auto object-contain"
            />
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 hover-lift"
            onClick={handleNewChat}
          >
            <Plus className="h-4 w-4" />
            <span className="sr-only">New chat</span>
          </Button>
        </div>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Chat History</SidebarGroupLabel>
          <SidebarGroupContent>
            {chatHistory.length === 0 ? (
              <div className="px-4 py-8 text-center text-sm text-muted-foreground">
                No chat history yet.
                <br />
                Start a new conversation!
              </div>
            ) : (
              <SidebarMenu>
                {chatHistory.map((chat) => (
                  <SidebarMenuItem key={chat.id}>
                    <SidebarMenuButton>
                      <MessageSquare className="h-4 w-4" />
                      <span className="truncate">{chat.title}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            )}
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t border-sidebar-border px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="text-xs text-muted-foreground">
            Powered by ADK
          </div>
          <ThemeToggle />
        </div>
      </SidebarFooter>
    </Sidebar>
  )
}
