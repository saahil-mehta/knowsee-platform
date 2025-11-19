"use client";

import { KeyboardEvent, useState, useRef, useEffect } from "react";

type ChatComposerProps = {
  value: string;
  onChange: (value: string) => void;
  onSend: () => void;
  onStop: () => void;
  isLoading: boolean;
};

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
        className={`relative flex items-end gap-2 rounded-[26px] bg-muted/50 px-4 py-2.5 transition-all duration-200 ease-in-out ${isFocused || isHovered ? "bg-muted/80 shadow-lg ring-1 ring-black/5" : ""
          }`}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        <button
          type="button"
          className="flex-shrink-0 text-muted-foreground/70 transition hover:text-foreground mb-1.5"
          aria-label="Attach file"
        >
          <PaperclipIcon />
        </button>
        <textarea
          ref={textareaRef}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          rows={1}
          placeholder="Send a message..."
          className="max-h-[200px] min-h-[24px] flex-1 resize-none bg-transparent py-1 text-[15px] leading-relaxed placeholder:text-muted-foreground/70 focus:outline-none"
        />
        {isLoading ? (
          <button
            type="button"
            onClick={onStop}
            className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-destructive text-destructive-foreground transition hover:bg-destructive/90 mb-0.5"
            aria-label="Stop generating"
          >
            <svg aria-hidden="true" className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor">
              <rect width="12" height="12" x="6" y="6" rx="2" />
            </svg>
          </button>
        ) : (
          <button
            type="button"
            disabled={disabled}
            onClick={onSend}
            className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-transparent text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:pointer-events-none disabled:opacity-50 mb-0.5"
            aria-label="Send message"
          >
            <SendIcon />
          </button>
        )}
      </div>
      <div className={`px-4 text-xs text-muted-foreground/60 transition-opacity duration-200 ${isFocused || isHovered ? "opacity-100" : "opacity-0"
        }`}>
        Press <kbd className="font-sans">Enter</kbd> to send, <kbd className="font-sans">Shift + Enter</kbd> for new line
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
