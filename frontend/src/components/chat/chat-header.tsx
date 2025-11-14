"use client";

type ChatHeaderProps = {
  hasMessages: boolean;
  onReset?: () => void;
};

export function ChatHeader({ hasMessages, onReset }: ChatHeaderProps) {
  return (
    <header className="panel flex flex-col gap-5 rounded-[32px] px-6 py-6 text-slate-200">
      <div className="space-y-2">
        <p className="text-[11px] uppercase tracking-[0.5em] text-slate-300/80">
          Knowsee Copilot
        </p>
        <h1 className="text-3xl font-semibold text-white">
          Conversation Studio
        </h1>
        <p className="text-sm text-slate-300">
          Plan, research, and ship faster with CopilotKit and AG-UI.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="pill inline-flex items-center gap-2 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.35em] text-emerald-200">
          <span className="h-2.5 w-2.5 rounded-full bg-emerald-300 shadow-[0_0_12px_rgba(16,185,129,0.95)] animate-pulse-soft" />
          Live
        </div>
        <button
          type="button"
          onClick={() => onReset?.()}
          className="pill inline-flex items-center gap-2 px-5 py-2 text-sm font-medium text-white transition hover:border-white/20 hover:bg-white/10"
        >
          <svg
            aria-hidden="true"
            className="h-4 w-4"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            viewBox="0 0 24 24"
          >
            <path
              d="M12 5v14M5 12h14"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          {hasMessages ? "New chat" : "Start chat"}
        </button>
      </div>
    </header>
  );
}
