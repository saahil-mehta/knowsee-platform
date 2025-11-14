"use client";

import Link from "next/link";
import { MessageSquare } from "lucide-react";

export function AppSidebar() {
  return (
    <aside className="hidden w-64 flex-col border-r bg-muted/10 md:flex">
      <div className="flex h-14 items-center border-b px-4">
        <Link href="/" className="flex items-center gap-2 font-semibold">
          <MessageSquare className="h-5 w-5" />
          <span>Chats</span>
        </Link>
      </div>
      <div className="flex-1 overflow-auto p-4">
        <p className="text-muted-foreground text-sm">Chat history will appear here</p>
      </div>
    </aside>
  );
}
