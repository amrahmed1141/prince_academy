# Examples

Canonical copyable patterns extracted from this repository.

**Precedence:** live gold features (`lib/features/auth`, `booking`, `sessions`) → these excerpts → prose in `ai/standards/` / docs.

Do not invent patterns that are not already present in `lib/` or `supabase/`. Prefer linking to the source of truth over growing a parallel codebase.

| Folder | Pattern | Primary source |
|--------|---------|----------------|
| [`cubit/`](cubit/) | Cubit + Equatable state + GetIt factory | `AdminDashboardCubit` |
| [`repository/`](repository/) | Domain interface + impl + remote DS | `AuthRepo` / `AuthRepoImpl` |
| [`supabase_repository/`](supabase_repository/) | Cache-first / SWR + `StreamRepository` | `BookingRepository`, `AdminRepository` |
| [`rpc/`](rpc/) | `SECURITY DEFINER` RPC + client `.rpc` | `create_booking_with_schedule`, `cancel_booking` |
| [`screen/`](screen/) | Page wires `BlocProvider` via GetIt; no remote I/O | `SessionsPage` |
| [`widget/`](widget/) | Presentational UI; data/callbacks in | `AlreadyBookedButton`, `CoachChipList` |
| [`tests/`](tests/) | Pure Dart unit tests (`flutter_test`) | `test/session_conflict_detector_test.dart`, `test/paged_result_test.dart` |
| [`navigation/`](navigation/) | Imperative `Navigator` + `AuthenticatedShell` | `lib/app` shell (link-only) |

## Agents

| Agent | Uses |
|-------|------|
| Architect | Cites folders in ADR-lite load list |
| Database | [`rpc/`](rpc/) |
| Flutter Developer | All implementation folders |
| Reviewer | Compliance oracle against these shapes |
| Security | [`rpc/`](rpc/), [`navigation/`](navigation/), auth [`repository/`](repository/) |
| Performance | [`supabase_repository/`](supabase_repository/) |
| QA | [`tests/`](tests/) |
| Documentation | Keeps this index truthful |

## Rules

1. Excerpts are snapshots — if source and excerpt diverge, **source wins**; update the excerpt.
2. Copy structure, not novel abstractions.
3. Empty or link-only folders stay empty until a real pattern is approved.
