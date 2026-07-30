# Testing guide

Current suite is **sparse** (~few tests) relative to business complexity. Add tests where risk is highest; do not require a full rewrite to contribute.

---

## Priority unit-test targets

| Area | Why |
|------|-----|
| Pricing helpers (`core`) | Money logic regressions are costly |
| Booking conflict detection / RPC result mapping | Core member revenue path |
| Model mappers (`fromJson` / `fromMap`) | Schema drift shows up here |
| Repository error mapping (`PostgrestException` → user-facing) | UX consistency |
| Auth role gate / missing profile → sign-out behavior | Security-adjacent |
| Cache invalidation helpers (`MemberDataSync` paths) | Stale UI bugs |

---

## Suggested style

- Prefer pure Dart unit tests for mappers, pricing, and policy helpers
- Mock repositories when testing BLoCs/Cubits (constructor injection already supports this)
- Keep tests under `test/` mirroring feature names when practical

---

## Out of scope unless requested

- Full widget golden suite
- Forcing Freezed/codegen solely for testability
- Deleting legacy screens “to make testing easier”

---

## Command

```bash
flutter test
```
