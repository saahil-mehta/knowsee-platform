'use client'

import type { Message as MessageType } from '@/types/chat'
import { BotIcon, SparklesIcon, UserIcon } from '@/components/icons'

interface MessageProps {
  message: MessageType
}

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  hour: '2-digit',
  minute: '2-digit',
})

export default function Message({ message }: MessageProps) {
  const isUser = message.role === 'user'

  return (
    <div className={`flex w-full gap-4 ${isUser ? 'flex-row-reverse text-right' : 'flex-row'}`}>
      <div
        className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-2xl shadow-sm ${
          isUser
            ? 'bg-gradient-to-br from-zinc-900 to-zinc-700 text-white'
            : 'bg-gradient-to-br from-primary-500 via-indigo-500 to-sky-500 text-white'
        }`}
      >
        {isUser ? <UserIcon className="h-5 w-5" /> : <BotIcon className="h-5 w-5" />}
      </div>

      <div className={`flex max-w-[min(75%,40rem)] flex-col gap-2 ${isUser ? 'items-end' : 'items-start'}`}>
        <div
          className={`w-full rounded-3xl px-5 py-4 text-sm leading-relaxed shadow-sm ring-1 ring-black/0 backdrop-blur ${
            isUser
              ? 'bg-zinc-900 text-white shadow-soft-lg'
              : 'bg-white/75 text-zinc-900 shadow-soft-lg ring-zinc-900/5 dark:bg-zinc-900/70 dark:text-zinc-100'
          }`}
        >
          <div className="whitespace-pre-wrap break-words text-left leading-6">
            {message.content || (
              <span className="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400">
                <SparklesIcon className="h-4 w-4" /> Streaming response…
              </span>
            )}
          </div>

          {message.files && message.files.length > 0 && (
            <div className="mt-3 space-y-2">
              {message.files.map((file) => (
                <div
                  key={file.id}
                  className="flex items-center gap-2 rounded-2xl border border-dashed border-zinc-300/70 bg-white/70 px-3 py-2 text-xs text-zinc-500 dark:border-zinc-700/60 dark:bg-zinc-900/40 dark:text-zinc-300"
                >
                  <span className="font-medium text-zinc-600 dark:text-zinc-200">{file.name}</span>
                  <span>·</span>
                  <span>{(file.size / 1024).toFixed(1)} KB</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <time className="text-xs text-zinc-400 dark:text-zinc-500">
          {timeFormatter.format(message.timestamp)}
        </time>
      </div>
    </div>
  )
}
