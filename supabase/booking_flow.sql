-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — Booking flow (create_booking_with_schedule + RLS)
--
-- Fixes: "Booking service unavailable" (missing RPC / RLS blocks)
-- Run the ENTIRE script in Supabase → SQL Editor → Run.
-- Safe to re-run (idempotent).
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 0. Ensure is_admin() exists (uses profiles.role, NOT admins table)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 0b. Normalize bookings user column (some schemas use member_id / profile_id)
-- ───────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'bookings'
      AND column_name = 'user_id'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'bookings'
        AND column_name = 'member_id'
    ) THEN
      ALTER TABLE public.bookings RENAME COLUMN member_id TO user_id;
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'bookings'
        AND column_name = 'profile_id'
    ) THEN
      ALTER TABLE public.bookings RENAME COLUMN profile_id TO user_id;
    END IF;
  END IF;
END $$;

-- ───────────────────────────────────────────────────────────────
-- 1. bookings — ensure core columns + payment fields
-- ───────────────────────────────────────────────────────────────
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS coach_id uuid REFERENCES public.coaches(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS session_id uuid REFERENCES public.coach_sessions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS subscription_start date,
  ADD COLUMN IF NOT EXISTS subscription_end date,
  ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'pending_payment',
  ADD COLUMN IF NOT EXISTS payment_reference text,
  ADD COLUMN IF NOT EXISTS payment_deadline date,
  ADD COLUMN IF NOT EXISTS payment_screenshot_url text,
  ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES public.branches(id),
  ADD COLUMN IF NOT EXISTS selected_days text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS selected_time text,
  ADD COLUMN IF NOT EXISTS payment_method text,
  ADD COLUMN IF NOT EXISTS total_price numeric DEFAULT 0;

-- 1b. Fix payment_status check constraint (app uses pending_payment, etc.)
ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS valid_payment_status;

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

-- Allow booking lifecycle statuses used by create_booking / verify_payment
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

-- ───────────────────────────────────────────────────────────────
-- 2. user_schedules table (create or upgrade existing table)
-- ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  session_date date NOT NULL,
  status text NOT NULL DEFAULT 'scheduled',
  attended_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (booking_id, session_date)
);

-- Add columns when table already existed with an older schema
ALTER TABLE public.user_schedules
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS session_date date,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'scheduled',
  ADD COLUMN IF NOT EXISTS attended_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

UPDATE public.user_schedules
SET status = 'scheduled'
WHERE status IS NULL;

UPDATE public.user_schedules
SET created_at = now()
WHERE created_at IS NULL;

-- Backfill user_id from bookings for any existing schedule rows
UPDATE public.user_schedules us
SET user_id = b.user_id
FROM public.bookings b
WHERE us.booking_id = b.id
  AND us.user_id IS NULL
  AND b.user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_schedules_booking_id
  ON public.user_schedules (booking_id);

CREATE INDEX IF NOT EXISTS idx_user_schedules_user_date
  ON public.user_schedules (user_id, session_date);

ALTER TABLE public.user_schedules ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────
-- 3. generate_user_schedules
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.generate_user_schedules(
  p_booking_id uuid,
  p_start_date date,
  p_selected_days text[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_end_date date;
  v_current date;
  v_day_name text;
BEGIN
  SELECT user_id INTO v_user_id
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  DELETE FROM public.user_schedules
  WHERE booking_id = p_booking_id;

  v_end_date := (p_start_date + INTERVAL '1 month')::date;
  v_current := p_start_date;

  WHILE v_current < v_end_date LOOP
    v_day_name := trim(to_char(v_current, 'Day'));

    IF EXISTS (
      SELECT 1
      FROM unnest(p_selected_days) AS d(raw_day)
      WHERE lower(trim(d.raw_day)) = lower(v_day_name)
         OR lower(left(trim(d.raw_day), 3)) = lower(left(v_day_name, 3))
    ) THEN
      INSERT INTO public.user_schedules (
        booking_id,
        user_id,
        session_date,
        status
      ) VALUES (
        p_booking_id,
        v_user_id,
        v_current,
        'scheduled'
      )
      ON CONFLICT (booking_id, session_date) DO NOTHING;
    END IF;

    v_current := v_current + 1;
  END LOOP;
END;
$$;

-- ───────────────────────────────────────────────────────────────
-- 4. create_booking_with_schedule (called by Flutter app)
-- ───────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_booking_with_schedule(
  uuid, uuid, uuid, text[], text, date, numeric, text, text
);

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

-- ───────────────────────────────────────────────────────────────
-- 5. verify_payment (admin QR scan / pending payments)
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
    AND payment_status IN ('pending_payment', 'awaiting_verification');
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_payment(uuid, uuid, text) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 6. Views (drop first — CREATE OR REPLACE cannot rename columns)
-- ───────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.pending_payments CASCADE;
DROP VIEW IF EXISTS public.user_calendar_sessions CASCADE;

CREATE VIEW public.pending_payments AS
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
WHERE b.payment_status IN ('pending_payment', 'awaiting_verification')
  AND lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected');

GRANT SELECT ON public.pending_payments TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 5b. reject_payment (admin rejects InstaPay / invalid payment)
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
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can reject payments';
  END IF;

  UPDATE public.bookings
  SET
    payment_status = 'rejected',
    status = 'rejected',
    updated_at = now()
  WHERE id = p_booking_id
    AND payment_status IN ('pending_payment', 'awaiting_verification');
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_payment(uuid, uuid, text) TO authenticated;

CREATE VIEW public.user_calendar_sessions AS
SELECT
  us.user_id,
  us.session_date,
  us.booking_id,
  c.name AS coach_name
FROM public.user_schedules us
JOIN public.bookings b ON b.id = us.booking_id
JOIN public.coaches c ON c.id = b.coach_id
WHERE lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected')
  AND (
    b.payment_status IN ('verified', 'active')
    OR lower(coalesce(b.status, '')) = 'active'
    OR b.payment_status = 'pending_payment'
  );

GRANT SELECT ON public.user_calendar_sessions TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 7. RLS — fix policies (use is_admin(), not public.admins)
-- ───────────────────────────────────────────────────────────────
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_schedules ENABLE ROW LEVEL SECURITY;

-- Drop old policies that reference public.admins (if any)
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('bookings', 'user_schedules')
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      pol.policyname,
      pol.tablename
    );
  END LOOP;
END $$;

-- bookings: users
CREATE POLICY "bookings_select_own"
  ON public.bookings FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "bookings_insert_own"
  ON public.bookings FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "bookings_update_own_pending"
  ON public.bookings FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    AND payment_status IN ('pending_payment', 'awaiting_verification')
  )
  WITH CHECK (user_id = auth.uid());

-- bookings: admins
CREATE POLICY "bookings_select_admin"
  ON public.bookings FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "bookings_update_admin"
  ON public.bookings FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "bookings_insert_admin"
  ON public.bookings FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

-- user_schedules: users
CREATE POLICY "user_schedules_select_own"
  ON public.user_schedules FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- user_schedules: admins
CREATE POLICY "user_schedules_select_admin"
  ON public.user_schedules FOR SELECT TO authenticated
  USING (public.is_admin());

CREATE POLICY "user_schedules_update_admin"
  ON public.user_schedules FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- RPCs run as SECURITY DEFINER and insert schedules — no user INSERT policy needed
