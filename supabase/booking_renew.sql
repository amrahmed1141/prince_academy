-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — Member booking renew (expired / finished)
--
-- Adds:
--   • bookings.renew_prompt_dismissed_at
--   • get_renewable_bookings()
--   • dismiss_booking_renew_prompt(p_booking_id)
--   • renew_expired_booking(...)  — new booking, same days + price
--
-- Callers: BookingRemoteDs / BookingRepository / BookingRenewCubit
-- RLS: SECURITY DEFINER; every path checks auth.uid() = booking.user_id
--
-- Safe to re-run (idempotent).
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 1. Persist "don't show this renew prompt again"
-- ───────────────────────────────────────────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS renew_prompt_dismissed_at timestamptz;

COMMENT ON COLUMN public.bookings.renew_prompt_dismissed_at IS
  'Set when a renew completes (or legacy permanent dismiss). App cancel is session-only; get_renewable_bookings ignores this for prompts.';

-- Keep caller-provided price on INSERT so renew can copy the original total.
-- Day/session updates still recalculate via monthly_subscription_price.
CREATE OR REPLACE FUNCTION public.set_booking_pricing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_base_price numeric;
  v_sessions_per_week integer;
BEGIN
  IF TG_OP = 'INSERT'
     AND NEW.total_price IS NOT NULL
     AND NEW.total_price > 0 THEN
    RETURN NEW;
  END IF;

  v_sessions_per_week := COALESCE(
    NULLIF(array_length(NEW.selected_days, 1), 0),
    1
  );

  SELECT cs.price_per_session
  INTO v_base_price
  FROM public.coach_sessions cs
  WHERE cs.id = NEW.session_id
  LIMIT 1;

  IF v_base_price IS NULL OR v_base_price <= 0 THEN
    v_base_price := COALESCE(NEW.total_price, 0);
  END IF;

  NEW.total_price := public.monthly_subscription_price(
    v_base_price,
    v_sessions_per_week
  );

  RETURN NEW;
END;
$$;

-- ───────────────────────────────────────────────────────────────
-- 2. get_renewable_bookings — current user's expired/finished
--    bookings that still need a renew prompt (one per coach)
-- ───────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_renewable_bookings();

