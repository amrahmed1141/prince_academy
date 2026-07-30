# AI Platform Layer

Tool-independent AI operating layer for this repository.

| Folder | Purpose |
|--------|---------|
| `templates/` | Work-type packs (Feature, Bug Fix, SQL Change, Review, Release, Documentation) — see `templates/README.md` |
| `prompts/` | Reusable prompt templates bound to packs |
| `context/` | Major-domain context packs (routing summaries; load only what the task needs — see `context/INDEX.md`) |
| `workflows/` | Multi-step agent workflow definitions bound to packs |
| `memory/` | Long-term project memory |
| `standards/` | Coding / architecture standards |

Cursor adapters live under `.cursor/`. Other AI tools should point here via `AGENTS.md` and `README_AI.md`.

Context packs under `context/` are filled for major domains only. Work-type packs under `templates/` are generic process templates; bind them to project contract and context at runtime. Do not invent product conventions inside packs.
