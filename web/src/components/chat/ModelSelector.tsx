'use client'

import { useMemo, useRef } from 'react'
import { ChevronRightIcon } from '@/components/icons'

interface ModelSelectorProps {
  value: string
  onChange: (value: string) => void
}

const MODELS = [
  { value: 'knowsee-vertex-pro', label: 'Vertex Pro (120B)', latency: '420ms' },
  { value: 'knowsee-vertex-lite', label: 'Vertex Lite (32B)', latency: '210ms' },
  { value: 'knowsee-vertex-fast', label: 'Vertex Fast (8B)', latency: '130ms' },
]

export default function ModelSelector({ value, onChange }: ModelSelectorProps) {
  const selected = useMemo(() => MODELS.find((model) => model.value === value) ?? MODELS[0], [value])
  const detailsRef = useRef<HTMLDetailsElement>(null)

  return (
    <details
      ref={detailsRef}
      className="group relative inline-flex w-full max-w-xs cursor-pointer select-none flex-col rounded-2xl border border-zinc-200/70 bg-white/70 px-4 py-3 shadow-sm transition hover:-translate-y-0.5 hover:border-zinc-300 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900/60 sm:w-60"
    >
      <summary className="flex list-none items-center justify-between gap-3 text-left">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-zinc-500 dark:text-zinc-400">Model</p>
          <p className="text-sm font-medium text-zinc-900 dark:text-zinc-100">{selected.label}</p>
          <p className="text-xs text-zinc-500 dark:text-zinc-400">Streaming latency ~{selected.latency}</p>
        </div>
        <span className="flex h-8 w-8 items-center justify-center rounded-full border border-zinc-200 bg-white text-zinc-600 transition group-open:rotate-90 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300">
          <ChevronRightIcon className="h-4 w-4" />
        </span>
      </summary>
      <div className="absolute left-0 top-full z-20 mt-2 w-full rounded-2xl border border-zinc-200/70 bg-white/95 p-2 shadow-lg backdrop-blur-xl dark:border-zinc-700/70 dark:bg-zinc-900/90">
        <ul className="space-y-1 text-sm">
          {MODELS.map((model) => {
            const isActive = model.value === selected.value
            return (
              <li key={model.value}>
                <button
                  type="button"
                  onClick={() => {
                    onChange(model.value)
                    detailsRef.current?.removeAttribute('open')
                  }}
                  className={`w-full rounded-xl px-3 py-2 text-left transition ${
                    isActive
                      ? 'bg-primary-500/10 text-primary-600 dark:bg-primary-500/20 dark:text-primary-200'
                      : 'text-zinc-600 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800'
                  }`}
                >
                  <p className="font-medium">{model.label}</p>
                  <p className="text-xs text-zinc-500 dark:text-zinc-400">{model.latency} avg latency</p>
                </button>
              </li>
            )
          })}
        </ul>
      </div>
    </details>
  )
}
