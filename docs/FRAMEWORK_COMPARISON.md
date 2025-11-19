# Framework Comparison: ADK vs Alternatives

This document captures the strategic decision to use Google ADK and the trade-offs involved with alternative frameworks. Reference this when clients or stakeholders ask about multi-cloud deployment or alternative AI frameworks.

## Executive Summary

ADK provides managed session/memory infrastructure that would require 3-6 months to build with alternatives. The GCP lock-in is a deliberate trade-off for reduced engineering overhead and robust enterprise features.

## Framework Comparison Matrix

| Aspect | ADK (Current) | LangChain/LangGraph | Vercel AI SDK | OpenAI Agents SDK |
|--------|---------------|---------------------|---------------|-------------------|
| **Session Management** | Agent Engines (managed) | Build yourself | Build yourself | Threads API (OpenAI) |
| **Memory** | Built-in, persistent | Build yourself | Build yourself | Built-in (OpenAI) |
| **Streaming** | Native | Native | Excellent | Native |
| **Multi-agent** | Native | LangGraph (complex) | Limited | Native |
| **Tool execution** | Robust | Robust | Basic | Robust |
| **Observability** | Cloud Trace | LangSmith ($$$) | None built-in | OpenAI dashboard |
| **Deployment** | Cloud Run | Anywhere | Vercel-optimised | Anywhere |
| **Lock-in** | GCP | None (but DIY hell) | Vercel + provider | OpenAI |

## The Core Problem: Sessions and Memory

Session and memory management is the critical differentiator. Here's what "build yourself" means:

### LangChain/LangGraph

```python
# You need to build:
# - Session store (Redis/Postgres/DynamoDB)
# - Conversation history management
# - State serialisation/deserialisation
# - Memory pruning strategies
# - Multi-turn context windows
# - Checkpointing for long-running agents
```

LangGraph has `checkpointers` but they're low-level primitives. You're essentially building Agent Engines yourself.

### Vercel AI SDK

```typescript
// Streaming is excellent, but:
// - No built-in persistence
// - No session management
// - No memory abstraction
// - You implement everything in your database
```

Good for simple chatbots, not suitable for stateful agents.

### OpenAI Agents SDK

```python
# Swarm/Assistants API provides:
# - Threads (sessions)
# - Built-in memory
# - File handling

# But:
# - OpenAI only (no Gemini, Claude, Llama)
# - Their pricing controls you
# - Data residency concerns for EU clients
```

Different lock-in, arguably worse (single LLM vendor with less competitive pricing).

## Current GCP Dependencies

| Component | GCP Service | Azure Equivalent | Portability Effort |
|-----------|-------------|------------------|---------------------|
| LLM | Gemini (Vertex AI) | Azure OpenAI | Code changes required |
| RAG/Search | Discovery Engine | Azure AI Search | Significant rework |
| Compute | Cloud Run | Container Apps | Configuration only |
| Storage | Cloud Storage | Blob Storage | Configuration only |
| Sessions | Agent Engines | Custom build | Major rework (months) |
| Auth (IAP) | Identity-Aware Proxy | Azure AD / Front Door | Complete replacement |

## Why ADK is the Pragmatic Choice

1. **Session/Memory solved** - Agent Engines handles the hard distributed state problem
2. **Gemini pricing** - Genuinely cheaper than OpenAI at scale
3. **Vertex AI ecosystem** - Search, Ranking, Embeddings all integrated
4. **Enterprise features** - Data residency, VPC-SC, audit logging out of the box

## Cost of Portability

Building a truly cloud-agnostic solution requires:

- **3-6 months** building session infrastructure
- **Ongoing maintenance** of that infrastructure
- **Integration work** with your choice of vector DB / search
- **Custom observability** pipeline

This is engineering time not spent on product features.

## Multi-Cloud Client Scenarios

### If a client demands Azure/AWS:

**Option A: Different pricing tier**
- Quote it as a separate product
- Scope the rebuild properly (it's not trivial)
- Charge for the infrastructure development

**Option B: Cloud-agnostic LLM gateway**
- Use LiteLLM for model abstraction
- Still need their session infrastructure
- Partial portability only

**Option C: Self-hosted everything**
- Postgres + Redis + custom session management
- Significant ongoing overhead
- Suitable for air-gapped/on-premise requirements

## Authentication Considerations

If multi-cloud is a genuine requirement, avoid GCP-specific auth:

| Option | Cloud-Agnostic | Complexity | Best For |
|--------|----------------|------------|----------|
| **IAP** | No (GCP only) | Low | Internal tools, GCP commitment |
| **Auth0/Okta** | Yes | Medium | SaaS products, enterprise clients |
| **Keycloak** | Yes | High | Self-hosted, full control |
| **NextAuth.js** | Yes | Medium | App-level, database-backed |

## Recommendation

**For GCP clients:** Commit to ADK. The lock-in trade-off is worth the reduced complexity.

**For multi-cloud aspirations:**
1. Keep LLM calls behind an abstraction (LangChain for retrieval already helps)
2. Document what Agent Engines provides
3. If/when Azure client appears, scope the rebuild as a separate engagement

**Do not pre-optimise for portability** - you'll spend months building what GCP provides for free, and the alternative cloud client may never materialise.

## When to Consider LangGraph

The only scenarios where LangGraph makes sense:

- On-premise deployment required
- Air-gapped environments
- Client explicitly prohibits cloud vendors
- You have 3+ months to build session infrastructure

## References

- [Google ADK Documentation](https://google.github.io/adk-docs/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [Vercel AI SDK](https://sdk.vercel.ai/docs)
- [OpenAI Assistants API](https://platform.openai.com/docs/assistants)

---

*Last updated: November 2025*
*Decision owner: Engineering*
