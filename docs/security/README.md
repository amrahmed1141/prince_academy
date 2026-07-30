# Security

Trust boundaries and the controls that protect them: client privileges, RLS intent, `SECURITY DEFINER` risk, storage access, session hygiene, and review checklists.

**Not here:** table/column catalogues ([`../database/`](../database/)); member/admin capability lists as product UX ([`../product/`](../product/)). *What* an RLS policy is belongs in database docs; *why the threat model requires it* belongs here.

## Consumers

Reviewers on PRs that touch auth, RLS, storage, or privileged RPCs; anyone preparing a release security check; engineers adding `SECURITY DEFINER` functions.

## Index

| Document | Question it answers | Status |
|----------|---------------------|--------|
| [Security notes (root)](../security-notes.md) | What are client privileges, authz model, storage, and the PR checklist? | Current — migrate to `overview.md` |
| [Auth & roles (root)](../auth-and-roles.md) | How is session established and what must sign-out clear? | Current — enforcement sections belong here |

## Planned pages (create when content is ready)

| Document | Question it answers |
|----------|---------------------|
| `overview.md` | What is the security model end to end? |
| `authentication.md` | How does session auth work, and what is forbidden? |
| `rls-and-roles.md` | What do RLS / `is_admin()` / triggers enforce? |
| `security-definer.md` | When is DEFINER allowed, and how is the surface minimized? |
| `storage.md` | What are bucket risks (especially public payment screenshots)? |
| `secrets-and-config.md` | How may keys and `--dart-define` values be handled? |

## Non-negotiables

| Allowed in Flutter | Forbidden in Flutter |
|--------------------|----------------------|
| Supabase anon / publishable key | Supabase `service_role` key |
| `--dart-define` for publishable config | Private API secrets / server tokens |

- Admin UI gate (`role == 'admin'`) is **UX**, not the security boundary.
- Signup metadata (including role) is **not** authorization — RLS, triggers, and `is_admin()` enforce role.
- Privileged multi-step work goes through carefully scoped `SECURITY DEFINER` RPCs.
- No direct `Supabase.instance` (or equivalent) from widgets in new code.

## Storage buckets

`profile-avatars`, `coach-photos`, `payment-screenshots`. Payment screenshots may use public URLs by design — treat as sensitive; do not casually broaden access.

## Sign-out hygiene

1. Clear FCM token on profile  
2. Dispose notification realtime  
3. Supabase sign-out  
4. Clear user Hive cache  

## PR checklist

- [ ] No `service_role` in app or client-oriented env samples  
- [ ] New tables / RPCs include RLS thinking  
- [ ] `SECURITY DEFINER` functions minimize trust surface  
- [ ] No new remote I/O from widgets  
- [ ] Matching SQL under `supabase/` for schema changes  

## Related

- Database catalogue: [`../database/`](../database/)
- Auth architecture path: `lib/features/auth`
- Agent context: [`ai/context/authentication.md`](../../ai/context/authentication.md)
- Rules: [`.cursor/rules/data/auth-security.mdc`](../../.cursor/rules/data/auth-security.mdc), [`.cursor/rules/data/secrets-config.mdc`](../../.cursor/rules/data/secrets-config.mdc)

## When to update this folder

- Auth, RLS, storage policy, or DEFINER RPC change
- New secret / config channel
- Incident or near-miss that changes controls
