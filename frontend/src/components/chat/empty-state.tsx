"use client";

type EmptyStateProps = {
  actions: string[];
  onSelect: (value: string) => void;
  isLoading: boolean;
};

export function EmptyState({ actions, onSelect, isLoading }: EmptyStateProps) {
  return (
    <div className="flex h-full flex-col items-center justify-center px-6 py-12 text-center">
      <div className="max-w-xl space-y-5 animate-fade-up">
        <p className="text-xs uppercase tracking-[0.5em] text-slate-500">
          Ready when you are
        </p>
        <h2 className="text-3xl font-semibold text-white">
          Start a new thread or pick a booster on the left.
        </h2>
        <p className="text-base text-slate-300">
          Everything you discuss stays in this private workspace. Switch models, attach files, or drop context as you go.
        </p>
      </div>
      <div className="mt-8 flex flex-wrap justify-center gap-3 text-sm text-slate-200">
        {actions.slice(0, 3).map((action) => (
          <button
            key={action}
            type="button"
            disabled={isLoading}
            onClick={() => onSelect(action)}
            className="pill px-4 py-2 text-slate-100 transition hover:border-white/20 hover:bg-white/10 disabled:opacity-50"
          >
            {action}
          </button>
        ))}
      </div>
    </div>
  );
}
