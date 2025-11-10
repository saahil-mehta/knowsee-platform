"use client";

import { KeyboardEvent } from "react";

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

  const handleKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      if (!isLoading && !disabled) {
        onSend();
      }
    }
  };

  return (
    <div className="relative flex items-end gap-2 rounded-3xl border bg-input px-4 py-3 shadow-sm">
      <button
        type="button"
        className="flex-shrink-0 text-muted-foreground transition hover:text-foreground"
        aria-label="Attach file"
      >
        <PaperclipIcon />
      </button>
      <textarea
        value={value}
        onChange={(event) => onChange(event.target.value)}
        onKeyDown={handleKeyDown}
        rows={1}
        placeholder="Send a message..."
        className="max-h-[200px] min-h-[20px] flex-1 resize-none bg-transparent text-sm leading-5 placeholder:text-muted-foreground focus:outline-none"
      />
      {isLoading ? (
        <button
          type="button"
          onClick={onStop}
          className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-destructive text-destructive-foreground transition hover:bg-destructive/90"
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
          className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground transition hover:bg-primary/90 disabled:pointer-events-none disabled:opacity-50"
          aria-label="Send message"
        >
          <SendIcon />
        </button>
      )}
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
      strokeWidth="2"
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
      strokeWidth="2"
      viewBox="0 0 24 24"
    >
      <path d="M22 2 11 13M22 2l-7 20-4-9-9-4 20-7z" />
    </svg>
  );
}
