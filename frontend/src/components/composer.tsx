"use client"

import * as React from "react"
import { Send, Square, Paperclip } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { cn } from "@/lib/utils"

interface ComposerProps {
  value: string
  onChange: (value: string) => void
  onSubmit: () => void
  onStop?: () => void
  isLoading?: boolean
  disabled?: boolean
  placeholder?: string
  maxHeight?: number
  className?: string
}

export function Composer({
  value,
  onChange,
  onSubmit,
  onStop,
  isLoading = false,
  disabled = false,
  placeholder = "Type your message...",
  maxHeight = 240,
  className,
}: ComposerProps) {
  const textareaRef = React.useRef<HTMLTextAreaElement>(null)

  // Auto-resize textarea
  React.useEffect(() => {
    const textarea = textareaRef.current
    if (!textarea) return

    textarea.style.height = "auto"
    const scrollHeight = textarea.scrollHeight
    textarea.style.height = Math.min(scrollHeight, maxHeight) + "px"
  }, [value, maxHeight])

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      if (!isLoading && value.trim()) {
        onSubmit()
      }
    }
  }

  const handleSubmit = () => {
    if (!isLoading && value.trim()) {
      onSubmit()
    }
  }

  return (
    <div className={cn(
      "border-t border-border/50 bg-gradient-knowsee-reverse backdrop-blur-knowsee shadow-knowsee-lg px-4 py-3",
      className
    )}>
      <div className="relative flex items-end gap-2">
        {/* Textarea */}
        <div className="flex-1 relative">
          <Textarea
            ref={textareaRef}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            disabled={disabled || isLoading}
            className="min-h-[52px] max-h-[240px] resize-none pr-12"
            rows={1}
          />

          {/* Attachment Button (Placeholder) */}
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="ghost"
                size="icon"
                className="absolute right-2 bottom-2 h-7 w-7"
                disabled
              >
                <Paperclip className="h-4 w-4" />
                <span className="sr-only">Attach file (coming soon)</span>
              </Button>
            </TooltipTrigger>
            <TooltipContent side="top">
              Attach file (coming soon)
            </TooltipContent>
          </Tooltip>
        </div>

        {/* Send / Stop Button */}
        {isLoading && onStop ? (
          <Button
            variant="destructive"
            size="icon"
            onClick={onStop}
            className="shrink-0"
          >
            <Square className="h-4 w-4 fill-current" />
            <span className="sr-only">Stop generating</span>
          </Button>
        ) : (
          <Button
            onClick={handleSubmit}
            disabled={!value.trim() || disabled}
            size="icon"
            className="shrink-0 bg-primary hover:bg-primary/90 text-primary-foreground glow-purple transition-all hover-lift"
          >
            <Send className="h-4 w-4" />
            <span className="sr-only">Send message</span>
          </Button>
        )}
      </div>

      {/* Helper Text */}
      <div className="mt-2 text-xs text-muted-foreground text-center">
        Press <kbd className="px-1 py-0.5 rounded bg-muted font-mono">Enter</kbd> to send,{" "}
        <kbd className="px-1 py-0.5 rounded bg-muted font-mono">Shift</kbd> +{" "}
        <kbd className="px-1 py-0.5 rounded bg-muted font-mono">Enter</kbd> for new line
      </div>
    </div>
  )
}
