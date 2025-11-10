"use client";

type EmptyStateProps = {
  actions: string[];
  onSelect: (value: string) => void;
  isLoading: boolean;
};

export function EmptyState() {
  return (
    <div className="flex h-full flex-col items-center justify-center space-y-3 text-center">
      <h2 className="font-semibold text-foreground text-xl">Hello there!</h2>
      <p className="text-muted-foreground">How can I help you today?</p>
    </div>
  );
}
