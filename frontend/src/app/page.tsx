"use client";

import { useMemo, useState } from "react";
import { useCoAgent, useCopilotAction } from "@copilotkit/react-core";
import { CopilotKitCSSProperties, CopilotSidebar } from "@copilotkit/react-ui";

import { ProverbBoard } from "../components/proverb-board";
import { ThemePanel } from "../components/theme-panel";
import { normalizeHexColor } from "../lib/theme";

type AgentState = {
  proverbs: string[];
};

const DEFAULT_THEME = "#6366f1";
const INITIAL_PROVERBS = [
  "CopilotKit may be new, but it's the best thing since sliced bread.",
  "AG-UI streams context like a DJ crossfading perfect tracks.",
];

export default function Page() {
  const [themeColor, setThemeColor] = useState(DEFAULT_THEME);

  const { state, setState } = useCoAgent<AgentState>({
    name: "sagent_copilot",
    initialState: { proverbs: INITIAL_PROVERBS },
  });

  useCopilotAction({
    name: "setThemeColor",
    parameters: [
      {
        name: "themeColor",
        description: "Hex color to tint the entire interface (e.g. #f97316)",
        type: "string",
        required: true,
      },
    ],
    handler({ themeColor }) {
      setThemeColor(normalizeHexColor(themeColor));
    },
  });

  useCopilotAction({
    name: "set_proverbs_ui_state",
    description: "Replace the current proverb list shown on screen.",
    parameters: [
      {
        name: "proverbs",
        type: "array",
        required: true,
        items: { type: "string" },
      },
    ],
    handler({ proverbs }) {
      setState({ proverbs });
    },
  });

  useCopilotAction({
    name: "get_weather",
    description: "Render a weather card for the requested location.",
    parameters: [
      { name: "location", type: "string", required: true },
    ],
    render: ({ args }) => (
      <WeatherCard location={args.location} themeColor={themeColor} />
    ),
  });

  const subtitle = useMemo(
    () => `Streaming from ${process.env.NEXT_PUBLIC_AGUI_URL ?? "http://localhost:8000/api/agui"}`,
    [],
  );

  return (
    <main
      style={{ "--copilot-kit-primary-color": themeColor } as CopilotKitCSSProperties}
      className="min-h-screen"
    >
      <CopilotSidebar
        clickOutsideToClose
        defaultOpen
        labels={{
          title: "Knowsee Copilot",
          initial:
            "👋 Hi! I'm your AG-UI powered teammate. Ask me to recolor the UI, curate proverbs, or call the weather tool.",
        }}
      >
        <section className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-6 py-12 md:flex-row">
          <div className="flex-1 space-y-6">
            <div>
              <p className="text-sm uppercase tracking-[0.3em] text-slate-300">Now playing</p>
              <h1 className="text-4xl font-bold text-white md:text-5xl">Knowsee CopilotKit Canvas</h1>
              <p className="mt-2 text-sm text-slate-300">{subtitle}</p>
            </div>
            <ThemePanel themeColor={themeColor} onThemeChange={setThemeColor} />
            <div className="rounded-3xl bg-white/5 p-6 shadow-2xl">
              <div className="flex items-baseline justify-between">
                <div>
                  <p className="text-sm uppercase tracking-[0.2em] text-slate-300">Wisdom log</p>
                  <h2 className="text-2xl font-semibold text-white">Shared Proverbs</h2>
                </div>
                <p className="text-xs text-slate-300">Managed by AG-UI sessions</p>
              </div>
              <div className="mt-6">
                <ProverbBoard
                  proverbs={state.proverbs ?? []}
                  onRemove={(index) =>
                    setState({
                      proverbs: state.proverbs?.filter((_, i) => i !== index) ?? [],
                    })
                  }
                />
              </div>
            </div>
          </div>
          <aside className="w-full max-w-sm space-y-6">
            <WeatherCard location="San Francisco" themeColor={themeColor} />
          </aside>
        </section>
      </CopilotSidebar>
    </main>
  );
}

type WeatherCardProps = {
  location?: string;
  themeColor: string;
};

function WeatherCard({ location = "Anywhere", themeColor }: WeatherCardProps) {
  return (
    <div
      className="rounded-3xl p-6 text-white shadow-2xl"
      style={{ background: themeColor }}
    >
      <p className="text-xs uppercase tracking-[0.3em]">Weather</p>
      <h3 className="text-2xl font-semibold">{location}</h3>
      <p className="mt-2 text-sm text-white/70">Live data supplied by the agent.</p>
      <div className="mt-6 flex items-center gap-6">
        <div>
          <p className="text-4xl font-bold">72°</p>
          <p className="text-sm text-white/70">Sunny vibes</p>
        </div>
        <div className="text-xs text-white/80">
          <p>Humidity · 48%</p>
          <p>Wind · 5 mph</p>
          <p>Feels like · 74°</p>
        </div>
      </div>
    </div>
  );
}
