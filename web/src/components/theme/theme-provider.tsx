'use client'

import { createContext, useContext, useEffect, useMemo, useState } from 'react'

export type Theme = 'light' | 'dark'

interface ThemeContextValue {
  theme: Theme
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined)

const THEME_STORAGE_KEY = 'knowsee-theme-preference'

const prefersDark = () =>
  typeof window !== 'undefined' && window.matchMedia('(prefers-color-scheme: dark)').matches

function applyTheme(theme: Theme) {
  if (typeof document === 'undefined') return
  const root = document.documentElement
  root.classList.toggle('dark', theme === 'dark')
  root.style.setProperty('color-scheme', theme)
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window === 'undefined') {
      return 'light'
    }
    const stored = window.localStorage.getItem(THEME_STORAGE_KEY) as Theme | null
    const nextTheme = stored === 'light' || stored === 'dark' ? stored : prefersDark() ? 'dark' : 'light'
    applyTheme(nextTheme)
    return nextTheme
  })

  useEffect(() => {
    applyTheme(theme)
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(THEME_STORAGE_KEY, theme)
    }
  }, [theme])

  useEffect(() => {
    if (typeof window === 'undefined') return

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    if (!window.localStorage.getItem(THEME_STORAGE_KEY)) {
      setThemeState(mediaQuery.matches ? 'dark' : 'light')
    }

    const handler = (event: MediaQueryListEvent) => {
      if (!window.localStorage.getItem(THEME_STORAGE_KEY)) {
        setThemeState(event.matches ? 'dark' : 'light')
      }
    }

    mediaQuery.addEventListener('change', handler)
    return () => mediaQuery.removeEventListener('change', handler)
  }, [])

  const value = useMemo<ThemeContextValue>(
    () => ({
      theme,
      setTheme: (next) => {
        setThemeState(next)
      },
      toggleTheme: () => {
        setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'))
      },
    }),
    [theme]
  )

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}
