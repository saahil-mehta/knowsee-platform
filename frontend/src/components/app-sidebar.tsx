"use client";

import Link from "next/link";
import { MessageSquare } from "lucide-react";

export function AppSidebar({ isCollapsed }: { isCollapsed: boolean }) {
  return (
    <aside
      className={`hidden flex-col border-r bg-muted/10 md:flex transition-all duration-300 ease-in-out ${isCollapsed ? "w-0 border-r-0 overflow-hidden" : "w-64"
        }`}
    >
      <div className="flex h-14 items-center border-b px-4 whitespace-nowrap overflow-hidden">
        <div className="flex items-center gap-2 font-semibold text-foreground/80">
          <MessageSquare className="h-5 w-5" />
          <span>Chats</span>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-4 whitespace-nowrap">
        <p className="text-muted-foreground text-sm">Chat history will appear here</p>
      </div>
    </aside>
  );
}