CREATE OR REPLACE FUNCTION public.get_renewable_bookings()
RETURNS TABLE (
  booking_id uuid,
  user_id uuid,
  coach_id uuid,
  branch_id uuid,
  branch_name text,
  coach_name text,
  coach_photo text,
  coach_specialty text,
  selected_days text[],
  selected_time text,
  total_price numeric,
  payment_method text,
  subscription_start date,
  subscription_end date,
  booking_status text,
  created_at timestamptz,
  total_sessions integer,
  attended_sessions bigint,
  remaining_sessions bigint,
  display_status text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT DISTINCT ON (b.coach_id)
    b.id AS booking_id,
    b.user_id,
    b.coach_id,
    b.branch_id,
    br.name AS branch_name,
    c.name AS coach_name,
    c.photo_url AS coach_photo,
    c.specialty AS coach_specialty,
    b.selected_days,
    b.selected_time,
    b.total_price,
    b.payment_method,
    b.subscription_start,
    b.subscription_end,
    b.status AS booking_status,
    b.created_at,
    COALESCE(bp.total_sessions, 0) AS total_sessions,
    COALESCE(bp.attended_sessions, 0::bigint) AS attended_sessions,
    COALESCE(bp.remaining_sessions, 0::bigint) AS remaining_sessions,
    CASE
      WHEN COALESCE(bp.attended_sessions, 0) >= COALESCE(bp.total_sessions, 0)
           AND COALESCE(bp.total_sessions, 0) > 0
        THEN 'completed'::text
      ELSE 'expired'::text
    END AS display_status
  FROM public.bookings b
  JOIN public.coaches c ON c.id = b.coach_id
  LEFT JOIN public.branches br ON br.id = b.branch_id
  LEFT JOIN public.booking_progress bp ON bp.booking_id = b.id
  WHERE b.user_id = auth.uid()
    -- Cancel is session-only in the app; do not hide on renew_prompt_dismissed_at.
    AND lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected')
    AND (
      b.subscription_end < CURRENT_DATE
      OR lower(coalesce(b.status, '')) IN ('expired', 'completed')
      OR (
        COALESCE(bp.attended_sessions, 0) >= COALESCE(bp.total_sessions, 0)
        AND COALESCE(bp.total_sessions, 0) > 0
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.bookings live
      WHERE live.user_id = b.user_id
        AND live.coach_id = b.coach_id
        AND live.id <> b.id
        AND lower(coalesce(live.status, '')) NOT IN (
          'cancelled', 'rejected', 'expired', 'completed'
        )
        AND lower(coalesce(live.payment_status, '')) NOT IN (
          'rejected', 'cancelled'
        )
        AND (live.subscription_end IS NULL OR live.subscription_end >= CURRENT_DATE)
    )
  ORDER BY b.coach_id, b.subscription_end DESC, b.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_renewable_bookings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_renewable_bookings() TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 3. dismiss_booking_renew_prompt
-- ───────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.dismiss_booking_renew_prompt(uuid);

CREATE OR REPLACE FUNCTION public.dismiss_booking_renew_prompt(
  p_booking_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT user_id INTO v_user_id
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot dismiss another user''s booking';
  END IF;

  UPDATE public.bookings
  SET
    renew_prompt_dismissed_at = now(),
    updated_at = now()
  WHERE id = p_booking_id
    AND user_id = auth.uid()
    AND renew_prompt_dismissed_at IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.dismiss_booking_renew_prompt(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dismiss_booking_renew_prompt(uuid)
  TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 4. renew_expired_booking — create a new booking with the same
--    coach, days, time, and original price. New start date + method.
-- ───────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.renew_expired_booking(uuid, date, text, text);

CREATE OR REPLACE FUNCTION public.renew_expired_booking(
  p_source_booking_id uuid,
  p_start_date date,
  p_payment_method text,
  p_payment_reference text DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_source public.bookings;
  v_booking public.bookings;
  v_method text;
  v_branch_id uuid;
  v_session_id uuid;
  v_attended bigint;
  v_total integer;
  v_is_finished boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_start_date IS NULL OR p_start_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'Start date must be today or later';
  END IF;

  v_method := lower(btrim(coalesce(p_payment_method, '')));
  IF v_method NOT IN ('cash', 'instapay') THEN
    RAISE EXCEPTION 'Payment method must be cash or instapay';
  END IF;

  SELECT * INTO v_source
  FROM public.bookings
  WHERE id = p_source_booking_id;

  IF v_source IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_source.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot renew another user''s booking';
  END IF;

  IF lower(coalesce(v_source.status, '')) IN ('cancelled', 'rejected') THEN
    RAISE EXCEPTION 'This booking cannot be renewed';
  END IF;

  SELECT
    COALESCE(bp.attended_sessions, 0),
    COALESCE(bp.total_sessions, 0)
  INTO v_attended, v_total
  FROM public.booking_progress bp
  WHERE bp.booking_id = v_source.id;

  v_is_finished :=
    v_source.subscription_end < CURRENT_DATE
    OR lower(coalesce(v_source.status, '')) IN ('expired', 'completed')
    OR (COALESCE(v_total, 0) > 0 AND COALESCE(v_attended, 0) >= v_total);

  IF NOT v_is_finished THEN
    RAISE EXCEPTION 'Only expired or finished bookings can be renewed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.bookings live
    WHERE live.user_id = v_source.user_id
      AND live.coach_id = v_source.coach_id
      AND live.id <> v_source.id
      AND lower(coalesce(live.status, '')) NOT IN (
        'cancelled', 'rejected', 'expired', 'completed'
      )
      AND lower(coalesce(live.payment_status, '')) NOT IN (
        'rejected', 'cancelled'
      )
      AND (live.subscription_end IS NULL OR live.subscription_end >= CURRENT_DATE)
  ) THEN
    RAISE EXCEPTION 'You already have an active booking with this coach';
  END IF;

  v_session_id := v_source.session_id;
  IF v_session_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.coach_sessions cs
    WHERE cs.id = v_session_id AND cs.is_active = true
  ) THEN
    SELECT cs.id INTO v_session_id
    FROM public.coach_sessions cs
    WHERE cs.coach_id = v_source.coach_id
      AND cs.is_active = true
    ORDER BY cs.created_at DESC
    LIMIT 1;
  END IF;

  v_branch_id := v_source.branch_id;
  IF v_branch_id IS NULL THEN
    SELECT COALESCE(cs.branch_id, c.branch_id)
    INTO v_branch_id
    FROM public.coaches c
    LEFT JOIN public.coach_sessions cs
      ON cs.coach_id = c.id AND cs.id = v_session_id
    WHERE c.id = v_source.coach_id;
  END IF;

  IF v_session_id IS NULL THEN
    RAISE EXCEPTION 'No active session found for this coach';
  END IF;

  IF v_branch_id IS NULL THEN
    RAISE EXCEPTION 'Branch not configured for this coach';
  END IF;

  IF v_source.selected_days IS NULL
     OR array_length(v_source.selected_days, 1) IS NULL
     OR array_length(v_source.selected_days, 1) < 1 THEN
    RAISE EXCEPTION 'Original booking has no training days';
  END IF;

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
    v_source.user_id,
    v_source.coach_id,
    v_branch_id,
    v_session_id,
    v_source.selected_days,
    v_source.selected_time,
    v_method,
    v_source.total_price,
    p_start_date,
    (p_start_date + INTERVAL '1 month')::date,
    'pending_payment',
    p_payment_reference,
    (CURRENT_DATE + INTERVAL '3 days')::date,
    'pending'
  )
  RETURNING * INTO v_booking;

  PERFORM public.generate_user_schedules(
    v_booking.id,
    p_start_date,
    v_source.selected_days
  );

  UPDATE public.bookings
  SET
    renew_prompt_dismissed_at = now(),
    updated_at = now()
  WHERE id = v_source.id
    AND renew_prompt_dismissed_at IS NULL;

  RETURN v_booking;
END;
$$;

REVOKE ALL ON FUNCTION public.renew_expired_booking(uuid, date, text, text)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.renew_expired_booking(uuid, date, text, text)
  TO authenticated;
