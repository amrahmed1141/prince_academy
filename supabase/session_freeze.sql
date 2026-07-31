-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — Session Freeze (tables + RPCs)
-- Run the ENTIRE script in Supabase → SQL Editor → Run.
-- Safe to re-run (idempotent).
--
-- Callers:
--   BookingFreezeRepository (request / apply / review / lists)
--   AdminDashboardRepository (pending count KPI)
--   get_booking_sessions / get_dashboard_low_attendance_members (patched)
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 0. Tables
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.booking_freezes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  requested_by uuid NOT NULL REFERENCES public.profiles(id),
  reviewed_by uuid REFERENCES public.profiles(id),
  reviewed_at timestamptz,
  original_subscription_end date,
  new_subscription_end date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_booking_freezes_booking_id
  ON public.booking_freezes (booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_freezes_status
  ON public.booking_freezes (status);
CREATE INDEX IF NOT EXISTS idx_booking_freezes_user_id
  ON public.booking_freezes (user_id);

-- At most one pending freeze per booking
CREATE UNIQUE INDEX IF NOT EXISTS idx_booking_freezes_one_pending
  ON public.booking_freezes (booking_id)
  WHERE status = 'pending';

CREATE TABLE IF NOT EXISTS public.booking_freeze_dates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  freeze_id uuid NOT NULL REFERENCES public.booking_freezes(id) ON DELETE CASCADE,
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  session_date date NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (freeze_id, session_date)
);

CREATE INDEX IF NOT EXISTS idx_booking_freeze_dates_booking_date
  ON public.booking_freeze_dates (booking_id, session_date);
CREATE INDEX IF NOT EXISTS idx_booking_freeze_dates_freeze_id
  ON public.booking_freeze_dates (freeze_id);

-- One active (pending|approved) freeze occupancy per booking+date
CREATE UNIQUE INDEX IF NOT EXISTS idx_booking_freeze_dates_active_unique
  ON public.booking_freeze_dates (booking_id, session_date)
  WHERE EXISTS (
    SELECT 1 FROM public.booking_freezes bf
    WHERE bf.id = booking_freeze_dates.freeze_id
      AND bf.status IN ('pending', 'approved')
  );

-- Partial unique via trigger is more reliable than predicate on other table;
-- enforce in helper instead. Drop fragile index if created above fails on some PG.
DROP INDEX IF EXISTS public.idx_booking_freeze_dates_active_unique;

ALTER TABLE public.booking_freezes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_freeze_dates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS booking_freezes_select_own ON public.booking_freezes;
CREATE POLICY booking_freezes_select_own
  ON public.booking_freezes FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS booking_freeze_dates_select_own ON public.booking_freeze_dates;
CREATE POLICY booking_freeze_dates_select_own
  ON public.booking_freeze_dates FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.booking_freezes bf
      WHERE bf.id = freeze_id
        AND (bf.user_id = auth.uid() OR public.is_admin())
    )
  );

-- No direct INSERT/UPDATE/DELETE for clients — RPCs only.

-- ───────────────────────────────────────────────────────────────
-- 1. Helpers
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._freeze_format_date(p_date date)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT to_char(p_date, 'YYYY-MM-DD');
$$;

