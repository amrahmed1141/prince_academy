-- ═══════════════════════════════════════════════════════════════
-- Fix admin QR scan: payment status, subscription_status, payment fields
--
-- Problem: admin_scan_profile marked unpaid bookings as "active"
-- because subscription_status ignored payment_status.
--
-- Run in Supabase → SQL Editor → Run (safe to re-run).
-- ═══════════════════════════════════════════════════════════════

DROP VIEW IF EXISTS public.admin_scan_profile CASCADE;

CREATE VIEW public.admin_scan_profile AS
SELECT
  pr.id AS user_id,
  COALESCE(pr.full_name, 'Member') AS full_name,
  pr.phone,
  pr.qr_code,
  b.id AS booking_id,
  b.coach_id,
  c.name AS coach_name,
  c.photo_url AS coach_photo,
  c.specialty AS coach_specialty,
  b.branch_id,
  br.name AS branch_name,
  b.selected_days,
  b.selected_time,
  b.total_price,
  b.payment_method,
  b.payment_status,
  b.status AS booking_status,
  b.subscription_start,
  b.subscription_end,
  b.created_at,
  b.payment_deadline,
  b.payment_reference,
  b.payment_screenshot_url,
  COALESCE(
    bp.total_sessions,
    GREATEST(COALESCE(array_length(b.selected_days, 1), 0), 0) * 4,
    0
  )::integer AS total_sessions,
  COALESCE(bp.attended_sessions, 0)::integer AS attended_sessions,
  COALESCE(
    bp.remaining_sessions,
    GREATEST(
      COALESCE(
        bp.total_sessions,
        GREATEST(COALESCE(array_length(b.selected_days, 1), 0), 0) * 4,
        0
      ) - COALESCE(bp.attended_sessions, 0),
      0
    ),
    0
  )::integer AS remaining_sessions,
  GREATEST(
    COALESCE(b.subscription_end::date - CURRENT_DATE, 0),
    0
  )::integer AS days_remaining,
  CASE
    WHEN lower(coalesce(b.payment_status, '')) IN (
      'pending_payment', 'awaiting_verification', 'pending'
    )
      THEN 'pending_payment'
    WHEN lower(coalesce(b.status, '')) IN ('cancelled', 'rejected')
      THEN lower(b.status)
    WHEN COALESCE(bp.total_sessions, 0) > 0
         AND COALESCE(bp.attended_sessions, 0) >= COALESCE(bp.total_sessions, 0)
      THEN 'completed'
    WHEN b.subscription_end IS NOT NULL
         AND b.subscription_end::date < CURRENT_DATE
      THEN 'expired'
    WHEN lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
         AND lower(coalesce(b.status, '')) IN ('active', 'approved')
      THEN CASE
        WHEN b.subscription_end IS NOT NULL
             AND b.subscription_end::date < CURRENT_DATE
          THEN 'expired'
        ELSE 'active'
      END
    WHEN lower(coalesce(b.status, '')) IN ('pending', 'pending_payment')
      THEN 'pending_payment'
    WHEN lower(coalesce(b.status, '')) IN ('active', 'approved')
      THEN CASE
        WHEN b.subscription_end IS NOT NULL
             AND b.subscription_end::date < CURRENT_DATE
          THEN 'expired'
        WHEN lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
          THEN 'active'
        ELSE 'pending_payment'
      END
    ELSE 'expired'
  END AS subscription_status,
  EXISTS (
    SELECT 1
    FROM public.attendance a
    WHERE a.booking_id = b.id
      AND a.attended_on::date = CURRENT_DATE
      AND lower(coalesce(a.status, '')) = 'attended'
  ) AS already_checked_in_today,
  (
    lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
    AND lower(coalesce(b.status, '')) IN ('active', 'approved')
  )
  AND b.subscription_start IS NOT NULL
  AND b.subscription_end IS NOT NULL
  AND CURRENT_DATE BETWEEN b.subscription_start::date AND b.subscription_end::date
  AND EXISTS (
    SELECT 1
    FROM unnest(b.selected_days) AS d(raw_day)
    WHERE lower(trim(d.raw_day)) = lower(trim(to_char(CURRENT_DATE, 'Day')))
       OR lower(left(trim(d.raw_day), 3)) = lower(left(trim(to_char(CURRENT_DATE, 'Day')), 3))
  ) AS is_scheduled_today
FROM public.bookings b
JOIN public.profiles pr ON pr.id = b.user_id
JOIN public.coaches c ON c.id = b.coach_id
LEFT JOIN public.branches br ON br.id = b.branch_id
LEFT JOIN public.booking_progress bp ON bp.booking_id = b.id
WHERE pr.qr_code IS NOT NULL
  AND trim(pr.qr_code) <> ''
  AND lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected');

GRANT SELECT ON public.admin_scan_profile TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- verify_payment — activate booking after admin confirms payment
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.verify_payment(
  p_booking_id uuid,
  p_admin_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can verify payments';
  END IF;

  UPDATE public.bookings
  SET
    payment_status = 'verified',
    status = 'active',
    updated_at = now()
  WHERE id = p_booking_id
    AND (
      lower(coalesce(payment_status, '')) IN (
        'pending_payment', 'awaiting_verification', 'pending'
      )
      OR lower(coalesce(status, '')) IN ('pending', 'pending_payment')
    );

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found or payment already verified';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_payment(uuid, uuid, text) TO authenticated;
