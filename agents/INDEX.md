# Agents

Specialised AI agent definitions for Prince Academy. Agents collaborate via typed handoffs; they do not duplicate responsibilities.

## Load order

1. [`AGENTS.md`](../AGENTS.md) — non-negotiables and precedence
2. [`README_AI.md`](../README_AI.md) — platform maps
3. This directory — role definition for the active agent
4. Matching pack under [`ai/templates/`](../ai/templates/)
5. Matching [`ai/workflows/`](../ai/workflows/) and [`ai/prompts/`](../ai/prompts/)
6. Only needed [`ai/context/`](../ai/context/) packs
7. [`examples/`](../examples/) + gold-standard features
8. [`ai/memory/`](../ai/memory/) when relevant

## Roster

| Agent | File | Owns |
|-------|------|------|
| Orchestrator | [`orchestrator.md`](orchestrator.md) | Routing, gates, pipeline selection |
| Architect | [`architect.md`](architect.md) | Design, boundaries, ADR-lite |
| Database | [`database.md`](database.md) | Schema, RPC, RLS |
| Flutter Developer | [`flutter-developer.md`](flutter-developer.md) | Feature implementation |
| Reviewer | [`reviewer.md`](reviewer.md) | Contract compliance on the diff |
| Security | [`security.md`](security.md) | Auth, secrets, privileged SQL |
| Performance | [`performance.md`](performance.md) | Cache, query cost, hot paths |
| QA | [`qa.md`](qa.md) | Behaviour evidence |
| Documentation | [`documentation.md`](documentation.md) | Docs and memory truth |
| Release | [`release.md`](release.md) | Go / no-go ship gate |

## Pipelines

See each agent’s **Workflow** and **Handoff**. Default feature path:

`Orchestrator → Architect → Database? → Flutter → [Reviewer ∥ Security? ∥ Performance?] → QA → Documentation → Release`

## Anti-duplication

| Concern | Owner |
|---------|-------|
| Module placement / contracts | Architect |
| SQL / RPC / RLS | Database |
| Flutter code | Flutter Developer |
| Style & architecture compliance | Reviewer |
| Threats & secrets | Security |
| Latency / cache / jank | Performance |
| Test evidence | QA |
| Docs / memory accuracy | Documentation |
| Ship decision | Release |

## Precedence

Source > `supabase/*.sql` > `ai/memory/` > `docs/` + `ai/context/` > `ai/prompts/` + `ai/workflows/` > `.cursor/rules/` > indexes.
See [`AGENTS.md`](../AGENTS.md).
