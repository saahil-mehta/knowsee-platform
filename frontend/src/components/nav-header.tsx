"use client";

import { Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/theme-toggle";

export function NavHeader() {
  const router = useRouter();

  return (
    <header className="sticky top-0 z-10 flex h-14 items-center gap-4 border-b bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex flex-1 items-center gap-4">
        <div className="flex items-center gap-2">
          <h1 className="font-semibold text-lg">Knowsee Copilot</h1>
          <div className="flex h-5 items-center gap-1.5 rounded-full border bg-muted px-2 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
            Live
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            router.push("/");
            router.refresh();
          }}
        >
          <Plus className="h-4 w-4" />
          New Chat
        </Button>
        <ThemeToggle />
      </div>
    </header>
  );
}
