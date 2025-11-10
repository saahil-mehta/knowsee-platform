import type { Metadata } from "next";
import { CopilotKit } from "@copilotkit/react-core";
import { Geist, Geist_Mono } from "next/font/google";
import { Toaster } from "sonner";
import { ThemeProvider } from "@/components/theme-provider";
import { NavHeader } from "@/components/nav-header";
import { AppSidebar } from "@/components/app-sidebar";

import "./globals.css";
import "@copilotkit/react-ui/styles.css";

export const metadata: Metadata = {
  title: "Knowsee Copilot",
  description: "AG-UI powered CopilotKit frontend wired to ADK backend",
};

const AGENT_IDENTIFIER = process.env.NEXT_PUBLIC_COPILOT_AGENT ?? "sagent_copilot";
const RUNTIME_URL = process.env.NEXT_PUBLIC_COPILOT_RUNTIME_URL ?? "/api/copilotkit";

const geistSans = Geist({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-geist",
});

const geistMono = Geist_Mono({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-geist-mono",
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable}`} suppressHydrationWarning>
      <body className="antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <CopilotKit runtimeUrl={RUNTIME_URL} agent={AGENT_IDENTIFIER}>
            <div className="flex h-screen overflow-hidden">
              <AppSidebar />
              <div className="flex flex-1 flex-col">
                <NavHeader />
                <main className="flex-1 overflow-auto">
                  {children}
                </main>
              </div>
            </div>
            <Toaster position="top-center" />
          </CopilotKit>
        </ThemeProvider>
      </body>
    </html>
  );
}
