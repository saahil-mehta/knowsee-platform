"use client";

import { Plus, PanelLeft } from "lucide-react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/theme-toggle";

type NavHeaderProps = {
  isSidebarCollapsed: boolean;
  onToggleSidebar: () => void;
};

export function NavHeader({ isSidebarCollapsed, onToggleSidebar }: NavHeaderProps) {
  const router = useRouter();

  return (
    <header className="sticky top-0 z-10 flex h-14 items-center gap-4 bg-background/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="icon" onClick={onToggleSidebar} className="hidden md:flex">
          <PanelLeft className="h-5 w-5" />
          <span className="sr-only">Toggle Sidebar</span>
        </Button>
        <div className="flex flex-1 items-center gap-4">
          <h1 className="font-serif text-2xl select-none cursor-default">
            <span className="font-normal">Know</span>
            <span className="font-light italic opacity-70">see</span>
          </h1>
        </div>
      </div>

      <div className="flex flex-1 justify-end items-center gap-2">
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
