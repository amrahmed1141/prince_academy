# Operations

How to set up, build, ship, and run Prince Academy under time pressure. Prefer checklists and exact commands over narrative.

**Not here:** architectural rationale ([`../architecture/`](../architecture/)); product behaviour ([`../product/`](../product/)); agent test-writing standards ([`ai/standards/testing.md`](../../ai/standards/testing.md) — keep as the agent twin of the human testing page).

## Consumers

Developers on a fresh machine, whoever owns a release, and responders during an incident.

## Index

| Document | Question it answers | Status |
|----------|---------------------|--------|
| [Environment setup (root)](../environment-setup.md) | How do I run the app with Supabase / Firebase / defines? | Current — migrate to `environment-setup.md` |
| [Deprecation list (root)](../deprecation-list.md) | What is frozen legacy and must not be “cleaned up”? | Current — migrate to `deprecations.md` |
| [Testing guide (root)](../testing-guide.md) | What should humans prioritize when adding tests? | Current — migrate to `testing.md` |

## Planned pages (create when content is ready)

| Document | Question it answers |
|----------|---------------------|
| `environment-setup.md` | Prerequisites, `flutter run`, dart-defines, Firebase, maps |
| `sql-apply.md` | How to apply `supabase/*.sql` deliberately per environment |
| `release.md` | Build, signing, store upload, rollback |
| `deprecations.md` | Frozen legacy surfaces and removal protocol |
| `testing.md` | Human testing priorities and how to run `flutter test` |
| `monitoring.md` | Crash / push / incident triage entry points |

## Quick start

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Use the exact define names from `lib/core/config/supabase_config.dart`. Publishable defaults may exist for local work; prefer explicit defines outside local.

```bash
flutter test
```

## Supabase scripts

- Live under `supabase/` as named setup/fix files  
- No guaranteed CLI migration history  
- Apply deliberately; keep RLS and storage policies aligned with the app  

## Deprecation stance

Do **not** delete `lib/view/`, remove the unused `provider` dependency, or retire `navigation_bloc` unless explicitly asked. See the deprecation list before “cleanup” PRs.

## Related

- Release agent / prompt: [`agents/release.md`](../../agents/release.md), [`ai/prompts/release.md`](../../ai/prompts/release.md), [`ai/workflows/release.md`](../../ai/workflows/release.md)
- Deprecations rule: [`.cursor/rules/product/deprecations.mdc`](../../.cursor/rules/product/deprecations.mdc)

## When to update this folder

- Setup, build, signing, or release process change
- New dart-define or Firebase requirement
- New deprecation entry or completed removal
- Change to how SQL scripts are applied
