-- ═══════════════════════════════════════════════════════════════
-- Fix payment verify/reject for legacy payment_status='pending',
-- include those rows in pending_payments, enable dashboard realtime,
-- and reliably auto-delete unconfirmed cash bookings after 3 days.
--
-- Safe to re-run.
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 1. verify_payment — accept legacy 'pending' + raise on no-op
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
DECLARE
  v_updated int;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can verify payments';
  END IF;

  UPDATE public.bookings
  SET
    payment_status = 'verified',
    status = 'active',
    verified_by = p_admin_id,
    verified_at = now(),
    notes = CASE
      WHEN p_notes IS NULL OR btrim(p_notes) = '' THEN notes
      ELSE coalesce(notes, '') || E'\n' || p_notes
    END,
    updated_at = now()
  WHERE id = p_booking_id
    AND lower(coalesce(payment_status, '')) IN (
      'pending',
      'pending_payment',
      'awaiting_verification'
    )
    AND lower(coalesce(status, '')) NOT IN ('cancelled', 'rejected', 'expired');

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Booking not found or payment already processed';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_payment(uuid, uuid, text) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 2. reject_payment — same pending-status coverage
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.reject_payment(
  p_booking_id uuid,
  p_admin_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated int;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can reject payments';
  END IF;

  UPDATE public.bookings
  SET
    payment_status = 'rejected',
    status = 'rejected',
    notes = CASE
      WHEN p_reason IS NULL OR btrim(p_reason) = '' THEN notes
      ELSE coalesce(notes, '') || E'\nRejected: ' || p_reason
    END,
    updated_at = now()
  WHERE id = p_booking_id
    AND lower(coalesce(payment_status, '')) IN (
      'pending',
      'pending_payment',
      'awaiting_verification'
    )
    AND lower(coalesce(status, '')) NOT IN ('cancelled', 'rejected', 'expired');

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Booking not found or payment already processed';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_payment(uuid, uuid, text) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 3. pending_payments view — include legacy payment_status='pending'
-- ───────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.pending_payments CASCADE;

CREATE VIEW public.pending_payments
WITH (security_invoker = true)
AS
SELECT
  b.id AS booking_id,
  b.user_id,
  COALESCE(pr.full_name, 'Member') AS full_name,
  pr.phone,
  b.coach_id,
  c.name AS coach_name,
  c.photo_url AS coach_photo,
  c.specialty AS coach_specialty,
  br.name AS branch_name,
  b.selected_days,
  b.selected_time,
  b.total_price,
  b.payment_method,
  b.payment_status,
  b.subscription_start,
  b.subscription_end,
  b.payment_deadline,
  b.payment_reference,
  b.payment_screenshot_url,
  b.created_at
FROM public.bookings b
JOIN public.coaches c ON c.id = b.coach_id
LEFT JOIN public.profiles pr ON pr.id = b.user_id
LEFT JOIN public.branches br ON br.id = b.branch_id
WHERE lower(coalesce(b.payment_status, '')) IN (
    'pending',
    'pending_payment',
    'awaiting_verification'
  )
  AND lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected', 'expired', 'active');

GRANT SELECT ON public.pending_payments TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 4. Audit log + auto-delete unconfirmed cash bookings (3 days)
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cash_booking_expiry_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL,
  user_id uuid NOT NULL,
  coach_id uuid,
  payment_method text,
  payment_status text,
  status text,
  total_price numeric,
  booking_created_at timestamptz,
  payment_deadline timestamptz,
  expired_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.cash_booking_expiry_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cash_booking_expiry_log_admin_select
  ON public.cash_booking_expiry_log;
CREATE POLICY cash_booking_expiry_log_admin_select
  ON public.cash_booking_expiry_log
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP FUNCTION IF EXISTS public.auto_delete_expired_cash_bookings();

CREATE OR REPLACE FUNCTION public.auto_delete_expired_cash_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted int := 0;
BEGIN
  -- Opportunistic client calls must be admin; cron/postgres has no JWT.
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can expire cash bookings';
  END IF;

  WITH expired AS (
    SELECT
      b.id,
      b.user_id,
      b.coach_id,
      b.payment_method,
      b.payment_status,
      b.status,
      b.total_price,
      b.created_at,
      b.payment_deadline
    FROM public.bookings b
    WHERE lower(coalesce(b.payment_method, '')) = 'cash'
      AND lower(coalesce(b.payment_status, '')) IN (
        'pending',
        'pending_payment',
        'awaiting_verification'
      )
      AND lower(coalesce(b.status, '')) NOT IN (
        'active',
        'cancelled',
        'rejected',
        'expired'
      )
      AND (
        (b.payment_deadline IS NOT NULL AND b.payment_deadline < now())
        OR (
          b.payment_deadline IS NULL
          AND b.created_at < (now() - interval '3 days')
        )
      )
  ),
  logged AS (
    INSERT INTO public.cash_booking_expiry_log (
      booking_id,
      user_id,
      coach_id,
      payment_method,
      payment_status,
      status,
      total_price,
      booking_created_at,
      payment_deadline
    )
    SELECT
      id,
      user_id,
      coach_id,
      payment_method,
      payment_status,
      status,
      total_price,
      created_at,
      payment_deadline
    FROM expired
    RETURNING booking_id
  )
  DELETE FROM public.bookings b
  USING logged
  WHERE b.id = logged.booking_id;

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

GRANT EXECUTE ON FUNCTION public.auto_delete_expired_cash_bookings() TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 5. Realtime publication for admin dashboard live updates
-- ───────────────────────────────────────────────────────────────
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.coach_sessions;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
END $$;

-- ───────────────────────────────────────────────────────────────
-- 6. Daily cron (pg_cron) — best-effort; opportunistic RPC remains
-- ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'expire-unconfirmed-cash-bookings'
  ) THEN
    PERFORM cron.unschedule('expire-unconfirmed-cash-bookings');
  END IF;

  PERFORM cron.schedule(
    'expire-unconfirmed-cash-bookings',
    '15 3 * * *',
    $cron$SELECT public.auto_delete_expired_cash_bookings();$cron$
  );
EXCEPTION
  WHEN undefined_table THEN
    RAISE NOTICE 'pg_cron unavailable — rely on opportunistic RPC calls';
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not schedule cash expiry cron: %', SQLERRM;
END $$;
