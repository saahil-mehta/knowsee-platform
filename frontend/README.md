# Knowsee Frontend

Production-ready Next.js interface for the Knowsee RAG agent. Built with shadcn/ui, CopilotKit, and Google ADK, featuring a polished chat experience with dark mode, responsive design, and smooth animations.

## Features

- 🎨 **Modern UI** - shadcn/ui components with OKLCH colour palette and Geist fonts
- 🌓 **Dark Mode** - System-aware theme switching with smooth transitions
- 📱 **Responsive** - Mobile-first design with collapsible sidebar
- ⚡ **Real-time Streaming** - CopilotKit headless integration for agent responses
- 🎭 **Animations** - Motion library for polished micro-interactions
- ♿ **Accessible** - WCAG compliant with keyboard navigation
- 🔧 **Extensible** - Clear component contracts for future features

## Prerequisites

- Node.js 18 or newer
- Access to the Knowsee backend (run locally with `uv run python -m app.api` or via deployed API)
- `npm` (or another Node package manager)

## Quick Start

1. **Install dependencies:**

```bash
npm install
```

2. **Configure backend URL** (optional):

Create `.env.local` to point to your ADK backend:

```bash
NEXT_PUBLIC_AGENT_API_URL=https://your-api-url.example.com/
```

Default: `http://localhost:8000/`

3. **Start development server:**

```bash
npm run dev
```

Open http://localhost:3000 (ensure backend is running)

## Architecture

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Next.js 15 (App Router) |
| **UI Components** | shadcn/ui (Radix UI primitives) |
| **Styling** | Tailwind CSS v4 with OKLCH colours |
| **Fonts** | Geist Sans & Geist Mono |
| **Animations** | Motion library |
| **Agent Integration** | CopilotKit + AG-UI Client |
| **State Management** | React Context + CopilotKit hooks |
| **Theme** | next-themes |

### System Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Next.js Frontend (UI Layer)                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ shadcn/ui Components                                  │  │
│  │ (Button, Card, Textarea, Avatar, Sidebar, etc.)      │  │
│  └─────────────────┬─────────────────────────────────────┘  │
│                    │ Props & Composition                    │
│  ┌─────────────────▼─────────────────────────────────────┐  │
│  │ Custom Chat Components                                │  │
│  │ - AppShell (layout wrapper)                           │  │
│  │ - AppSidebar (navigation, chat history)               │  │
│  │ - ChatContainer (auto-scroll messages)                │  │
│  │ - MessageBubble (user/assistant display)              │  │
│  │ - Composer (input with auto-resize)                   │  │
│  │ - ThemeToggle (dark/light mode)                       │  │
│  └─────────────────┬─────────────────────────────────────┘  │
│                    │ Hooks & State                          │
│  ┌─────────────────▼─────────────────────────────────────┐  │
│  │ CopilotKit Headless Hooks                             │  │
│  │ - useCopilotChat (messages, actions, loading)         │  │
│  │ - useCopilotAction (tool rendering, generative UI)    │  │
│  │ - appendMessage, stopGeneration, reloadMessages       │  │
│  └─────────────────┬─────────────────────────────────────┘  │
│                    │ WebSocket/SSE Streaming                │
└────────────────────┼─────────────────────────────────────────┘
                     │
                     │ Runtime API
                     │
┌────────────────────▼─────────────────────────────────────────┐
│ CopilotKit Runtime (/api/copilotkit/route.ts)               │
│ - Handles streaming responses                                │
│ - Routes requests to AG-UI HttpAgent                         │
│ - Manages connection lifecycle                               │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ HTTP Protocol
                     │
┌────────────────────▼─────────────────────────────────────────┐
│ AG-UI Client (@ag-ui/client)                                 │
│ - Protocol bridge for Google ADK                             │
│ - Serialises/deserialises agent messages                     │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ Agent API (HTTP)
                     │
┌────────────────────▼─────────────────────────────────────────┐
│ Google ADK Backend (FastAPI/Python)                          │
│ - Agent logic and orchestration                              │
│ - Tool execution (search, retrieval, analysis)               │
│ - Session management and state persistence                   │
│ - RAG integration with knowledge base                        │
└───────────────────────────────────────────────────────────────┘
```

## Component Contracts

### Core Components

#### **AppShell**
**Purpose:** Layout wrapper providing header and main content area.

**Props:**
```typescript
interface AppShellProps {
  children: React.ReactNode
}
```

**Usage:**
```tsx
<AppShell>
  <YourChatInterface />
