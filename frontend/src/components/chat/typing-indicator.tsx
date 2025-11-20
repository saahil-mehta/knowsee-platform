"use client";

import { useEffect, useState } from "react";

const FUNNY_VERBS = [
  "Thinking",
  "Pondering",
  "Ruminating",
  "Contemplating",
  "Calculating",
  "Processing",
  "Analyzing",
  "Synthesizing",
  "Hullabalooing",
  "Whirlpooling",
  "Pontificating",
  "Gesticulating",
  "Bamboozling",
  "Discombobulating",
  "Kerfuffling",
  "Shenaniganizing",
  "Gobbledygooking",
  "Lollygagging",
  "Skedaddling",
  "Canoodling",
  "Flibbertigibbetting",
  "Mollycoddling",
  "Snollygostering",
  "Cattywampusing",
  "Brouhaharing",
  "Malarkeying",
  "Nincompooping",
  "Skullduggerying",
  "Hornswoggling",
  "Codswalloping",
  "Transmogrifying",
  "Hydroplaning",
  "Moonwalking",
  "Bushwhacking",
  "Spelunking",
  "Gallivanting",
  "Meandering",
  "Perspicating",
  "Bloviating",
  "Fulsominating",
  "Cacophonizing",
  "Zigzagging",
  "Flummoxing",
  "Hoodwinking",
  "Defenestrating",
  "Peregrinating",
  "Ululating",
  "Vociferating",
  "Masticating",
  "Gestating",
  "Fabricating",
  "Orchestrating",
  "Extrapolating",
  "Interpolating",
  "Triangulating",
  "Quantifying",
  "Qualifying",
  "Iterating",
  "Ideating",
  "Brainstorming",
  "Envisioning",
  "Manifesting",
  "Dreaming",
  "Scheming",
  "Plotting",
  "Conspiring",
  "Brewing",
  "Cooking",
  "Baking",
  "Simulating",
  "Emulating",
  "Rendering",
  "Compiling",
  "Transpiling",
  "Debugging",
  "Refactoring",
];

export function TypingIndicator() {
  const [verb, setVerb] = useState(() => FUNNY_VERBS[Math.floor(Math.random() * FUNNY_VERBS.length)]);
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const interval = setInterval(() => {
      setIsVisible(false);
      setTimeout(() => {
        setVerb((prev) => {
          const currentIndex = FUNNY_VERBS.indexOf(prev);
          let nextIndex = Math.floor(Math.random() * FUNNY_VERBS.length);
          // Avoid repeating the same verb immediately
          while (nextIndex === currentIndex) {
            nextIndex = Math.floor(Math.random() * FUNNY_VERBS.length);
          }
          return FUNNY_VERBS[nextIndex];
        });
        setIsVisible(true);
      }, 200); // Wait for fade out
    }, 1500); // Change every 1.5 seconds

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex justify-start py-2">
      <div className="inline-flex items-center gap-3 rounded-2xl bg-muted/30 px-4 py-2 text-sm text-muted-foreground/80">
        <span className="flex gap-1">
          <span className="h-1.5 w-1.5 rounded-full bg-foreground/40 animate-pulse [animation-delay:-0.3s]" />
          <span className="h-1.5 w-1.5 rounded-full bg-foreground/40 animate-pulse [animation-delay:-0.15s]" />
          <span className="h-1.5 w-1.5 rounded-full bg-foreground/40 animate-pulse" />
        </span>
        <span
          className={`font-sans font-medium tracking-wide transition-opacity duration-200 ${isVisible ? "opacity-100" : "opacity-0"
            }`}
        >
          {verb}...
        </span>
      </div>
    </div>
  );
}
