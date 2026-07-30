# Product

Domain behaviour described without Dart: who the actors are, what they can do, and which business rules constrain the system. Name the enforcing RPC or repository when a rule is technical.

**Not here:** Flutter layer layout ([`../architecture/`](../architecture/)); RLS / secret handling ([`../security/`](../security/)); compressed agent restatements ([`ai/memory/business-rules.md`](../../ai/memory/business-rules.md) — keep that as a short twin that links here).

## Consumers

Product owners and academy operators, QA writing cases from expected behaviour, developers deciding whether an edge case is a bug or intentional, and support diagnosing member issues.

## Index

| Document | Question it answers | Status |
|----------|---------------------|--------|
| [Auth & roles (root)](../auth-and-roles.md) | How do signup, login, session, and role shells behave? | Current — split: capabilities stay product; enforcement → security |

## Planned pages (create when content is ready)

| Document | Question it answers |
|----------|---------------------|
| `roles-and-capabilities.md` | What can member vs admin do in the product? |
| `booking-lifecycle.md` | What are booking states and allowed transitions? |
| `subscriptions-and-pricing.md` | How do monthly pricing and renewals work? |
| `attendance.md` | How do attend / re-attend semantics work? |
| `payments.md` | How does screenshot submission and verify/reject work? |
| `notifications.md` | When do in-app and push notifications fire? |
| `admin-operations.md` | What does the admin dashboard operate on day to day? |

## Role signal (product view)

| Role | Product surface |
|------|-----------------|
| `role == 'admin'` | Admin home / operational tools |
| otherwise | Member bottom navigation (home, booking, sessions, profile, …) |

UI role checks are product routing, not authorization. Authorization is RLS and RPCs — see [`../security/`](../security/).

## Feature → product map

| Feature (`lib/features/`) | Product concern |
|---------------------------|-----------------|
| auth | Identity, session, role gate into the shell |
| home | Member home, coaches, activity |
| booking | Book coach sessions, payment screenshot, history |
| sessions | Calendar / upcoming / history, attendance progress |
| profile | Profile, avatar, payments, member QR |
| notifications | In-app feed + FCM bridge |
| maps | Branch map |
| admin | Coaches, branches, sessions, finance, payments, tracking, QR attendance, renewals |

## Related

- Agent context packs: [`ai/context/`](../../ai/context/) (booking, payments, attendance, subscriptions, notifications, … — see [`INDEX.md`](../../ai/context/INDEX.md); admin-dashboard is retired)
- Memory twin: [`ai/memory/business-rules.md`](../../ai/memory/business-rules.md)
- Product rules: [`.cursor/rules/product/`](../../.cursor/rules/product/)

## When to update this folder

- New user-visible behaviour or state machine
- Change to roles, pricing, booking, attendance, or payment rules
- Admin operational surface change
