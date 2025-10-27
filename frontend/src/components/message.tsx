"use client"

import * as React from "react"
import { motion } from "motion/react"
import { Copy, RotateCw, User, Bot, Check } from "lucide-react"
import ReactMarkdown from "react-markdown"
import remarkGfm from "remark-gfm"

import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { cn } from "@/lib/utils"

interface MessageBubbleProps {
  children: React.ReactNode
  role: "user" | "assistant"
  className?: string
}

export function MessageBubble({ children, role, className }: MessageBubbleProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: 0.3,
        ease: "easeOut",
      }}
      className={cn(
        "group flex gap-3 px-4 py-4 hover:bg-muted/30 transition-colors",
        className
      )}
    >
      {children}
    </motion.div>
  )
}

interface MessageAvatarProps {
  role: "user" | "assistant"
}

export function MessageAvatar({ role }: MessageAvatarProps) {
  return (
    <Avatar className="h-8 w-8 shrink-0 ring-2 ring-offset-2 ring-offset-background">
      <AvatarFallback className={cn(
        "transition-all duration-300",
        role === "assistant" && "bg-primary text-primary-foreground glow-purple",
        role === "user" && "bg-secondary text-secondary-foreground glow-green"
      )}>
        {role === "assistant" ? (
          <Bot className="h-4 w-4" />
        ) : (
          <User className="h-4 w-4" />
        )}
      </AvatarFallback>
    </Avatar>
  )
}

interface MessageContentProps {
  children: React.ReactNode
  markdown?: boolean
  className?: string
}

export function MessageContent({ children, markdown = true, className }: MessageContentProps) {
  if (!markdown) {
    return <div className={cn("flex-1 space-y-2 text-sm", className)}>{children}</div>
  }

  return (
    <div className={cn("flex-1 space-y-2 text-sm prose prose-sm dark:prose-invert max-w-none", className)}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          code({ className, children, ...props }) {
            const isInline = !className
            return isInline ? (
              <code
                className="px-1.5 py-0.5 rounded-md bg-muted font-mono text-xs"
                {...props}
              >
                {children}
              </code>
            ) : (
              <code
                className={cn("block p-4 rounded-lg bg-muted font-mono text-xs overflow-x-auto", className)}
                {...props}
              >
                {children}
              </code>
            )
          },
        }}
      >
        {String(children)}
      </ReactMarkdown>
    </div>
  )
}

interface MessageActionsProps {
  content: string
  onRegenerate?: () => void
  className?: string
}

export function MessageActions({ content, onRegenerate, className }: MessageActionsProps) {
  const [copied, setCopied] = React.useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(content)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className={cn(
      "flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity",
      className
    )}>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7"
            onClick={handleCopy}
          >
            {copied ? (
              <Check className="h-3.5 w-3.5 text-green-500" />
            ) : (
              <Copy className="h-3.5 w-3.5" />
            )}
          </Button>
        </TooltipTrigger>
        <TooltipContent side="top">
          {copied ? "Copied!" : "Copy message"}
        </TooltipContent>
      </Tooltip>

      {onRegenerate && (
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7"
              onClick={onRegenerate}
            >
              <RotateCw className="h-3.5 w-3.5" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="top">
            Regenerate response
          </TooltipContent>
        </Tooltip>
      )}
    </div>
  )
}

interface LoadingIndicatorProps {
  className?: string
}

export function LoadingIndicator({ className }: LoadingIndicatorProps) {
  return (
    <div className={cn("loading-dots flex gap-1", className)}>
      <span className="h-2 w-2 rounded-full bg-muted-foreground"></span>
      <span className="h-2 w-2 rounded-full bg-muted-foreground"></span>
      <span className="h-2 w-2 rounded-full bg-muted-foreground"></span>
    </div>
  )
}
