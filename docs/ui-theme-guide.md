# UI & theme guide

---

## Theme

- Light theme via **`EAppTheme`**
- Typography: **Poppins** (bundled under `assets` / font registration as configured in the app)
- Colors, sizes, and helpers centralized under `lib/core`

Prefer existing theme tokens and helpers over hard-coded one-off styles in new pages.

---

## Widget locations

| Need | Prefer |
|------|--------|
| App-wide reusable widgets | `lib/core/widgets` |
| Feature-specific UI | `lib/features/<feature>/presentation/widgets` |
| `lib/shared` | Underused — do not expand without reason |
| `lib/view` | Legacy empty — do not add UI here |

Example shared control mentioned in analysis: `primary_button` under `shared` — new shared controls should still prefer `core/widgets` unless matching an existing shared file.

---

## Presentation patterns

- Pages own `BlocProvider` / `MultiBlocProvider` at the boundary
- Forms and ephemeral UI: `StatefulWidget` / `setState`
- Tab/QR: existing `ChangeNotifier` controllers + `ListenableBuilder`
- Navigation: imperative `Navigator` + `MaterialPageRoute`

---

## Assets

`assets/` holds coaches, icons, images, animations, fonts — reuse existing asset organization; register new assets in `pubspec.yaml` when adding files.

---

## Design discipline for agents

- Match surrounding feature UI density and patterns
- Do not introduce a parallel design system
- Avoid drive-by visual refactors outside the requested task
