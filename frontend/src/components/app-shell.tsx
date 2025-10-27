"use client"

import * as React from "react"
import { SidebarInset, SidebarTrigger } from "@/components/ui/sidebar"
import { Separator } from "@/components/ui/separator"

interface AppShellProps {
  children: React.ReactNode
}

export function AppShell({ children }: AppShellProps) {
  return (
    <SidebarInset className="flex flex-col">
      {/* App Header */}
      <header className="sticky top-0 z-10 flex h-14 items-center gap-3 border-b border-border/50 bg-background/95 backdrop-blur-knowsee shadow-knowsee-sm px-4">
        <SidebarTrigger className="-ml-1" />
        <Separator orientation="vertical" className="h-6" />
        <img
          src="/knowsee-logo.png"
          alt="Knowsee"
          className="h-6 w-auto object-contain"
        />
        <Separator orientation="vertical" className="h-4" />
        <span className="text-xs text-muted-foreground letter-spacing-tight">Powered by Google ADK</span>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 overflow-hidden">
        {children}
      </main>
    </SidebarInset>
  )
}
