'use client'

import { useState, useRef, KeyboardEvent, ChangeEvent } from 'react'
import { ArrowUpIcon, PaperclipIcon, SparklesIcon } from '@/components/icons'

interface ChatInputProps {
  onSend: (message: string) => Promise<void> | void
  disabled?: boolean
  status?: string
}

export default function ChatInput({ onSend, disabled = false, status }: ChatInputProps) {
  const [message, setMessage] = useState('')
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const handleSend = async () => {
    if (message.trim() && !disabled) {
      await onSend(message)
      setMessage('')

      if (textareaRef.current) {
        textareaRef.current.style.height = 'auto'
      }
    }
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      void handleSend()
    }
  }

  const handleInput = (e: ChangeEvent<HTMLTextAreaElement>) => {
    setMessage(e.target.value)
    const textarea = e.target
    textarea.style.height = 'auto'
    textarea.style.height = `${Math.min(textarea.scrollHeight, 220)}px`
  }

  return (
    <div className="px-4 pb-8 pt-4 sm:px-8">
      <div className="mx-auto w-full max-w-3xl space-y-3">
        <div className="rounded-3xl border border-zinc-200/70 bg-card p-4 shadow-soft-lg backdrop-blur-md transition dark:border-zinc-800/70">
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-3">
              <div className="flex flex-col gap-2">
                <button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-2xl border border-zinc-200 bg-white text-zinc-500 transition hover:-translate-y-0.5 hover:border-zinc-300 hover:text-zinc-700 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300"
                  aria-label="Attach files"
                  disabled={disabled}
                >
                  <PaperclipIcon className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-2xl border border-zinc-200 bg-white text-zinc-500 transition hover:-translate-y-0.5 hover:border-zinc-300 hover:text-zinc-700 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300"
                  aria-label="Insert template"
                  disabled={disabled}
                >
                  <SparklesIcon className="h-4 w-4" />
                </button>
              </div>
              <div className="relative flex-1">
                <textarea
                  ref={textareaRef}
                  value={message}
                  onChange={handleInput}
                  onKeyDown={handleKeyDown}
                  placeholder="Send a message..."
                  disabled={disabled}
                  rows={1}
                  className="w-full resize-none rounded-3xl border border-transparent bg-white/60 px-4 py-3 text-sm leading-6 text-zinc-900 placeholder:text-zinc-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-500/40 disabled:opacity-50 dark:bg-zinc-900/60 dark:text-zinc-100 dark:placeholder:text-zinc-500"
                />
              </div>
              <button
                onClick={() => {
                  void handleSend()
                }}
                disabled={!message.trim() || disabled}
                className="flex h-12 w-12 items-center justify-center rounded-2xl bg-zinc-900 text-white transition hover:-translate-y-0.5 hover:bg-zinc-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-zinc-900"
                aria-label="Send message"
              >
                {disabled ? (
                  <span className="flex h-5 w-5 animate-spin rounded-full border-2 border-white/40 border-t-white dark:border-zinc-900/40 dark:border-t-zinc-900" />
                ) : (
                  <ArrowUpIcon className="h-5 w-5" />
                )}
              </button>
            </div>
            <div className="flex items-center justify-between text-xs text-zinc-500 dark:text-zinc-400">
              <span>{status ?? 'Press Enter to send · Shift+Enter for a new line'}</span>
              <span>{message.length}/2000</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
