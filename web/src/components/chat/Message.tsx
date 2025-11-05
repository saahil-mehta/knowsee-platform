'use client'

import type { Message as MessageType } from '@/types/chat'

interface MessageProps {
  message: MessageType
}

export default function Message({ message }: MessageProps) {
  const isUser = message.role === 'user'

  return (
    <div
      className={`flex w-full ${isUser ? 'justify-end' : 'justify-start'} animate-fade-in`}
    >
      <div
        className={`max-w-[80%] rounded-2xl px-4 py-3 ${
          isUser
            ? 'bg-primary-500 text-white'
            : 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100'
        }`}
      >
        <div className="whitespace-pre-wrap break-words">{message.content}</div>

        {message.files && message.files.length > 0 && (
          <div className="mt-2 space-y-1">
            {message.files.map((file) => (
              <div
                key={file.id}
                className="flex items-center gap-2 text-xs opacity-75"
              >
                <svg
                  className="h-4 w-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"
                  />
                </svg>
                <span>{file.name}</span>
              </div>
            ))}
          </div>
        )}

        <div className="mt-1 text-xs opacity-60">
          {new Date(message.timestamp).toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
          })}
        </div>
      </div>
    </div>
  )
}
