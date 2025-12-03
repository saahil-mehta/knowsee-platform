/**
 * 100 funny verbs for the thinking animation.
 * Displayed while waiting for AI response to start streaming.
 * Source: refs/funny-verbs.txt
 */
export const THINKING_VERBS = [
  // Chaotic energy
  "Hullabalooing",
  "Kerfuffling",
  "Brouhaha-ing",
  "Skedaddling",
  "Shenaniganizing",
  "Bamboozling",
  "Discombobulating",
  "Flabbergasting",
  "Gobbledygooking",
  "Lollygagging",
  "Balderdashing",
  "Malarkeying",
  "Skullduggerying",
  "Thingamajigging",
  "Doohickying",
  "Whatchamacalliting",
  "Rigmaroling",
  "Hornswoggling",
  "Catawampusing",
  "Hocus-pocusing",

  // Trendy vibes
  "Vibing",
  "Manifesting",
  "Percolating",
  "Marinating",
  "Fermenting",
  "Osmosing",
  "Synthesizing",
  "Synergizing",
  "Curating",
  "Artisanal-ing",
  "Upcycling",
  "Foraging",
  "Kombucha-ing",
  "Sourdoughing",

  // Creative modes
  "Jazz-handing",
  "Improvising",
  "Noodling",
  "Riffing",
  "Moonlighting",
  "Daydreaming",

  // Deep thought
  "Ruminating",
  "Grumbling",
  "Harrumphing",
  "Pontificating",
  "Bloviating",
  "Concocting",
  "Plotting",
  "Scheming",
  "Tinkering",
  "Faffing",
  "Pottering",
  "Pondering",
  "Cogitating",
  "Masticating",
  "Regurgitating",
  "Finagling",
  "Waffling",
  "Dithering",
  "Mumbling",
  "Scowling",

  // Playful motion
  "Frolicking",
  "Gallivanting",
  "Scampering",
  "Squirrel-ing",
  "Badgering",
  "Ferreting",
  "Weaseling",
  "Leapfrogging",
  "Dog-paddling",
  "Cat-napping",
  "Purring",
  "Howling",

  // Nature & metamorphosis
  "Cocooning",
  "Metamorphosing",
  "Hibernating",
  "Molting",
  "Slithering",
  "Burrowing",
  "Pecking",
  "Grazing",

  // Science & chaos
  "Coalescing",
  "Vaporizing",
  "Defenestrating",
  "Quantum-leaping",
  "Teleporting",
  "Pixelating",
  "Glitching",
  "Buffering",
  "Defragging",
  "Recalibrating",

  // Existential
  "Hallucinating",
  "Transcending",
  "Evolving",
  "Combusting",
  "Imploding",
  "Melting",
  "Evaporating",
  "Unraveling",
  "Spiralizing",
  "Doomscrolling",
] as const;

export type ThinkingVerb = (typeof THINKING_VERBS)[number];
