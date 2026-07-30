# Doc page template

Copy this file into the target folder, rename to a kebab-case topic (`booking-lifecycle.md`), then replace every instruction in angle brackets. Delete this preamble.

---

# <Title — the question this page answers, in plain language>

| Field | Value |
|-------|-------|
| Owner | <team or role, e.g. Flutter / Backend> |
| Last reviewed | <YYYY-MM-DD> |
| Status | `current` \| `draft` \| `deprecated` |
| Folder | `architecture` \| `database` \| `product` \| `security` \| `operations` |

## Audience

Who should open this page, and what they already know.

## Summary

Two or three sentences. A reader in a hurry should leave with the answer without scrolling.

## Source of truth

Name the canonical artifacts this page describes. Examples:

- Code: `lib/features/booking/...`
- SQL: `supabase/booking_flow.sql`
- Config: `lib/core/config/supabase_config.dart`

If this page and the source disagree, the source wins — update this page.

## Content

### <Primary section>

Facts only. Prefer tables for catalogues, numbered lists for ordered flows, and short paragraphs for constraints.

### Invariants

Bullets that must remain true after any change in this area. Link ADRs when an invariant is a recorded decision (`../decisions/NNNN-...`).

### Anti-patterns

What not to do, drawn from real project mistakes — not generic advice.

## Related

| Kind | Link |
|------|------|
| Sibling docs | |
| ADRs | |
| Agent context / memory | |
| Examples | |
| Cursor rules | |

## Changelog

| Date | Change |
|------|--------|
| <YYYY-MM-DD> | Page created |

---

## Author checklist (delete before merge)

- [ ] Filename is kebab-case and topic-first
- [ ] Page lives in the folder matching the reader’s question (see [`../README.md`](../README.md))
- [ ] No duplicated prose that already lives elsewhere — link instead
- [ ] Sources cited; nothing invented to fill space
- [ ] Folder `README.md` index row added or updated
- [ ] Status and last-reviewed set