CREATE OR REPLACE FUNCTION public._freeze_validate_dates(
  p_booking_id uuid,
  p_session_dates date[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking record;
  v_date date;
  v_attended boolean;
  v_already_frozen boolean;
  v_is_scheduled boolean;
  v_day_name text;
BEGIN
  IF p_session_dates IS NULL OR cardinality(p_session_dates) = 0 THEN
    RAISE EXCEPTION 'Select at least one session to freeze';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF lower(coalesce(v_booking.status, '')) NOT IN ('active', 'approved', 'pending') THEN
    RAISE EXCEPTION 'Booking is not eligible for freeze';
  END IF;

  FOREACH v_date IN ARRAY p_session_dates LOOP
    -- Must fall on a selected weekday within subscription window
    v_day_name := trim(to_char(v_date, 'Day'));
    SELECT EXISTS (
      SELECT 1
      FROM unnest(v_booking.selected_days) AS d(raw_day)
      WHERE lower(trim(d.raw_day)) = lower(v_day_name)
         OR lower(left(trim(d.raw_day), 3)) = lower(left(v_day_name, 3))
    )
    AND (
      v_booking.subscription_start IS NULL
      OR v_date >= v_booking.subscription_start::date
    )
    AND (
      v_booking.subscription_end IS NULL
      OR v_date <= v_booking.subscription_end::date
    )
    INTO v_is_scheduled;

    IF NOT coalesce(v_is_scheduled, false) THEN
      RAISE EXCEPTION 'Date % is not a scheduled session for this booking', v_date;
    END IF;

    SELECT EXISTS (
      SELECT 1 FROM public.attendance a
      WHERE a.booking_id = p_booking_id
        AND a.attended_on = v_date
        AND lower(coalesce(a.status, '')) = 'attended'
    ) INTO v_attended;

    IF v_attended THEN
      RAISE EXCEPTION 'Cannot freeze an attended session (%)', v_date;
    END IF;

    SELECT EXISTS (
      SELECT 1
      FROM public.booking_freeze_dates fd
      JOIN public.booking_freezes bf ON bf.id = fd.freeze_id
      WHERE fd.booking_id = p_booking_id
        AND fd.session_date = v_date
        AND bf.status IN ('pending', 'approved')
    ) INTO v_already_frozen;

    IF v_already_frozen THEN
      RAISE EXCEPTION 'Session % is already frozen or pending freeze', v_date;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public._freeze_apply_approved(
  p_freeze_id uuid,
  p_reviewer_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_freeze record;
  v_n integer;
  v_original date;
  v_new date;
BEGIN
  SELECT * INTO v_freeze
  FROM public.booking_freezes
  WHERE id = p_freeze_id
  FOR UPDATE;

  IF v_freeze IS NULL THEN
    RAISE EXCEPTION 'Freeze request not found';
  END IF;

  IF v_freeze.status = 'approved' THEN
    RETURN v_freeze.id;
  END IF;

  IF v_freeze.status NOT IN ('pending') THEN
    RAISE EXCEPTION 'Freeze request cannot be approved (status=%)', v_freeze.status;
  END IF;

  SELECT COUNT(*)::integer INTO v_n
  FROM public.booking_freeze_dates
  WHERE freeze_id = p_freeze_id;

  IF v_n <= 0 THEN
    RAISE EXCEPTION 'Freeze request has no session dates';
  END IF;

  SELECT subscription_end::date INTO v_original
  FROM public.bookings
  WHERE id = v_freeze.booking_id
  FOR UPDATE;

  IF v_original IS NULL THEN
    RAISE EXCEPTION 'Booking has no subscription_end';
  END IF;

  v_new := (v_original + (v_n || ' days')::interval)::date;

  UPDATE public.bookings
  SET subscription_end = v_new
  WHERE id = v_freeze.booking_id;

  UPDATE public.booking_freezes
  SET
    status = 'approved',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    original_subscription_end = COALESCE(original_subscription_end, v_original),
    new_subscription_end = v_new,
    updated_at = now()
  WHERE id = p_freeze_id;

  RETURN p_freeze_id;
END;
$$;

-- ───────────────────────────────────────────────────────────────
-- 2. request_booking_freeze (member)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.request_booking_freeze(
  p_booking_id uuid,
  p_session_dates date[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_booking record;
  v_freeze_id uuid;
  v_date date;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking.user_id <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the booking owner can request a freeze';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.booking_freezes
    WHERE booking_id = p_booking_id AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'A pending freeze request already exists for this booking';
  END IF;

  PERFORM public._freeze_validate_dates(p_booking_id, p_session_dates);

  INSERT INTO public.booking_freezes (
    booking_id, user_id, status, requested_by
  ) VALUES (
    p_booking_id, v_booking.user_id, 'pending', v_uid
  )
  RETURNING id INTO v_freeze_id;

  FOREACH v_date IN ARRAY p_session_dates LOOP
    INSERT INTO public.booking_freeze_dates (freeze_id, booking_id, session_date)
    VALUES (v_freeze_id, p_booking_id, v_date);
  END LOOP;

  RETURN v_freeze_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_booking_freeze(uuid, date[]) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 3. apply_booking_freeze (admin — immediate)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.apply_booking_freeze(
  p_booking_id uuid,
  p_session_dates date[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_booking record;
  v_freeze_id uuid;
  v_date date;
  v_n integer;
  v_original date;
  v_new date;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can apply a freeze';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  PERFORM public._freeze_validate_dates(p_booking_id, p_session_dates);

  -- Cancel any pending request for this booking (admin override)
  UPDATE public.booking_freezes
  SET status = 'cancelled', updated_at = now(), reviewed_by = v_uid, reviewed_at = now()
  WHERE booking_id = p_booking_id AND status = 'pending';

  v_n := cardinality(p_session_dates);
  v_original := v_booking.subscription_end::date;
  IF v_original IS NULL THEN
    RAISE EXCEPTION 'Booking has no subscription_end';
  END IF;
  v_new := (v_original + (v_n || ' days')::interval)::date;

  INSERT INTO public.booking_freezes (
    booking_id, user_id, status, requested_by, reviewed_by, reviewed_at,
    original_subscription_end, new_subscription_end
  ) VALUES (
    p_booking_id, v_booking.user_id, 'approved', v_uid, v_uid, now(),
    v_original, v_new
  )
  RETURNING id INTO v_freeze_id;

  FOREACH v_date IN ARRAY p_session_dates LOOP
    INSERT INTO public.booking_freeze_dates (freeze_id, booking_id, session_date)
    VALUES (v_freeze_id, p_booking_id, v_date);
  END LOOP;

  UPDATE public.bookings
  SET subscription_end = v_new
  WHERE id = p_booking_id;

  RETURN v_freeze_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_booking_freeze(uuid, date[]) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 4. review_booking_freeze (admin approve/reject)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.review_booking_freeze(
  p_freeze_id uuid,
  p_approve boolean
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_freeze record;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can review freeze requests';
  END IF;

  SELECT * INTO v_freeze
  FROM public.booking_freezes
  WHERE id = p_freeze_id
  FOR UPDATE;

  IF v_freeze IS NULL THEN
    RAISE EXCEPTION 'Freeze request not found';
  END IF;

  IF v_freeze.status <> 'pending' THEN
    RAISE EXCEPTION 'Freeze request is not pending';
  END IF;

  IF p_approve THEN
    RETURN public._freeze_apply_approved(p_freeze_id, v_uid);
  END IF;

  UPDATE public.booking_freezes
  SET
    status = 'rejected',
    reviewed_by = v_uid,
    reviewed_at = now(),
    updated_at = now()
  WHERE id = p_freeze_id;

  RETURN p_freeze_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.review_booking_freeze(uuid, boolean) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 5. List RPCs (admin)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_pending_freeze_requests()
RETURNS TABLE (
  freeze_id uuid,
  booking_id uuid,
  user_id uuid,
  full_name text,
  avatar_url text,
  coach_name text,
  session_dates date[],
  created_at timestamptz,
  current_subscription_end date
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can list freeze requests';
  END IF;

  RETURN QUERY
  SELECT
    bf.id AS freeze_id,
    bf.booking_id,
    bf.user_id,
    COALESCE(p.full_name, 'Member')::text AS full_name,
    p.avatar_url::text,
    COALESCE(c.name, 'Coach')::text AS coach_name,
    (
      SELECT array_agg(fd.session_date ORDER BY fd.session_date)
      FROM public.booking_freeze_dates fd
      WHERE fd.freeze_id = bf.id
    ) AS session_dates,
    bf.created_at,
    b.subscription_end::date AS current_subscription_end
  FROM public.booking_freezes bf
  JOIN public.bookings b ON b.id = bf.booking_id
  JOIN public.profiles p ON p.id = bf.user_id
  LEFT JOIN public.coaches c ON c.id = b.coach_id
  WHERE bf.status = 'pending'
  ORDER BY bf.created_at ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_pending_freeze_requests() TO authenticated;

CREATE OR REPLACE FUNCTION public.get_active_booking_freezes()
RETURNS TABLE (
  freeze_id uuid,
  booking_id uuid,
  user_id uuid,
  full_name text,
  avatar_url text,
  coach_name text,
  session_dates date[],
  original_subscription_end date,
  new_subscription_end date,
  approved_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can list active freezes';
  END IF;

  RETURN QUERY
  SELECT
    bf.id AS freeze_id,
    bf.booking_id,
    bf.user_id,
    COALESCE(p.full_name, 'Member')::text AS full_name,
    p.avatar_url::text,
    COALESCE(c.name, 'Coach')::text AS coach_name,
    (
      SELECT array_agg(fd.session_date ORDER BY fd.session_date)
      FROM public.booking_freeze_dates fd
      WHERE fd.freeze_id = bf.id
    ) AS session_dates,
    bf.original_subscription_end,
    bf.new_subscription_end,
    bf.reviewed_at AS approved_at
  FROM public.booking_freezes bf
  JOIN public.bookings b ON b.id = bf.booking_id
  JOIN public.profiles p ON p.id = bf.user_id
  LEFT JOIN public.coaches c ON c.id = b.coach_id
  WHERE bf.status = 'approved'
  ORDER BY bf.reviewed_at DESC NULLS LAST, bf.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_active_booking_freezes() TO authenticated;

CREATE OR REPLACE FUNCTION public.get_freeze_dashboard_count()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can read freeze dashboard count';
  END IF;

  RETURN (
    SELECT COUNT(*)::integer
    FROM public.booking_freezes
    WHERE status = 'pending'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_freeze_dashboard_count() TO authenticated;

-- Optional: booking end + subscription window for freeze UI
CREATE OR REPLACE FUNCTION public.get_booking_freeze_context(p_booking_id uuid)
RETURNS TABLE (
  booking_id uuid,
  user_id uuid,
  subscription_end date,
  subscription_start date,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_booking record;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
  IF v_booking IS NULL THEN
    RETURN;
  END IF;

  IF v_booking.user_id <> v_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  booking_id := v_booking.id;
  user_id := v_booking.user_id;
  subscription_end := v_booking.subscription_end::date;
  subscription_start := v_booking.subscription_start::date;
  status := v_booking.status;
  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_booking_freeze_context(uuid) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 6. Patch get_booking_sessions — frozen status + makeup cap
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_booking_sessions(
  p_booking_id uuid
)
RETURNS TABLE (
  session_date date,
  day_name text,
  status text,
  is_attended boolean,
  can_re_attend boolean,
  can_unmark boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking record;
  v_start_date date;
  v_end_date date;
  v_current_date date := CURRENT_DATE;
  v_session_date date;
  v_day_name text;
  v_is_attended boolean;
  v_is_frozen boolean;
  v_status text;
  v_can_re_attend boolean;
  v_can_unmark boolean;
  v_total_sessions integer;
  v_frozen_count integer := 0;
  v_session_count integer := 0;
  v_cap integer;
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_booking IS NULL THEN
    RETURN;
  END IF;

  v_start_date := v_booking.subscription_start::date;
  v_end_date := v_booking.subscription_end::date;

  SELECT COALESCE(bp.total_sessions, 0)
  INTO v_total_sessions
  FROM public.booking_progress bp
  WHERE bp.booking_id = p_booking_id;

  IF v_total_sessions IS NULL OR v_total_sessions <= 0 THEN
    SELECT COALESCE(
      cs.sessions_per_week,
      NULLIF(array_length(v_booking.selected_days, 1), 0),
      1
    ) * GREATEST(
      1,
      ((v_end_date - v_start_date) / 7) + 1
    )
    INTO v_total_sessions
    FROM public.coach_sessions cs
    WHERE cs.id = v_booking.session_id
    LIMIT 1;

    v_total_sessions := COALESCE(v_total_sessions, 0);
  END IF;

  SELECT COUNT(*)::integer INTO v_frozen_count
  FROM public.booking_freeze_dates fd
  JOIN public.booking_freezes bf ON bf.id = fd.freeze_id
  WHERE fd.booking_id = p_booking_id
    AND bf.status = 'approved';

  v_cap := v_total_sessions + COALESCE(v_frozen_count, 0);

  FOR v_session_date IN
    SELECT generate_series(v_start_date, v_end_date, '1 day'::interval)::date
    ORDER BY 1
  LOOP
    EXIT WHEN v_cap > 0 AND v_session_count >= v_cap;

    v_day_name := trim(to_char(v_session_date, 'Day'));

    IF EXISTS (
      SELECT 1
      FROM unnest(v_booking.selected_days) AS d(raw_day)
      WHERE lower(trim(d.raw_day)) = lower(v_day_name)
         OR lower(left(trim(d.raw_day), 3)) = lower(left(v_day_name, 3))
    ) THEN
      SELECT EXISTS (
        SELECT 1
        FROM public.attendance a
        WHERE a.booking_id = p_booking_id
          AND a.attended_on = v_session_date
          AND lower(coalesce(a.status, '')) = 'attended'
      ) INTO v_is_attended;

      SELECT EXISTS (
        SELECT 1
        FROM public.booking_freeze_dates fd
        JOIN public.booking_freezes bf ON bf.id = fd.freeze_id
        WHERE fd.booking_id = p_booking_id
          AND fd.session_date = v_session_date
          AND bf.status = 'approved'
      ) INTO v_is_frozen;

      v_can_unmark := false;
      v_can_re_attend := false;

      IF v_is_attended THEN
        v_status := 'completed';
        v_can_unmark := true;
      ELSIF v_is_frozen THEN
        v_status := 'frozen';
      ELSIF v_session_date > v_current_date THEN
        v_status := 'upcoming';
      ELSIF v_session_date = v_current_date THEN
        v_status := 'today';
        v_can_re_attend := true;
      ELSE
        v_status := 'missed';
        v_can_re_attend := true;
      END IF;

      session_date := v_session_date;
      day_name := v_day_name;
      status := v_status;
      is_attended := v_is_attended;
      can_re_attend := v_can_re_attend;
      can_unmark := v_can_unmark;

      v_session_count := v_session_count + 1;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_booking_sessions(uuid) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 7. Patch get_dashboard_low_attendance_members — exclude frozen
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_dashboard_low_attendance_members(
  p_days integer DEFAULT 14,
  p_limit integer DEFAULT 10
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  avatar_url text,
  attended_count integer,
  expected_count integer,
  attendance_rate numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_days integer := GREATEST(1, LEAST(COALESCE(p_days, 14), 30));
  v_limit integer := GREATEST(1, LEAST(COALESCE(p_limit, 10), 25));
  v_start date := (CURRENT_DATE - (v_days - 1));
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can list low-attendance members';
  END IF;

  RETURN QUERY
  WITH active_bookings AS (
    SELECT
      b.id AS booking_id,
      b.user_id,
      b.selected_days,
      b.subscription_start,
      b.subscription_end
    FROM public.bookings b
    JOIN public.active_users_with_qr u ON u.user_id = b.user_id
    WHERE lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
      AND lower(coalesce(b.status, '')) IN ('active', 'approved')
      AND (
        b.subscription_end IS NULL
        OR b.subscription_end::date >= v_start
      )
      AND (
        b.subscription_start IS NULL
        OR b.subscription_start::date <= CURRENT_DATE
      )
  ),
  date_range AS (
    SELECT d::date AS session_date
    FROM generate_series(v_start::timestamp, CURRENT_DATE::timestamp, '1 day') AS d
  ),
  expected AS (
    SELECT
      ab.user_id,
      COUNT(*)::integer AS expected_count
    FROM active_bookings ab
    CROSS JOIN date_range dr
    WHERE EXISTS (
      SELECT 1
      FROM unnest(ab.selected_days) AS sd(raw_day)
      WHERE lower(trim(sd.raw_day)) = lower(trim(to_char(dr.session_date, 'Day')))
         OR lower(left(trim(sd.raw_day), 3)) =
            lower(left(trim(to_char(dr.session_date, 'Day')), 3))
    )
    AND (
      ab.subscription_start IS NULL
      OR dr.session_date >= ab.subscription_start::date
    )
    AND (
      ab.subscription_end IS NULL
      OR dr.session_date <= ab.subscription_end::date
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.booking_freeze_dates fd
      JOIN public.booking_freezes bf ON bf.id = fd.freeze_id
      WHERE fd.booking_id = ab.booking_id
        AND fd.session_date = dr.session_date
        AND bf.status = 'approved'
    )
    GROUP BY ab.user_id
  ),
  attended AS (
    SELECT
      a.user_id,
      COUNT(DISTINCT a.attended_on::date)::integer AS attended_count
    FROM public.attendance a
    JOIN public.active_users_with_qr u ON u.user_id = a.user_id
    WHERE a.attended_on::date BETWEEN v_start AND CURRENT_DATE
      AND lower(coalesce(a.status, '')) = 'attended'
    GROUP BY a.user_id
  ),
  member_stats AS (
    SELECT
      u.user_id,
      u.full_name::text,
      p.avatar_url::text,
      e.expected_count,
      COALESCE(at.attended_count, 0) AS attended_count,
      CASE
        WHEN e.expected_count > 0
          THEN COALESCE(at.attended_count, 0)::numeric / e.expected_count
        ELSE NULL
      END AS attendance_rate
    FROM public.active_users_with_qr u
    JOIN public.profiles p ON p.id = u.user_id
    JOIN expected e ON e.user_id = u.user_id
    LEFT JOIN attended at ON at.user_id = u.user_id
    WHERE e.expected_count > 0
  ),
  cohort AS (
    SELECT AVG(ms.attendance_rate) AS avg_rate
    FROM member_stats ms
  )
  SELECT
    ms.user_id,
    ms.full_name,
    ms.avatar_url,
    ms.attended_count,
    ms.expected_count,
    ms.attendance_rate
  FROM member_stats ms
  CROSS JOIN cohort c
  WHERE ms.attended_count = 0
     OR (
       c.avg_rate IS NOT NULL
       AND ms.attendance_rate < (c.avg_rate * 0.5)
     )
  ORDER BY ms.attendance_rate ASC NULLS FIRST, ms.attended_count ASC, ms.full_name ASC
  LIMIT v_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_dashboard_low_attendance_members(
  integer, integer
) TO authenticated;

-- After applying this script, also re-run admin_scan_profile.sql so
-- is_scheduled_today excludes approved frozen dates (Mark Attended CTA).
