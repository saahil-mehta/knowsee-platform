import type { Metadata } from "next";
import { CopilotKit } from "@copilotkit/react-core";
import { Geist, Geist_Mono, Instrument_Serif } from "next/font/google";
import { Toaster } from "sonner";
import { ThemeProvider } from "@/components/theme-provider";
import { SidebarLayout } from "@/components/sidebar-layout";

import "./globals.css";
import "@copilotkit/react-ui/styles.css";

export const metadata: Metadata = {
  title: "Knowsee",
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

const instrumentSerif = Instrument_Serif({
  weight: ["400"],
  subsets: ["latin"],
  display: "swap",
  variable: "--font-instrument-serif",
  style: ["normal", "italic"],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} ${instrumentSerif.variable}`} suppressHydrationWarning>
      <body className="antialiased">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <CopilotKit runtimeUrl={RUNTIME_URL} agent={AGENT_IDENTIFIER}>
            <SidebarLayout>
              {children}
            </SidebarLayout>
            <Toaster position="top-center" />
          </CopilotKit>
        </ThemeProvider>
      </body>
    </html>
  );
}
