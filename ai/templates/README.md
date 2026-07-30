# Work-type templates

Reusable packs for agent and human workflows. Tool-independent; Cursor adapters live under `.cursor/`.

## How to use

1. Read [`_base.md`](_base.md) for the shared section contract.
2. Open the pack for the work type below.
3. Load the matching prompt under [`../prompts/`](../prompts/) and workflow under [`../workflows/`](../workflows/).
4. Map **Primary roles** to the active agent roster.
5. Load only the context documents listed by the pack.

## Packs

| Pack | File | Prompt | Workflow | Owner role (logical) |
|------|------|--------|----------|----------------------|
| Feature | [`feature.md`](feature.md) | `feature-planning` | `feature-development` | Architect → Implementer |
| Bug Fix | [`bug-fix.md`](bug-fix.md) | `bug-fix` | `bug-fix` (`hot-fix` variant) | Implementer |
| SQL Change | [`sql-change.md`](sql-change.md) | `sql` | `database-change` | Database |
| Review | [`review.md`](review.md) | `code-review` (+ lenses) | embedded / reviewer stage | Reviewer |
| Release | [`release.md`](release.md) | `release` | `release` | Release |
| Documentation | [`documentation.md`](documentation.md) | `documentation` | (prompt-led stages) | Documentation |

## Composition

```text
Request → select pack → apply _base + pack
       → bind roles → load listed context only
       → run stages → emit output schema → pass gates → DoD
```

Review and Release **consume** the output schema of Feature, Bug Fix, and SQL Change. Do not invent a parallel report format.

## Status legend

| Status | Meaning |
|--------|---------|
| `active` | Safe to route production work through this pack |
| `draft` | Structure complete; refine after real runs |
| `empty` | Placeholder only |

## Adding a pack

1. Copy [`_base.md`](_base.md) sections into `ai/templates/<name>.md`.
2. Add prompt + workflow files from their `_template.md` skeletons.
3. Register rows in this README and in `prompts/INDEX.md` / `workflows/INDEX.md`.
