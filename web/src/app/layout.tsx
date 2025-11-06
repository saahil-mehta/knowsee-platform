import type { Metadata } from 'next'
import './globals.css'
import { ThemeProvider } from '@/components/theme/theme-provider'

export const metadata: Metadata = {
  title: 'Knowsee - AI Chat Assistant',
  description: 'Chat with GPT-OSS-120B powered by Vertex AI',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-background text-foreground antialiased transition-colors">
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  )
}
