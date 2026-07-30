# AI Platform Structure

Full folder tree and purpose map for the AI / agent / docs layer added to this repository.

Entry points: [`AGENTS.md`](AGENTS.md) · [`README_AI.md`](README_AI.md)

---

## Tree

```text
prince_academy/
├── AGENTS.md
├── README_AI.md
├── AI_STRUCTURE.md          ← this file
│
├── agents/                  # Agent role definitions
│   ├── INDEX.md
│   ├── orchestrator.md
│   ├── architect.md
│   ├── flutter-developer.md
│   ├── database.md
│   ├── reviewer.md
│   ├── qa.md
│   ├── security.md
│   ├── performance.md
│   ├── release.md
│   └── documentation.md
│
├── ai/                      # Tool-independent AI operating layer
│   ├── README.md
│   │
│   ├── templates/           # Work-type packs (process)
│   │   ├── README.md
│   │   ├── _base.md
│   │   ├── feature.md
│   │   ├── bug-fix.md
│   │   ├── sql-change.md
│   │   ├── review.md
│   │   ├── release.md
│   │   └── documentation.md
│   │
│   ├── prompts/             # Reusable prompt templates
│   │   ├── INDEX.md
│   │   ├── _template.md
│   │   ├── feature-planning.md
│   │   ├── bug-fix.md
│   │   ├── code-review.md
│   │   ├── architecture-review.md
│   │   ├── performance-review.md
│   │   ├── sql.md
│   │   ├── release.md
│   │   └── documentation.md
│   │
│   ├── context/             # Domain context packs (load only what you need)
│   │   ├── INDEX.md
│   │   ├── _template.md
│   │   ├── architecture.md
│   │   ├── authentication.md
│   │   ├── supabase.md
│   │   ├── booking.md
│   │   ├── attendance.md
│   │   ├── subscriptions.md
│   │   ├── payments.md
│   │   ├── notifications.md
│   │   └── admin-dashboard.md
│   │
│   ├── workflows/           # Multi-step agent workflows
│   │   ├── INDEX.md
│   │   ├── _template.md
│   │   ├── feature-development.md
│   │   ├── bug-fix.md
│   │   ├── hot-fix.md
│   │   ├── database-change.md
│   │   ├── refactoring.md
│   │   ├── performance-optimisation.md
│   │   └── release.md
│   │
│   ├── memory/              # Long-term project memory
│   │   ├── INDEX.md
│   │   ├── architecture.md
│   │   ├── business-rules.md
│   │   ├── coding-decisions.md
│   │   ├── known-pitfalls.md
│   │   ├── lessons-learned.md
│   │   └── project-history.md
│   │
│   └── standards/           # Coding / architecture standards
│       ├── INDEX.md
│       ├── flutter.md
│       ├── bloc.md
│       ├── models.md
│       ├── repository.md
│       ├── supabase.md
│       ├── testing.md
│       └── ui.md
│
├── docs/                    # Human-facing documentation
│   ├── README.md
│   ├── architecture-overview.md
│   ├── auth-and-roles.md
│   ├── caching-and-sync.md
│   ├── environment-setup.md
│   ├── feature-playbook.md
│   ├── security-notes.md
│   ├── supabase-schema-and-rpc.md
│   ├── testing-guide.md
│   ├── ui-theme-guide.md
│   ├── deprecation-list.md
│   │
│   ├── _templates/
│   │   ├── README.md
│   │   ├── doc-page.md
│   │   └── adr.md
│   │
│   ├── architecture/
│   │   └── README.md
│   ├── database/
│   │   └── README.md
│   ├── product/
│   │   └── README.md
│   ├── security/
│   │   └── README.md
│   ├── operations/
│   │   └── README.md
│   ├── decisions/
│   │   └── README.md
│   ├── generated/
│   │   └── README.md
│   └── tasks/
│       └── task_002_admin_dashboard_navigation.md
│
├── examples/                # Gold-pattern excerpts (copy from real features)
│   ├── README.md
│   ├── cubit/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── repository/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── supabase_repository/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── rpc/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── screen/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── widget/
│   │   ├── README.md
│   │   └── excerpt.md
│   ├── navigation/
│   │   └── README.md
│   └── tests/
│       ├── README.md
│       └── excerpt.md
│
└── .cursor/                 # Cursor-specific adapters
    ├── agents/
    │   └── README.md
    ├── skills/
    │   └── README.md
    └── rules/
        ├── core/
        │   ├── 00-platform-contract.mdc
        │   ├── 01-change-discipline.mdc
        │   └── 02-definition-of-done.mdc
        ├── flutter/
        │   ├── dependency-injection.mdc
        │   ├── error-observability.mdc
        │   ├── feature-layout.mdc
        │   ├── models-mapping.mdc
        │   ├── naming-imports.mdc
        │   ├── navigation-shell.mdc
        │   ├── state-management.mdc
        │   └── ui-theme-accessibility.mdc
        ├── data/
        │   ├── auth-boundary.mdc
        │   ├── caching-sync.mdc
        │   ├── repository-boundary.mdc
        │   ├── secrets-config.mdc
        │   └── supabase-sql.mdc
        ├── product/
        │   ├── academy-domain.mdc
        │   ├── admin-operations.mdc
        │   ├── deprecations.mdc
        │   └── fcm-notifications.mdc
        └── quality/
            ├── documentation.mdc
            ├── generated-files.mdc
            ├── performance.mdc
            ├── review.mdc
            └── testing.mdc
```

