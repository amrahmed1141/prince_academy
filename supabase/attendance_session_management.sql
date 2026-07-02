-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — Attendance session management (RUN IN SUPABASE)
-- Fixes: re_attend_session "updated_at does not exist" error
-- Adds: unmark_session (undo wrong attendance mark)
-- Updates: get_booking_sessions with can_unmark flag
--
-- Run the ENTIRE script in Supabase → SQL Editor → Run.
-- Safe to re-run (idempotent). Re-run if Re-Attend breaks again.
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 0. Schema — attendance must have updated_at (RPC / triggers use it)
-- ───────────────────────────────────────────────────────────────
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Unique index so ON CONFLICT (booking_id, attended_on) works
CREATE UNIQUE INDEX IF NOT EXISTS attendance_booking_date_unique
  ON public.attendance (booking_id, attended_on);

-- Drop ALL overloads of these functions (stale versions cause the updated_at error)
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS func
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname IN (
        'get_booking_sessions',
        're_attend_session',
        'unmark_session'
      )
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func;
  END LOOP;
END $$;

-- ───────────────────────────────────────────────────────────────
-- 1. get_booking_sessions — all session dates + status flags
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
  v_status text;
  v_can_re_attend boolean;
  v_can_unmark boolean;
  v_total_sessions integer;
  v_session_count integer := 0;
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_booking IS NULL THEN
    RETURN;
  END IF;

  v_start_date := v_booking.subscription_start::date;
  v_end_date := v_booking.subscription_end::date;

  -- Use the package session count (e.g. 12), NOT every matching weekday in the date range.
  -- A calendar month from start→end can include one extra week (e.g. Sun 19/07 → 13 not 12).
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

  FOR v_session_date IN
    SELECT generate_series(v_start_date, v_end_date, '1 day'::interval)::date
    ORDER BY 1
  LOOP
    EXIT WHEN v_total_sessions > 0 AND v_session_count >= v_total_sessions;

    v_day_name := trim(to_char(v_session_date, 'Day'));

    -- Match selected_days whether stored as "Sunday" or "Sun"
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

      v_can_unmark := false;
      v_can_re_attend := false;

      IF v_is_attended THEN
        v_status := 'completed';
        v_can_unmark := true;
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
-- 2. re_attend_session — mark a missed/forgotten session attended
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.re_attend_session(
  p_booking_id uuid,
  p_session_date date
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_coach_id uuid;
  v_admin_id uuid;
  v_exists boolean;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.attendance
    WHERE booking_id = p_booking_id
      AND attended_on = p_session_date
      AND lower(coalesce(status, '')) = 'attended'
  ) INTO v_exists;

  IF v_exists THEN
    RETURN false;
  END IF;

  SELECT b.user_id, b.coach_id
  INTO v_user_id, v_coach_id
  FROM public.bookings b
  WHERE b.id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  INSERT INTO public.attendance (
    booking_id,
    user_id,
    coach_id,
    attended_on,
    status,
    scanned_by,
    created_at
  ) VALUES (
    p_booking_id,
    v_user_id,
    v_coach_id,
    p_session_date,
    'attended',
    v_admin_id,
    now()
  )
  ON CONFLICT (booking_id, attended_on) DO UPDATE
  SET
    status = 'attended',
    scanned_by = v_admin_id,
    updated_at = now();

  RETURN true;
END;
$$;

GRANT EXECUTE ON FUNCTION public.re_attend_session(uuid, date) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 3. unmark_session — undo a wrong attendance mark
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.unmark_session(
  p_booking_id uuid,
  p_session_date date
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid;
  v_deleted integer;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;

  DELETE FROM public.attendance
  WHERE booking_id = p_booking_id
    AND attended_on = p_session_date
    AND lower(coalesce(status, '')) = 'attended';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  RETURN v_deleted > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.unmark_session(uuid, date) TO authenticated;
