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
  title = "Quick Actions",
  stacked,
}: QuickActionsProps) {
  if (actions.length === 0) {
    return null;
  }

  return (
    <div className="space-y-3">
      <p className="font-medium text-muted-foreground text-sm">
        {title}
      </p>

      <div className={`flex flex-wrap gap-2`}>
        {actions.map((action) => (
          <button
            key={action}
            type="button"
            disabled={isLoading}
            onClick={() => onSelect(action)}
            className="rounded-lg border bg-muted/50 px-3 py-2 text-left text-sm transition-colors hover:bg-muted hover:text-foreground disabled:opacity-50"
          >
            {action}
          </button>
        ))}
      </div>
    </div>
  );
}
