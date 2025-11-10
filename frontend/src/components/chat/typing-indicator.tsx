"use client";

export function TypingIndicator() {
  return (
    <div className="flex animate-fade-up justify-start">
      <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-medium uppercase tracking-[0.3em] text-slate-300">
        <span className="flex gap-1">
          <span className="h-1.5 w-1.5 rounded-full bg-slate-400 animate-pulse-soft [animation-delay:-200ms]" />
          <span className="h-1.5 w-1.5 rounded-full bg-slate-400 animate-pulse-soft [animation-delay:-100ms]" />
          <span className="h-1.5 w-1.5 rounded-full bg-slate-400 animate-pulse-soft" />
        </span>
        Thinking
      </div>
    </div>
  );
}
