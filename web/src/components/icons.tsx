'use client'

import type { SVGProps } from 'react'

const baseProps = {
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.5,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
}

export function SparklesIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M12 3.25l1.35 3.72 3.72 1.35-3.72 1.35-1.35 3.72-1.35-3.72-3.72-1.35 3.72-1.35z" />
      <path d="M6 5.25l.95 2.6 2.6.95-2.6.95-.95 2.6-.95-2.6-2.6-.95 2.6-.95z" className="opacity-70" />
      <path d="M17.5 13.25l.75 2.05 2.05.75-2.05.75-.75 2.05-.75-2.05-2.05-.75 2.05-.75z" className="opacity-60" />
    </svg>
  )
}

export function SunIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 3v2m0 14v2m9-9h-2M5 12H3m15.364-6.364l-1.414 1.414M7.05 16.95 5.636 18.364m0-12.728L7.05 7.05m9.9 9.9 1.414 1.414" />
    </svg>
  )
}

export function MoonIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M20.354 15.354A9 9 0 1111.293 5.293a7 7 0 009.061 9.061z" />
    </svg>
  )
}

export function PlusIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M12 5v14M5 12h14" />
    </svg>
  )
}

export function ArrowUpIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M12 5l6 6M12 5l-6 6" />
      <path d="M12 5v14" />
    </svg>
  )
}

export function PaperclipIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M21 9.5L12.5 18a5 5 0 01-7.07-7.07l8-8a3.5 3.5 0 115 4.95L10.5 15.5a1.5 1.5 0 01-2.12-2.12l7-7" />
    </svg>
  )
}

export function MenuIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  )
}

export function TrashIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M9 4h6l1 2h4M4 6h16M6 6l1 12a2 2 0 002 2h6a2 2 0 002-2l1-12" />
      <path d="M10 11v6m4-6v6" />
    </svg>
  )
}

export function UserIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M16 18a4 4 0 00-8 0" />
      <circle cx="12" cy="9" r="3" />
    </svg>
  )
}

export function BotIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <rect x="4" y="8" width="16" height="11" rx="4" />
      <path d="M12 3v5m-4 5h.01M16 13h.01M7 21h10" />
    </svg>
  )
}

export function ChevronRightIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...baseProps} {...props}>
      <path d="M9 6l6 6-6 6" />
    </svg>
  )
}
