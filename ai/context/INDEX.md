# Context packs

Compact routing summaries for major domains. Load the **minimum** set. Packs point at source — they are not full docs.

Global rules: [`AGENTS.md`](../../AGENTS.md).

## Catalog

| Pack | File | Load for |
|------|------|----------|
| Architecture | [`architecture.md`](architecture.md) | Boundaries, DI, shells, state, cache |
| Supabase | [`supabase.md`](supabase.md) | Schema, RLS, RPC, realtime, storage |
| Authentication | [`authentication.md`](authentication.md) | Session, roles, shell, profile |
| Attendance | [`attendance.md`](attendance.md) | Mark / re-attend / unmark, progress |
| Booking | [`booking.md`](booking.md) | Create / cancel / reschedule, cache |
| Payments | [`payments.md`](payments.md) | Methods, verify/reject, finance |
| Notifications | [`notifications.md`](notifications.md) | FCM, in-app feed, realtime |
| Subscriptions | [`subscriptions.md`](subscriptions.md) | Pricing, window, renew |

Retired: [`admin-dashboard.md`](admin-dashboard.md) → Architecture + domain pack(s).

## Loading model

1. Start with no pack → match domain overview triggers.
2. One primary domain pack.
3. Add Architecture only for boundary/DI/shell/cache/multi-feature work.
4. Add Supabase only for schema/RPC/RLS/realtime/storage/SQL work.
5. Second business pack only for explicit cross-domain work.
6. More than three packs → split the task.

## Pack sections

Domain overview · Important classes · Important repositories · Important Cubits/BLoCs · Business rules · Common mistakes · Related documentation

## Budget

Index ~100–150 words + table · business pack ~250–450 · Architecture/Supabase ~400–650.

New pack: copy [`_template.md`](_template.md).
