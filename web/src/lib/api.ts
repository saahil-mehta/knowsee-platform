/**
 * API client for chat and file operations
 */

import type { ChatRequest, StreamChunk } from '@/types/chat'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

/**
 * Stream chat completion from API
 */
export async function* streamChatCompletion(
  request: ChatRequest
): AsyncGenerator<string, void, undefined> {
  const response = await fetch(`${API_BASE_URL}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      ...request,
      stream: true,
    }),
  })

  if (!response.ok) {
    throw new Error(`API error: ${response.status} ${response.statusText}`)
  }

  const reader = response.body?.getReader()
  if (!reader) {
    throw new Error('No response body')
  }

  const decoder = new TextDecoder()
  let buffer = ''

  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed || !trimmed.startsWith('data: ')) continue

        const data = trimmed.slice(6)
        if (data === '[DONE]') return

        try {
          const chunk: StreamChunk = JSON.parse(data)
          const content = chunk.choices[0]?.delta?.content
          if (content) {
            yield content
          }
        } catch (e) {
          console.error('Failed to parse chunk:', e)
        }
      }
    }
  } finally {
    reader.releaseLock()
  }
}

/**
 * Upload file to server
 */
export async function uploadFile(file: File): Promise<{ id: string; url: string }> {
  const formData = new FormData()
  formData.append('file', file)

  const response = await fetch(`${API_BASE_URL}/v1/files/upload`, {
    method: 'POST',
    body: formData,
  })

  if (!response.ok) {
    throw new Error(`Upload failed: ${response.status} ${response.statusText}`)
  }

  return response.json()
}
