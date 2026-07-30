# Prince Academy

Flutter academy / coaching app: **BLoC/Cubit + GetIt + Supabase** (+ Hive, Firebase Messaging).

## Quick start

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

See `docs/environment-setup.md` for environment details.

## Layout

| Path | Role |
|------|------|
| `lib/app/` | Bootstrap, shells, navigation |
| `lib/core/` | DI, cache, theme, shared services |
| `lib/features/` | Feature modules |
| `supabase/` | SQL scripts |
| `ai/` | AI platform (prompts, context, workflows, memory) |
| `examples/` | Canonical copyable patterns |
| `docs/` | Human documentation |
| `.cursor/` | Cursor adapters (rules, agents, skills) |

## Agents

- Contract: [`AGENTS.md`](AGENTS.md)
- AI index: [`README_AI.md`](README_AI.md)
