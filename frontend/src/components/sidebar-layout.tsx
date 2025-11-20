"use client";

import { useState } from "react";
import { AppSidebar } from "@/components/app-sidebar";
import { NavHeader } from "@/components/nav-header";

export function SidebarLayout({ children }: { children: React.ReactNode }) {
    const [isCollapsed, setIsCollapsed] = useState(false);

    return (
        <div className="flex h-screen overflow-hidden bg-background">
            <AppSidebar isCollapsed={isCollapsed} />
            <div className="flex flex-1 flex-col min-w-0 transition-all duration-300 ease-in-out">
                <NavHeader
                    isSidebarCollapsed={isCollapsed}
                    onToggleSidebar={() => setIsCollapsed(!isCollapsed)}
                />
                <main className="flex-1 overflow-auto relative">
                    {children}
                </main>
            </div>
        </div>
    );
}
