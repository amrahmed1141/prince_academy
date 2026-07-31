# Business Rules Memory

Status: filled

Append dated entries. Do not invent.

<!-- YYYY-MM-DD — note -->

2026-07-31 — Session freeze: each approved frozen session extends `bookings.subscription_end` by +1 calendar day; frozen dates are skipped for Needs-attention expected counts and Mark Attended (`is_scheduled_today`). Members request via `request_booking_freeze`; admins apply via `apply_booking_freeze` or `review_booking_freeze`.
