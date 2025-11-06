'use client'

import { useMemo } from 'react'
import { useTheme } from './theme-provider'
import { MoonIcon, SunIcon } from '../icons'

interface ThemeToggleProps {
  showLabel?: boolean
  className?: string
}

export function ThemeToggle({ showLabel = false, className }: ThemeToggleProps) {
  const { theme, toggleTheme } = useTheme()
  const label = useMemo(() => (theme === 'dark' ? 'Dark mode' : 'Light mode'), [theme])

  return (
    <button
      type="button"
      onClick={toggleTheme}
      className={`group inline-flex items-center gap-2 rounded-full border border-zinc-200 bg-white px-3 py-1.5 text-xs font-medium text-zinc-600 shadow-sm transition-all hover:-translate-y-0.5 hover:border-zinc-300 hover:text-zinc-900 hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300 dark:hover:border-zinc-600 dark:hover:text-white ${className ?? ''}`}
      aria-label="Toggle theme"
    >
      <span className="relative flex h-6 w-6 items-center justify-center overflow-hidden rounded-full bg-zinc-100 transition-colors dark:bg-zinc-800">
        <SunIcon
          className={`absolute h-4 w-4 text-amber-500 transition-all duration-300 ${
            theme === 'dark' ? 'scale-0 opacity-0 rotate-90' : 'scale-100 opacity-100 rotate-0'
          }`}
        />
        <MoonIcon
          className={`absolute h-4 w-4 text-sky-300 transition-all duration-300 ${
            theme === 'dark' ? 'scale-100 opacity-100 rotate-0' : 'scale-0 opacity-0 -rotate-90'
          }`}
        />
      </span>
      {showLabel && <span className="transition-colors duration-300">{label}</span>}
    </button>
  )
}