</AppShell>
```

**Extension Points:**
- Add toolbar actions to header
- Inject breadcrumbs or session metadata
- Add floating action buttons

---

#### **AppSidebar**
**Purpose:** Collapsible navigation with chat history and theme toggle.

**Features:**
- Responsive (Sheet on mobile, resizable sidebar on desktop)
- Chat history list (TODO: wire to ADK sessions API)
- Theme toggle dropdown
- New chat button

**Extension Points:**
- Implement chat history fetching from ADK
- Add search/filter for chat history
- Add user profile section
- Add settings/preferences link

---

#### **ChatContainer**
**Purpose:** Auto-scrolling message container with scroll-to-bottom button.

**Components:**
- `ChatContainer.Root` - Main container with scroll logic
- `ChatContainer.Content` - Message list wrapper
- `ChatContainer.ScrollAnchor` - Scroll target element

**Usage:**
```tsx
<ChatContainer.Root>
  <ChatContainer.Content>
    {messages.map(msg => <MessageBubble ... />)}
    <ChatContainer.ScrollAnchor />
  </ChatContainer.Content>
</ChatContainer.Root>
```

**Styling Decisions:**
- Uses `use-stick-to-bottom` for smart auto-scroll
- Scroll button appears with spring animation when not at bottom
- Preserves scroll position when user scrolls up

---

#### **MessageBubble**
**Purpose:** Display individual chat messages with role-specific styling.

**Props:**
```typescript
interface MessageBubbleProps {
  children: React.ReactNode
  role: "user" | "assistant"
  className?: string
}
```

**Sub-components:**
- `MessageAvatar` - User/assistant avatar with role icons
- `MessageContent` - Markdown-rendered message text
- `MessageActions` - Copy and regenerate buttons

**Animations:**
- Fade-in with upward slide (Motion library)
- Hover state reveals action buttons

**Extension Points:**
- Add feedback buttons (thumbs up/down)
- Add tool call cards for ADK actions
- Add streaming indicator for partial messages
- Add syntax highlighting for code blocks (Shiki)

---

#### **Composer**
**Purpose:** Multi-line input with auto-resize and send/stop controls.

**Props:**
```typescript
interface ComposerProps {
  value: string
  onChange: (value: string) => void
  onSubmit: () => void
  onStop?: () => void
  isLoading?: boolean
  disabled?: boolean
  placeholder?: string
  maxHeight?: number  // Default: 240px
  className?: string
}
```

**Features:**
- Auto-resizing textarea (max 240px height)
- Enter to send, Shift+Enter for new line
- Send button (disabled when empty or loading)
- Stop button (appears during streaming)
- Attachment button placeholder

**Extension Points:**
- Implement file upload functionality
- Add command palette (Cmd+K)
- Add prompt suggestions
- Add voice input

---

### Provider Contracts

#### **ThemeProvider**
**Purpose:** System-aware dark/light mode management.

**Props:**
```typescript
{
  attribute: "class",
  defaultTheme: "system",
  enableSystem: true,
  disableTransitionOnChange: false
}
```

**Usage:**
```tsx
import { useTheme } from "next-themes"

const { theme, setTheme } = useTheme()
setTheme("dark") // "light" | "dark" | "system"
```

---

#### **ChatSessionsProvider**
**Purpose:** Manage chat history and session switching.

**API:**
```typescript
interface ChatSessionsContextValue {
  sessions: ChatSession[]
  activeSessionId: string | null
  createSession: () => Promise<string>
  switchSession: (sessionId: string) => void
  deleteSession: (sessionId: string) => void
  updateSessionTitle: (sessionId: string, title: string) => void
}
```

**TODO:**
- Implement ADK sessions API integration
- Fetch chat history on mount
- Persist active session in localStorage
- Add optimistic UI updates

---

## CopilotKit Integration

### Headless Hooks

The app uses **CopilotKit headless hooks** instead of pre-built components for full UI control:

```typescript
const {
  visibleMessages,      // Array of chat messages
  appendMessage,        // Send user message
  stopGeneration,       // Cancel streaming
  reloadMessages,       // Regenerate response
  isLoading,           // Streaming state
} = useCopilotChat()
```

### Adding Tool Renderers

Use `useCopilotAction` to render custom UI for ADK tool calls:

```typescript
useCopilotAction({
  name: "search_knowledge_base",
  description: "Search the knowledge base",
  render: ({ status, args, result }) => {
    if (status === "inProgress") {
      return <SearchingIndicator query={args.query} />
    }
    return <SearchResults results={result} />
  },
})
```

---

## Styling System

### OKLCH Colour Palette

Modern colour system using OKLCH for perceptual uniformity:

```css
/* Light Mode */
--primary: oklch(0.21 0.006 285.885);       /* Deep purple-tinted */
--background: oklch(1 0 0);                 /* Pure white */
--foreground: oklch(0.141 0.005 285.823);   /* Rich black */

