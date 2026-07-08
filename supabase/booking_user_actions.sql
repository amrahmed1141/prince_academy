-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — User booking actions (cancel / update_days / reschedule)
--
-- Run the ENTIRE script in Supabase → SQL Editor → Run.
-- Safe to re-run (idempotent).
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 1. cancel_booking (user cancels their own booking)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.cancel_booking(
  p_booking_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_payment_status text;
  v_status text;
BEGIN
  SELECT user_id, payment_status, status
  INTO v_user_id, v_payment_status, v_status
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot cancel another user''s booking';
  END IF;

  IF v_status IN ('cancelled', 'rejected', 'completed') THEN
    RAISE EXCEPTION 'Booking is already %', v_status;
  END IF;

  UPDATE public.bookings
  SET
    status = 'cancelled',
    payment_status = 'cancelled',
    updated_at = now()
  WHERE id = p_booking_id;

  DELETE FROM public.user_schedules
  WHERE booking_id = p_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_booking(uuid) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 2. update_booking_days (user changes training days per week)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_booking_days(
  p_booking_id uuid,
  p_days text[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_subscription_start date;
BEGIN
  SELECT user_id, subscription_start
  INTO v_user_id, v_subscription_start
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot update another user''s booking';
  END IF;

  IF p_days IS NULL OR array_length(p_days, 1) IS NULL OR array_length(p_days, 1) < 1 THEN
    RAISE EXCEPTION 'Select at least one training day';
  END IF;

  UPDATE public.bookings
  SET
    selected_days = p_days,
    updated_at = now()
  WHERE id = p_booking_id;

  IF v_subscription_start IS NOT NULL THEN
    PERFORM public.generate_user_schedules(p_booking_id, v_subscription_start, p_days);
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_booking_days(uuid, text[]) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 3. reschedule_booking (user changes subscription start date)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.reschedule_booking(
  p_booking_id uuid,
  p_start_date date
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_selected_days text[];
  v_end_date date;
BEGIN
  SELECT user_id, selected_days
  INTO v_user_id, v_selected_days
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot reschedule another user''s booking';
  END IF;

  v_end_date := (p_start_date + INTERVAL '1 month')::date;

  UPDATE public.bookings
  SET
    subscription_start = p_start_date,
    subscription_end = v_end_date,
    updated_at = now()
  WHERE id = p_booking_id;

  PERFORM public.generate_user_schedules(p_booking_id, p_start_date, v_selected_days);
END;
$$;

GRANT EXECUTE ON FUNCTION public.reschedule_booking(uuid, date) TO authenticated;
