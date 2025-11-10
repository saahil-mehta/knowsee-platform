"use client";

import { KeyboardEvent, ReactNode } from "react";

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
    <div className="rounded-[28px] border border-white/7 bg-[#030304] px-4 py-3 shadow-[0_16px_50px_rgba(0,0,0,0.65)] sm:px-6">
      <div className="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.35em] text-slate-500">
        <span className="pill px-3 py-1 text-slate-200">Model · Copilot</span>
        <span className="pill px-3 py-1 text-slate-200/80">Private</span>
      </div>

      <div className="mt-3 flex flex-col gap-3">
        <textarea
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onKeyDown={handleKeyDown}
          rows={2}
          placeholder="Ask anything…"
          className="min-h-[84px] w-full resize-none rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-base text-white placeholder:text-slate-600 focus:border-white/30 focus:outline-none"
        />

        <div className="flex flex-wrap items-center justify-between gap-3 text-slate-400">
          <div className="flex gap-2">
            <ActionButton icon={<PaperclipIcon />} label="file" />
            <ActionButton icon={<ImageIcon />} label="image" />
          </div>
          {isLoading ? (
            <button
              type="button"
              onClick={onStop}
              className="pill inline-flex h-12 w-12 items-center justify-center border-red-200/40 bg-red-500/10 text-red-200 transition hover:border-red-200/70"
            >
              <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <rect width="12" height="12" x="6" y="6" rx="2" />
              </svg>
            </button>
          ) : (
            <button
              type="button"
              disabled={disabled}
              onClick={onSend}
              className="pill inline-flex h-12 w-12 items-center justify-center bg-white text-slate-900 transition hover:opacity-90 disabled:opacity-40"
            >
              <SendIcon />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function ActionButton({ icon, label }: { icon: ReactNode; label: string }) {
  return (
    <button
      type="button"
      className="pill inline-flex items-center gap-2 px-3 py-2 text-xs font-semibold uppercase tracking-[0.3em] text-slate-300 hover:border-white/20 hover:bg-white/10"
    >
      {icon}
      {label}
    </button>
  );
}

function PaperclipIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-3.5 w-3.5"
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

function ImageIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-3.5 w-3.5"
      fill="none"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.5"
      viewBox="0 0 24 24"
    >
      <rect height="14" rx="2" width="18" x="3" y="5" />
      <path d="m3 15 4-4 11 11" />
      <circle cx="9" cy="9" r="1.5" />
    </svg>
  );
}

function SendIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4"
      fill="currentColor"
      viewBox="0 0 24 24"
    >
      <path d="m2 21 20-9L2 3l1 7 12 2-12 2z" />
    </svg>
  );
}
