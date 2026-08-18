# Business Rules Memory

Status: filled

Append dated entries. Do not invent.

<!-- YYYY-MM-DD — note -->

2026-08-13 — Member renew prompt: a booking is renewable when it is expired (`subscription_end < CURRENT_DATE`) or finished (attended ≥ monthly session total), not cancelled/rejected, not dismissed, and the member has no in-window live booking with the same coach. Renew creates a **new** pending booking (does not patch the old row); admin `renew_booking_subscription` still extends the same row.
2026-07-31 — Session freeze: each approved frozen session extends `bookings.subscription_end` by +1 calendar day; frozen dates are skipped for Needs-attention expected counts and Mark Attended (`is_scheduled_today`). Members request via `request_booking_freeze`; admins apply via `apply_booking_freeze` or `review_booking_freeze`.
