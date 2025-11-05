import type { Metadata } from 'next'
import './globals.css'

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
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  )
}
