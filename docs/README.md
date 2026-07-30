# Documentation

Human documentation for Prince Academy. Agent procedures, prompts, and memory live under [`ai/`](../ai/). The agent contract is [`AGENTS.md`](../AGENTS.md).

When code and docs disagree, **code and `supabase/*.sql` win**. Update the owning doc in the same change when you notice drift.

## Precedence (tiebreaker)

Source → SQL → decisions / `ai/memory` → docs / context packs → prompts / workflows → tool adapters (`.cursor/`) → indexes

## Folder map

| Folder | Answers | Primary consumers |
|--------|---------|-------------------|
| [`architecture/`](architecture/) | How the Flutter system is structured and why each layer exists | Flutter developers, reviewers, agents needing structure |
| [`database/`](database/) | What the schema, RPCs, views, and storage mean | Backend/Flutter developers writing queries or RPCs |
| [`product/`](product/) | What the product does for members, coaches, and admins | Product, QA, support, developers checking intended behaviour |
| [`security/`](security/) | Trust boundaries and what protects them | Reviewers, release security checks, anyone touching auth/RLS |
| [`operations/`](operations/) | How to set up, ship, and run the system | Release owners, onboarding, incident responders |
| [`decisions/`](decisions/) | Why a consequential choice was made (ADRs) | Anyone about to relitigate a settled constraint |
| [`generated/`](generated/) | Machine-written inventories only | Tooling and agents; do not hand-edit |

## Templates

Reusable skeletons (real conventions, not invent-and-fill stubs):

| Template | Use when |
|----------|----------|
| [`_templates/doc-page.md`](_templates/doc-page.md) | Adding a page under architecture, database, product, security, or operations |
| [`_templates/adr.md`](_templates/adr.md) | Recording a new Architecture Decision Record under `decisions/` |

## Legacy flat files (pending migration)

These remain at `docs/` root until moved into the folders above. Prefer the destination column for new links.

| File | Destination |
|------|-------------|
| [`architecture-overview.md`](architecture-overview.md) | `architecture/overview.md` |
| [`caching-and-sync.md`](caching-and-sync.md) | `architecture/caching-and-sync.md` |
| [`feature-playbook.md`](feature-playbook.md) | `architecture/feature-playbook.md` (or fold into [`ai/workflows/feature-development.md`](../ai/workflows/feature-development.md)) |
| [`ui-theme-guide.md`](ui-theme-guide.md) | `architecture/ui-theme.md` |
| [`supabase-schema-and-rpc.md`](supabase-schema-and-rpc.md) | split → `database/schema.md` + `database/rpc-catalogue.md` |
| [`auth-and-roles.md`](auth-and-roles.md) | split → `security/` (enforcement) + `product/` (capabilities) |
| [`security-notes.md`](security-notes.md) | `security/overview.md` |
| [`environment-setup.md`](environment-setup.md) | `operations/environment-setup.md` |
| [`deprecation-list.md`](deprecation-list.md) | `operations/deprecations.md` |
| [`testing-guide.md`](testing-guide.md) | `operations/testing.md` (keep [`ai/standards/testing.md`](../ai/standards/testing.md) as the agent-facing twin) |

## Writing rules

1. **One home per fact.** Link from other folders; do not copy.
2. **Owner + last-reviewed** on every page (see the doc-page template).
3. **Cite sources.** Database pages name the `supabase/*.sql` file; architecture pages name the feature path under `lib/features/`.
4. **Kebab-case filenames**, topic-first (`booking-lifecycle.md`). ADRs are `NNNN-short-title.md`.
5. **Docs-only changes must not touch `lib/`.**

## Related surfaces

| Surface | Role |
|---------|------|
| [`AGENTS.md`](../AGENTS.md) | Non-negotiable agent contract |
| [`ai/`](../ai/) | Agent workflows, context packs, memory, standards |
| [`examples/`](../examples/) | Copyable code patterns |
| [`.cursor/rules/`](../.cursor/rules/) | Editor/agent rule adapters |
