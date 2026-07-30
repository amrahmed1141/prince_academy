# Documentation templates

Skeletons for human docs under [`docs/`](../). Agent work-type packs live under [`ai/templates/`](../../ai/templates/); prompt/workflow skeletons remain under [`ai/prompts/_template.md`](../../ai/prompts/_template.md) and [`ai/workflows/_template.md`](../../ai/workflows/_template.md).

| Template | Creates | Notes |
|----------|---------|-------|
| [`doc-page.md`](doc-page.md) | A page in architecture, database, product, security, or operations | Cite sources; no invented conventions |
| [`adr.md`](adr.md) | `docs/decisions/NNNN-short-title.md` | Append-only; supersede instead of editing Accepted ADRs |

## Conventions shared by both

- Prefer linking over copying facts that already live in code, SQL, or another doc.
- Front-matter fields (`Owner`, `Last reviewed`, `Status`) are mandatory on doc pages; ADR status is mandatory on decisions.
- Update the owning folder’s `README.md` index in the same change.
- Docs-only work does not touch `lib/`.
