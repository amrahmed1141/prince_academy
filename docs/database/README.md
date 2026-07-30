# Database

Semantic map over `supabase/*.sql`, which is the **schema source of truth**. Scripts are ad-hoc setup/fix files (not a formal `supabase/migrations` history). Apply them deliberately per environment.

**Not here:** threat-model rationale for RLS (that is [`../security/`](../security/)); Flutter repository call sites (cite them from architecture or feature context packs); product lifecycle prose ([`../product/`](../product/)).

## Consumers

Developers writing queries or adding RPCs, reviewers of schema PRs, and anyone debugging which RPC owns a write path.

## Index

| Document | Question it answers | Status |
|----------|---------------------|--------|
| [Schema & RPC catalog (root)](../supabase-schema-and-rpc.md) | Which tables, views, RPCs, and storage buckets exist? | Current — split into `schema.md` + `rpc-catalogue.md` |

## Planned pages (create when content is ready)

| Document | Question it answers |
|----------|---------------------|
| `schema.md` | What do primary tables and relationships mean? |
| `rpc-catalogue.md` | Which RPCs exist, by domain, and which SQL file owns them? |
| `storage.md` | What are the buckets, and how do policies relate to scripts? |
| `indexes-and-performance.md` | What does `performance_indexes.sql` buy us? |

## Primary tables (observed)

| Table | Used for |
|-------|----------|
| `profiles` | User profile, role, FCM token |
| `coaches` | Coach directory / admin management |
| `coach_sessions` | Schedulable sessions |
| `branches` | Locations / maps |
| `bookings` | Member bookings |
| `payments` | Payment verification flows |
| `attendance` | Session attendance |
| `notifications` | In-app notification feed |

## RPC convention

Prefer Supabase RPCs for transactional or multi-step work (booking, payment verify/reject, attendance, privileged aggregates). Call RPCs only from repositories / datasources. Document RLS expectations and whether the function is `SECURITY DEFINER` on the owning SQL file and in the catalogue page.

## SQL inventory under `supabase/`

Scripts are named by concern (`booking_flow.sql`, `attendance_session_management.sql`, `profiles_rls_fix.sql`, `performance_indexes.sql`, storage scripts, and various `fix_*` patches). The catalogue page must map each live behaviour to a file; do not treat filenames alone as the mental model.

## Related

- Security (RLS intent / DEFINER risk): [`../security/`](../security/)
- Agent context: [`ai/context/supabase.md`](../../ai/context/supabase.md)
- Workflow: [`ai/workflows/database-change.md`](../../ai/workflows/database-change.md)
- Rule: [`.cursor/rules/data/supabase-sql.mdc`](../../.cursor/rules/data/supabase-sql.mdc)

## When to update this folder

- New or changed table, view, RPC, index, or storage bucket
- Change to bootstrap / client access assumptions
- New `SECURITY DEFINER` function (also update security docs)
