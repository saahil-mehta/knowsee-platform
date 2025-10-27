"use client"

import * as React from "react"
import { motion, AnimatePresence } from "motion/react"
import { ArrowDown } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface ChatContainerProps {
  children: React.ReactNode
  className?: string
}

export function ChatContainerRoot({ children, className }: ChatContainerProps) {
  const scrollRef = React.useRef<HTMLDivElement>(null)
  const [isAtBottom, setIsAtBottom] = React.useState(true)

  // Manual scroll detection
  React.useEffect(() => {
    const element = scrollRef.current
    if (!element) return

    const handleScroll = () => {
      const { scrollTop, scrollHeight, clientHeight } = element
      const threshold = 50
      setIsAtBottom(scrollHeight - scrollTop - clientHeight < threshold)
    }

    element.addEventListener("scroll", handleScroll)
    return () => element.removeEventListener("scroll", handleScroll)
  }, [])

  const scrollToBottom = () => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    })
  }

  // Auto-scroll on new messages
  React.useEffect(() => {
    if (isAtBottom) {
      scrollToBottom()
    }
  }, [children, isAtBottom])

  return (
    <div className={cn("relative flex flex-col h-full", className)}>
      <div
        ref={scrollRef}
        className="flex-1 overflow-y-auto"
      >
        {children}
      </div>

      <AnimatePresence>
        {!isAtBottom && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: 10 }}
            transition={{
              type: "spring",
              stiffness: 300,
              damping: 25,
            }}
            className="absolute bottom-4 right-4"
          >
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8 rounded-full shadow-lg"
              onClick={scrollToBottom}
            >
              <ArrowDown className="h-4 w-4" />
              <span className="sr-only">Scroll to bottom</span>
            </Button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export function ChatContainerContent({ children, className }: ChatContainerProps) {
  return (
    <div className={cn("px-4 py-4 space-y-4", className)}>
      {children}
    </div>
  )
}

export function ChatContainerScrollAnchor() {
  return <div className="h-px" />
}

export const ChatContainer = {
  Root: ChatContainerRoot,
  Content: ChatContainerContent,
  ScrollAnchor: ChatContainerScrollAnchor,
}
