# Tests

Approved test style from the existing suite: pure Dart `flutter_test` unit tests; no live Supabase.

## Why

The project suite is sparse. New tests should match these shapes — behaviour of helpers/mappers/pagination — and (when adding BLoC tests) mock the repository via constructor injection. See [`docs/testing-guide.md`](../../docs/testing-guide.md).

## Sources (truth)

| Role | Path |
|------|------|
| Helper behaviour | [`test/session_conflict_detector_test.dart`](../../test/session_conflict_detector_test.dart) |
| Model / paging | [`test/paged_result_test.dart`](../../test/paged_result_test.dart) |
| Guide | [`docs/testing-guide.md`](../../docs/testing-guide.md) |

## Agents

QA · Flutter Developer · Reviewer

## Excerpt

See [`excerpt.md`](excerpt.md). Full files live under `test/` — prefer editing those; this folder is the pattern snapshot.

## Anti-patterns

- Hitting real Supabase / network in unit tests
- Introducing a new mocking framework outside the project set
- Asserting UI trivia instead of helper / state contracts