/* Dark Mode */
--primary: oklch(0.985 0 0);                /* Near white */
--background: oklch(21.34% 0 0);            /* Deep black */
--accent: oklch(0.488 0.243 264.376);       /* Vibrant purple */
```

### Custom CSS Variables

```css
--spacing-app-header: 56px;           /* Fixed header height */
--spacing-input-area: 134px;          /* Composer area height */
--spacing-scroll-area: calc(...);     /* Dynamic content height */

--font-sans: var(--font-geist-sans);  /* Body text */
--font-mono: var(--font-geist-mono);  /* Code blocks */

--radius-sm: calc(var(--radius) - 4px);  /* Small radius */
--radius-lg: var(--radius);               /* Default radius */
--radius-xl: calc(var(--radius) + 4px);  /* Large radius */
```

### Glassmorphism Utility

```css
.glass {
  background: oklch(from var(--background) l c h / 0.8);
  backdrop-filter: blur(12px);
}
```

---

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server (http://localhost:3000) |
| `npm run build` | Create production bundle |
| `npm run start` | Serve production build |
| `npm run lint` | Run ESLint checks |

---

## Project Structure

```
frontend/
├── src/
│   ├── app/
│   │   ├── api/copilotkit/route.ts    # CopilotKit runtime endpoint
│   │   ├── layout.tsx                  # Root layout with providers
│   │   ├── page.tsx                    # Main chat interface
│   │   └── globals.css                 # Global styles + CSS variables
│   ├── components/
│   │   ├── ui/                         # shadcn/ui components
│   │   ├── providers/                  # React context providers
│   │   ├── app-shell.tsx               # Layout wrapper
│   │   ├── app-sidebar.tsx             # Navigation sidebar
│   │   ├── chat-container.tsx          # Auto-scroll container
│   │   ├── message.tsx                 # Message display components
│   │   ├── composer.tsx                # Input area
│   │   └── theme-toggle.tsx            # Theme switcher
│   ├── hooks/
│   │   └── use-mobile.ts               # Responsive breakpoint hook
│   └── lib/
│       └── utils.ts                    # Utility functions (cn, etc.)
├── public/                             # Static assets
├── components.json                     # shadcn/ui configuration
├── tailwind.config.ts                  # Tailwind CSS config
├── tsconfig.json                       # TypeScript config
└── package.json                        # Dependencies
```

---

## Troubleshooting

### Backend Connection Issues

**Problem:** Chat stalls or shows connection errors.

**Solution:**
1. Verify backend is running: `curl http://localhost:8000/health`
2. Check `NEXT_PUBLIC_AGENT_API_URL` in `.env.local`
3. Review FastAPI logs for authentication/quota errors

### Styling Issues

**Problem:** Dark mode colours look incorrect.

**Solution:**
- Ensure `next-themes` is configured with `attribute="class"`
- Check browser supports OKLCH colours (use fallback for Safari < 16.4)
- Verify `suppressHydrationWarning` on `<html>` tag

### Build Errors

**Problem:** TypeScript errors in production build.

**Solution:**
```bash
rm -rf .next node_modules
npm install
npm run build
```

---

## Extension Guide

### Adding a New Feature

1. **Create component** in `src/components/`
2. **Import shadcn primitives** if needed
3. **Wire to CopilotKit hooks** for agent integration
4. **Add Motion animations** for polish
5. **Update this README** with component contract

### Integrating ADK Sessions API

1. Update `ChatSessionsProvider` to fetch from backend:
   ```typescript
   const sessions = await fetch('/api/sessions').then(r => r.json())
   ```

2. Modify `AppSidebar` to display fetched sessions

3. Implement session switching in `page.tsx`

---

## Contributing

When adding components:

1. **Follow shadcn/ui patterns** - Use Radix primitives, not custom implementations
2. **Add prop types** - Fully type all component interfaces
3. **Document extension points** - Add JSDoc comments for key props
4. **Use OKLCH colours** - Extend the existing palette, don't add arbitrary hex values
5. **Maintain accessibility** - Add ARIA labels, keyboard navigation, focus states

---

## Licence

See root LICENSE file.
