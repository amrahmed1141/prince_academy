# Architecture overview

**Product:** Prince Academy  
**Style:** Pragmatic **feature-first layered** architecture (not strict Clean Architecture)  
**Stack:** Flutter + BLoC/Cubit + GetIt + Supabase (+ Firebase Messaging, Hive)

---

## Layers

| Layer | Role | Consistency |
|-------|------|-------------|
| `presentation` | Pages, widgets, BLoC/Cubit | Strong |
| `data` | Models, repositories, remote datasources | Strong |
| `domain` | Contracts / domain types | Weak — mainly `auth` (+ small `sessions` piece) |
| `core` / `app` | DI, cache, theme, bootstrap, shells | Strong |

Presentation talks to repositories (mostly **concrete** classes). Data access is almost entirely `SupabaseClient` (PostgREST, RPC, Storage, Realtime, Auth).

---

## Runtime shape

```
main.dart
  → Firebase push (mobile only)
  → bootstrap() [Hive → Supabase → GetIt]
  → PrinceAcademyApp
       → AuthBloc drives home: Splash | AuthPage | AuthenticatedShell
            → member NavigationBottom  OR  AdminHomeScreen
```

- Imperative navigation (`Navigator` + `MaterialPageRoute`) — no router package
- Role-based shell: member vs admin when `role == 'admin'`
- Local cache: Hive + in-memory TTL / `StreamRepository`

---

## Top-level layout

```
prince_academy/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── app/                 # bootstrap, root app, splash, member bottom nav
│   ├── core/                # DI, cache, theme, helpers, services, widgets
│   ├── features/
│   │   ├── admin/
│   │   ├── auth/            # includes domain/
│   │   ├── booking/
│   │   ├── home/
│   │   ├── maps/
│   │   ├── notifications/
│   │   ├── profile/         # presentation-heavy
│   │   └── sessions/        # includes small domain/
│   ├── shared/              # nearly empty — prefer core/widgets
│   └── view/                # empty / legacy — do not use
├── assets/
├── supabase/                # ad-hoc SQL setup/fix scripts (not CLI migrations)
├── test/                    # sparse
└── analysis_options.yaml    # default flutter_lints
```

### Typical feature layout

```
features/<name>/
  data/models | datasources | repositories
  domain/                     # optional
  presentation/bloc | pages | widgets
```

---

## Dependency injection

- **Library:** GetIt (`final sl = GetIt.I`)
- **Root:** `lib/core/di/injection.dart` → `setupDI()`
- **Lazy singleton:** `SupabaseClient`, repositories, datasources, cache, tab controllers, `UserQrService`
- **Factory:** BLoCs/Cubits
- **Eager singleton:** `AdminSessionPreferences` (async create)
- Manual registration only (no injectable)

Auth is the cleanest interface registration: `AuthRepo` → `AuthRepoImpl`.

---

## State management

- Primary: `bloc` + `flutter_bloc` + `equatable`
- Cubits for simpler admin/search/finance flows
- Secondary: `ChangeNotifier` for tab/QR services via `ListenableBuilder` (**not** Provider)
- `provider` is in pubspec but unused — do not adopt it

---

## Networking

No Dio/`http` wrapper. Remote API = Supabase SDK only. Push = Firebase Messaging; token on `profiles.fcm_token`.

Config: `lib/core/config/supabase_config.dart` via `--dart-define` (with checked-in publishable defaults).

---

## Feature map

| Feature | Responsibility |
|---------|----------------|
| auth | Login/signup, session, role gate |
| home | Member home, coaches, activity |
| booking | Book coach sessions, payment screenshot, history/detail |
| sessions | Calendar/upcoming/history, attendance progress |
| profile | Profile edit, avatar, payments, member QR |
| notifications | In-app feed + FCM bridge |
| maps | Branch map / external maps |
| admin | Dashboard, coaches/branches/sessions, finance, payments, tracking, QR attendance, renewals |

**Coupling notes:** Admin is the largest feature. Member features share cache invalidation via `MemberDataSync` / prefetch. Profile leans on other features’ repos/services.

---

## Architectural character (for clones)

This is a **product-oriented monolith**: clear feature folders, shared infrastructure in `core`, partial dependency inversion (auth only). SaaS clones should keep this shape rather than forcing full Clean Architecture unless the new product explicitly upgrades.
