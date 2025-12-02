# Claude Code Agents

Specialised sub-agents for the Knowsee Platform. Each agent has focused expertise and constraints.

## Available Agents

| Agent | File | Purpose |
|-------|------|---------|
| Backend Specialist | `.claude/agents/backend-specialist.md` | FastAPI, LangGraph, SQLAlchemy, Python |
| Frontend Specialist | `.claude/agents/frontend-specialist.md` | Next.js, Vercel AI SDK, React, TypeScript |
| Reliability Engineer | `.claude/agents/reliability-engineer.md` | Infrastructure, Terraform, observability |
| Documentation Crawler | `.claude/agents/knowsee-crawler.md` | Audit docs for drift and inconsistencies |
| Documentation Writer | `.claude/agents/knowsee-documenter.md` | Update docs based on crawler findings |

## Usage

Agents are invoked via Claude Code's `/agents` command or by referencing their prompts directly.

## Shared Conventions

All agents follow CLAUDE.md for:
- Code style (Python, TypeScript)
- Commit policy (conventional commits)
- Output policy (UK English, no emojis)
- Tooling (Make targets, not raw commands)
