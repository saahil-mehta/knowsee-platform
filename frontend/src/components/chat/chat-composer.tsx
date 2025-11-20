"use client";

import { KeyboardEvent, useState, useRef, useEffect } from "react";

type ChatComposerProps = {
  value: string;
  onChange: (value: string) => void;
  onSend: () => void;
  onStop: () => void;
  isLoading: boolean;
};

import { Button } from "@/components/ui/button";

export function ChatComposer({
  value,
  onChange,
  onSend,
  onStop,
  isLoading,
}: ChatComposerProps) {
  const disabled = value.trim().length === 0;
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const adjustHeight = () => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`;
    }
  };

  useEffect(() => {
    adjustHeight();
  }, [value]);

  const handleKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      if (!isLoading && !disabled) {
        onSend();
      }
    }
  };

  const [isFocused, setIsFocused] = useState(false);
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div className="flex flex-col gap-2">
      <div
        className={`relative flex items-end gap-2 rounded-3xl bg-background px-3 py-2 shadow-sm border border-border/40 transition-all duration-200 ease-in-out ${isFocused || isHovered ? "shadow-md border-border/60 ring-1 ring-black/5" : ""
          }`}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 rounded-full text-muted-foreground/70 hover:text-foreground mb-1"
          aria-label="Attach file"
        >
          <PaperclipIcon />
        </Button>

        <textarea
          ref={textareaRef}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          rows={1}
          placeholder="Send a message..."
          className="max-h-[200px] min-h-[24px] flex-1 resize-none bg-transparent py-2 text-[15px] leading-relaxed placeholder:text-muted-foreground/70 focus:outline-none"
        />

        {isLoading ? (
          <Button
            variant="default"
            size="icon"
            onClick={onStop}
            className="h-8 w-8 rounded-full bg-foreground text-background hover:bg-foreground/90 mb-1"
            aria-label="Stop generating"
          >
            <svg aria-hidden="true" className="h-3 w-3" viewBox="0 0 24 24" fill="currentColor">
              <rect width="12" height="12" x="6" y="6" rx="2" />
            </svg>
          </Button>
        ) : (
          <Button
            variant="ghost"
            size="icon"
            disabled={disabled}
            onClick={onSend}
            className={`h-8 w-8 rounded-full transition-all duration-200 mb-1 ${disabled
                ? "bg-transparent text-muted-foreground/50"
                : "bg-foreground text-background hover:bg-foreground/90"
              }`}
            aria-label="Send message"
          >
            <SendIcon />
          </Button>
        )}
      </div>
      <div className={`px-4 text-xs text-center text-muted-foreground/40 transition-opacity duration-200 ${isFocused || isHovered ? "opacity-100" : "opacity-0"
        }`}>
        Press <kbd className="font-sans font-medium">Enter</kbd> to send, <kbd className="font-sans font-medium">Shift + Enter</kbd> for new line
      </div>
    </div>
  );
}


function PaperclipIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-5 w-5"
      fill="none"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.5"
      viewBox="0 0 24 24"
    >
      <path d="M21.44 11.05 12 20.49a5 5 0 0 1-7.07-7.07l9.43-9.44a3 3 0 0 1 4.24 4.24l-9.43 9.44" />
    </svg>
  );
}

function SendIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4"
      fill="none"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.5"
      viewBox="0 0 24 24"
    >
      <path d="M22 2 11 13M22 2l-7 20-4-9-9-4 20-7z" />
    </svg>
  );
}
