# Frontend Roadmap (Onyx-Inspired)

This roadmap adapts the feature surface from the Onyx reference project to Knowsee's simpler footprint. Each phase is scoped to be incremental and shippable.

## Phase 1 – Conversation Essentials (In Progress)

- ✅ Persistent conversation store backed by Zustand + localStorage
- ✅ Sidebar for switching, creating, and deleting conversations
- ☐ Conversation title editing inline
- ☐ Empty-state polish and keyboard shortcuts cheat sheet

## Phase 2 – Assistant Quality of Life

- ☐ Draft/stream indicators for pending responses (progress dots, cancel button)
- ☐ Message actions (copy, regenerate, delete)
- ☐ Client-side markdown rendering parity with Onyx (tables, code blocks, callouts)
- ☐ Centralized theme primitives (`src/theme`) to support multi-brand skins

## Phase 3 – Knowledge & Files

- ☐ File attachment UX (drop zone, upload status)
- ☐ Document preview panel and message attachments list
- ☐ Pluggable knowledge providers abstraction mirroring Onyx connectors

## Phase 4 – Agents & Workflows

- ☐ Agent selection surface (left rail) with per-agent system prompts
- ☐ Settings modal to manage default model, temperature, and feature toggles
- ☐ Conversation export/share flows

Each phase should ship with:

1. Updated Playwright coverage for the new UI affordances
2. Documentation updates in `web/docs/` describing the feature and operator workflows
3. Backward-compatible API contracts so the mock server continues to serve the UI without changes