---

## What each area does

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Short contract for all AI agents (stack, non-negotiables, gold standards) |
| `README_AI.md` | Load order + map of the AI platform |
| `agents/` | Role playbooks (who does what: orchestrator, flutter-dev, DB, QA, …) |
| `ai/templates/` | Work-type packs: Feature, Bug Fix, SQL, Review, Release, Docs |
| `ai/prompts/` | Copy-paste / reusable prompts bound to those packs |
| `ai/context/` | Domain summaries (auth, booking, supabase, …) — load only what the task needs |
| `ai/workflows/` | Step-by-step flows (feature, hot-fix, DB change, release, …) |
| `ai/memory/` | Durable decisions, pitfalls, lessons, history |
| `ai/standards/` | How we write Flutter, BLoC, models, repos, SQL, tests, UI |
| `docs/` | Human docs (architecture, auth, caching, schema, testing, …) |
| `docs/_templates/` | Templates for new doc pages and ADRs |
| `docs/{architecture,database,product,security,operations,decisions}/` | Topic folders (indexes ready; pages migrate over time) |
| `docs/generated/` | Machine-generated output only — do not hand-edit |
| `docs/tasks/` | Task briefs / implementation notes |
| `examples/` | Short excerpts pointing at gold-standard patterns in `lib/` |
| `.cursor/rules/` | Cursor rule adapters (core / flutter / data / product / quality) |
| `.cursor/agents/` · `.cursor/skills/` | Cursor-local stubs / pointers |

---

## How to use (load order)

1. Read [`AGENTS.md`](AGENTS.md)
2. Pick a role under [`agents/`](agents/) → see [`agents/INDEX.md`](agents/INDEX.md)
3. Open the matching pack in [`ai/templates/`](ai/templates/)
4. Follow the matching [`ai/workflows/`](ai/workflows/)
5. Use the matching [`ai/prompts/`](ai/prompts/)
6. Load only needed packs from [`ai/context/`](ai/context/)
7. Copy patterns from [`examples/`](examples/) + gold features (`lib/features/auth`, `booking`, `sessions`)
8. Check [`ai/memory/`](ai/memory/) when relevant

**Precedence:** source code > SQL > decisions/memory > docs/context packs > prompts/workflows > `.cursor/` adapters > indexes

---

## Quick file index

### Agents (`agents/`)

| File | Role |
|------|------|
| `orchestrator.md` | Routes work, picks packs/workflows |
| `architect.md` | Boundaries, stack, ADRs |
| `flutter-developer.md` | Feature / UI / BLoC implementation |
| `database.md` | Schema, RPCs, RLS |
| `reviewer.md` | Diff review vs platform contract |
| `qa.md` | Test plan and verification |
| `security.md` | Auth, secrets, RLS threat model |
| `performance.md` | Cache, query cost, rebuilds |
| `release.md` | Ship checklist / release notes |
| `documentation.md` | Docs, context, memory updates |

### Work-type templates (`ai/templates/`)

| File | When |
|------|------|
| `feature.md` | New feature |
| `bug-fix.md` | Bug fix |
| `sql-change.md` | Schema / RPC / RLS |
| `review.md` | Code / architecture review |
| `release.md` | Release |
| `documentation.md` | Docs-only task |

### Context packs (`ai/context/`)

| File | Domain |
|------|--------|
| `architecture.md` | Overall app architecture |
| `authentication.md` | Auth + roles |
| `supabase.md` | Client, schema, RPCs |
| `booking.md` | Booking / sessions booking |
| `attendance.md` | Attendance |
| `subscriptions.md` | Subscriptions |
| `payments.md` | Payments |
| `notifications.md` | FCM / notifications |
| `admin-dashboard.md` | Admin dashboard |

### Workflows (`ai/workflows/`)

| File | Flow |
|------|------|
| `feature-development.md` | Full feature path |
| `bug-fix.md` | Diagnose → fix → verify |
| `hot-fix.md` | Urgent production fix |
| `database-change.md` | SQL / RPC change |
| `refactoring.md` | Scoped refactor |
| `performance-optimisation.md` | Perf pass |
| `release.md` | Release path |

### Cursor rules (`.cursor/rules/`)

| Group | Focus |
|-------|--------|
| `core/` | Platform contract, change discipline, definition of done |
| `flutter/` | DI, BLoC, models, navigation, UI, naming, errors |
| `data/` | Auth boundary, repos, cache, secrets, Supabase SQL |
| `product/` | Academy domain, admin ops, FCM, deprecations |
| `quality/` | Docs, generated files, performance, review, testing |

---

## Notes

- `ai/` is tool-independent; `.cursor/` is the Cursor adapter only.
- Context packs are major domains only — do not invent conventions to fill templates.
- Prefer linking to canonical source/docs over duplicating content.
- Docs-only tasks must not touch Flutter source under `lib/`.
