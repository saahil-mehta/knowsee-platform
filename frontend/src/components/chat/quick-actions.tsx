"use client";

type QuickActionsProps = {
  actions: string[];
  onSelect: (value: string) => void;
  isLoading: boolean;
  title?: string;
  stacked?: boolean;
};

export function QuickActions({
  actions,
  onSelect,
  isLoading,
}: QuickActionsProps) {
  if (actions.length === 0) {
    return null;
  }

  return (
    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
      {actions.map((action) => (
        <button
          key={action}
          type="button"
          disabled={isLoading}
          onClick={() => onSelect(action)}
          className="rounded-xl border bg-card px-4 py-3 text-left text-sm transition-colors hover:bg-accent hover:text-accent-foreground disabled:pointer-events-none disabled:opacity-50"
        >
          {action}
        </button>
      ))}
    </div>
  );
}
