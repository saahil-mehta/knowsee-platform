"use client";

import { memo } from "react";

export type ProverbBoardProps = {
  proverbs: string[];
  onRemove: (index: number) => void;
};

/**
 * Renders the list of proverbs with minimal UI sugar so the agent can mutate
 * shared state and the user can keep track of what changed.
 */
export const ProverbBoard = memo(function ProverbBoard({
  proverbs,
  onRemove,
}: ProverbBoardProps) {
  if (proverbs.length === 0) {
    return (
      <div className="rounded-2xl border border-white/15 bg-white/5 p-6 text-center text-sm text-slate-200">
        Ask the assistant to add a proverb to kick things off.
      </div>
    );
  }

  return (
    <ul className="flex flex-col gap-4">
      {proverbs.map((proverb, index) => (
        <li
          key={`${proverb}-${index}`}
          className="relative rounded-2xl border border-white/10 bg-white/10 p-5 shadow-2xl"
        >
          <p className="pr-12 text-base leading-relaxed text-slate-50">{proverb}</p>
          <button
            type="button"
            aria-label="Remove proverb"
            className="absolute right-3 top-3 rounded-full border border-white/30 bg-white/10 px-3 py-1 text-xs uppercase tracking-wide text-white transition hover:bg-white/30"
            onClick={() => onRemove(index)}
          >
            Remove proverb
          </button>
        </li>
      ))}
    </ul>
  );
});
