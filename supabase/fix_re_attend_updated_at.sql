-- Quick fix: "column updated_at of relation attendance does not exist"
-- Run in Supabase → SQL Editor → Run (safe to re-run)

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS attendance_booking_date_unique
  ON public.attendance (booking_id, attended_on);

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS func
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname = 're_attend_session'
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func;
  END LOOP;
END $$;

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
