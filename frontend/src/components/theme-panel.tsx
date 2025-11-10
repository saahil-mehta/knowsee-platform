"use client";

import { ChangeEvent } from "react";

export type ThemePanelProps = {
  themeColor: string;
  onThemeChange: (value: string) => void;
};

export function ThemePanel({ themeColor, onThemeChange }: ThemePanelProps) {
  const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
    onThemeChange(event.target.value);
  };

  return (
    <section className="rounded-3xl bg-white/5 p-6 text-slate-100 shadow-xl backdrop-blur">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-sm uppercase tracking-[0.2em] text-slate-300">Theme</p>
          <h2 className="text-2xl font-semibold">Agent Accent</h2>
        </div>
        <span
          data-testid="theme-preview"
          className="h-12 w-12 rounded-full border border-white/20"
          style={{ backgroundColor: themeColor }}
        />
      </div>

      <p className="mt-4 text-sm text-slate-200">
        The Copilot can call the <code>setThemeColor</code> action to update the UI.
      </p>

      <label className="mt-5 block text-xs font-semibold uppercase tracking-[0.25em] text-slate-400">
        Accent color
        <input
          aria-label="Accent color"
          type="text"
          value={themeColor}
          onChange={handleChange}
          className="mt-2 w-full rounded-2xl border border-white/20 bg-white/5 px-4 py-2 text-base text-white outline-none focus:border-white/60"
        />
      </label>
    </section>
  );
}
