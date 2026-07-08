-- ═══════════════════════════════════════════════════════════════
-- Fix: "violates check constraint valid_payment_status" on booking
--
-- Cause: create_booking_with_schedule inserts payment_status =
-- 'pending_payment', but an older bookings table constraint only
-- allows legacy values like 'pending' / 'paid'.
--
-- Run in Supabase → SQL Editor → Run (safe to re-run).
-- ═══════════════════════════════════════════════════════════════

-- Drop every known name for the payment_status check (varies by project)
ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS valid_payment_status;

ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS bookings_payment_status_check;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'public.bookings'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) ILIKE '%payment_status%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS %I',
      r.conname
    );
  END LOOP;
END $$;

ALTER TABLE public.bookings
  ADD CONSTRAINT valid_payment_status
  CHECK (
    payment_status IS NULL
    OR payment_status IN (
      'pending',
      'pending_payment',
      'awaiting_verification',
      'verified',
      'paid',
      'active',
      'failed',
      'cancelled',
      'rejected',
      'refunded'
    )
  );

-- Booking lifecycle status (create_booking uses status = 'pending')
ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS valid_status;

ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS bookings_status_check;

ALTER TABLE public.bookings
  ADD CONSTRAINT valid_status
  CHECK (
    status IS NULL
    OR status IN (
      'pending',
      'pending_payment',
      'active',
      'approved',
      'expired',
      'cancelled',
      'rejected',
      'completed'
    )
  );

ALTER TABLE public.bookings
  ALTER COLUMN payment_status SET DEFAULT 'pending_payment';

-- Ensure RPC matches app expectations
CREATE OR REPLACE FUNCTION public.create_booking_with_schedule(
  p_user_id uuid,
  p_coach_id uuid,
  p_branch_id uuid,
  p_days text[],
  p_time text,
  p_start_date date,
  p_price numeric,
  p_method text,
  p_payment_reference text DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings;
  v_session_id uuid;
  v_base_price numeric;
  v_final_price numeric;
  v_subscription_end date;
  v_sessions_per_week integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot create booking for another user';
  END IF;

  IF p_days IS NULL OR array_length(p_days, 1) IS NULL OR array_length(p_days, 1) < 1 THEN
    RAISE EXCEPTION 'Select at least one training day';
  END IF;

  SELECT cs.id, cs.price_per_session
  INTO v_session_id, v_base_price
  FROM public.coach_sessions cs
  WHERE cs.coach_id = p_coach_id
    AND cs.is_active = true
  ORDER BY cs.created_at DESC
  LIMIT 1;

  v_sessions_per_week := array_length(p_days, 1);

  v_final_price := public.monthly_subscription_price(
    COALESCE(NULLIF(v_base_price, 0), p_price),
    v_sessions_per_week
  );

  IF v_final_price IS NULL OR v_final_price <= 0 THEN
    v_final_price := COALESCE(p_price, 0);
  END IF;

  v_subscription_end := (p_start_date + INTERVAL '1 month')::date;

  INSERT INTO public.bookings (
    user_id,
    coach_id,
    branch_id,
    session_id,
    selected_days,
    selected_time,
    payment_method,
    total_price,
    subscription_start,
    subscription_end,
    payment_status,
    payment_reference,
    payment_deadline,
    status
  ) VALUES (
    p_user_id,
    p_coach_id,
    p_branch_id,
    v_session_id,
    p_days,
    p_time,
    p_method,
    v_final_price,
    p_start_date,
    v_subscription_end,
    'pending_payment',
    p_payment_reference,
    (CURRENT_DATE + INTERVAL '3 days')::date,
    'pending'
  )
  RETURNING * INTO v_booking;

  PERFORM public.generate_user_schedules(
    v_booking.id,
    p_start_date,
    p_days
  );

  RETURN v_booking;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_booking_with_schedule(
  uuid, uuid, uuid, text[], text, date, numeric, text, text
) TO authenticated;
