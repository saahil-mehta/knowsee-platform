import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";

import { CopilotKit } from "@copilotkit/react-core";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SidebarProvider } from "@/components/ui/sidebar";

import "./fonts.css";
import "./globals.css";

export const metadata: Metadata = {
  title: "Knowsee Assistant",
  description: "Intelligent RAG agent powered by Google ADK and CopilotKit. Search, analyse, and interact with your knowledge base.",
  viewport: {
    width: "device-width",
    initialScale: 1,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${GeistSans.variable} ${GeistMono.variable}`}
    >
      <body className="antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange={false}
        >
          <TooltipProvider delayDuration={200} skipDelayDuration={500}>
            <SidebarProvider defaultOpen={true}>
              <CopilotKit runtimeUrl="/api/copilotkit" agent="my_agent">
                {children}
              </CopilotKit>
            </SidebarProvider>
          </TooltipProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
