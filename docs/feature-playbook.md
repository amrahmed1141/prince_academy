# Feature playbook

How to add or extend a feature in Prince Academy without inventing a new architecture.

---

## 1. Choose the home

Place work under `lib/features/<feature>/`:

```
features/<name>/
  data/
    models/
    datasources/      # *_remote_ds.dart (optional but preferred for fat remote APIs)
    repositories/     # *_repository.dart
  domain/             # optional — use when you need an interface (auth style)
  presentation/
    bloc/             # *_bloc.dart, *_event.dart, *_state.dart  OR cubit
    pages/
    widgets/
```

Shared infrastructure → `lib/core` or `lib/app` only.

---

## 2. Models

- Hand-written Dart classes (no Freezed / json_serializable)
- Snake_case keys matching Postgres
- `fromJson` / `fromMap` and `toJson` / `toMap` / `toInsertJson` consistent with siblings
- `copyWith` when the feature already uses it

---

## 3. Repository / datasource

- Wrap Supabase `.from`, `.rpc`, storage, and realtime here — **not** in pages
- Prefer RPCs for multi-table / transactional flows
- For live admin-style lists, consider extending `StreamRepository<T>` (`lib/core/base/stream_repository.dart`)
- Auth gold standard: interface in `domain` + `AuthRepoImpl` + `AuthRemoteDs`

Existing repositories to extend before creating new ones:  
`AuthRepo`, `BookingRepository`, `SessionsRepository`, `HomeCoachRepository`, `NotificationRepository`, `AdminRepository`, `AdminDashboardRepository`, `BranchRepository`, `CoachRepository`, `FinanceRepository`

---

## 4. Register in GetIt

In `lib/core/di/injection.dart`:

- Repository / datasource / cache → **lazy singleton**
- BLoC / Cubit → **factory**

Prefer constructor injection into the BLoC/Cubit.

---

## 5. Presentation wiring

- Create BLoC (events/states + Equatable) or Cubit
- At the page: `BlocProvider(create: (_) => sl<MyBloc>()..add(...))` or `MultiBlocProvider`
- Subscribe to repository streams; emit **cached data first**, then refresh
- Surface errors as `String` fields on states (existing style)

---

## 6. Cache / sync after mutations

- Invalidate via `MemberDataSync` / member prefetch helpers when member home/booking/sessions data changes
- Use `unawaited` for non-blocking cache writes where that pattern already exists

---

## 7. Navigation

- `Navigator.push(MaterialPageRoute(...))`
- Authenticated destinations must remain reachable under **`AuthenticatedShell`**
- Do not introduce a router package in this playbook

---

## 8. SQL (if schema changes)

1. Add a clearly named script under `supabase/`
2. Note RLS / `SECURITY DEFINER` / storage policy impact
3. Update [supabase-schema-and-rpc.md](supabase-schema-and-rpc.md) when catalogs change

---

## Checklist

- [ ] Files under the correct feature folders
- [ ] No `Supabase.instance` in widgets
- [ ] DI registration + factory BLoC
- [ ] Naming: `snake_case` files, `*_repository` / `*_model` / `*_remote_ds`
- [ ] Cache-first behavior preserved for lists
- [ ] No unrelated legacy cleanup
