-- Prince Academy — Paginated active members for admin tracking
-- Run in Supabase → SQL Editor. Safe to re-run.
--
-- Supports limit/offset + optional search, coach, branch, pending-only filters.
-- Requires public.is_admin() (see booking_flow.sql).

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_profiles_full_name_trgm
  ON public.profiles USING gin (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_phone_trgm
  ON public.profiles USING gin (phone gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_bookings_payment_status_pending
  ON public.bookings (user_id, payment_status)
  WHERE lower(coalesce(payment_status, '')) IN (
    'pending_payment', 'awaiting_verification', 'pending'
  );

DROP FUNCTION IF EXISTS public.get_active_users_page(
  integer, integer, text, uuid, uuid, boolean
);

CREATE OR REPLACE FUNCTION public.get_active_users_page(
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0,
  p_search text DEFAULT NULL,
  p_coach_id uuid DEFAULT NULL,
  p_branch_id uuid DEFAULT NULL,
  p_pending_only boolean DEFAULT NULL
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  phone text,
  qr_code text,
  total_bookings integer,
  active_bookings integer,
  expired_bookings integer,
  latest_subscription_end timestamptz,
  has_pending_payment boolean,
  total_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit integer := GREATEST(1, LEAST(COALESCE(p_limit, 50), 100));
  v_offset integer := GREATEST(0, COALESCE(p_offset, 0));
  v_search text := NULLIF(trim(COALESCE(p_search, '')), '');
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can list members';
  END IF;

  RETURN QUERY
  WITH pending AS (
    SELECT DISTINCT b.user_id
    FROM public.bookings b
    WHERE lower(coalesce(b.payment_status, '')) IN (
      'pending_payment', 'awaiting_verification', 'pending'
    )
  ),
  filtered AS (
    SELECT
      u.user_id,
      u.full_name,
      u.phone,
      u.qr_code,
      u.total_bookings,
      u.active_bookings,
      u.expired_bookings,
      u.latest_subscription_end,
      (p.user_id IS NOT NULL) AS has_pending_payment
    FROM public.active_users_with_qr u
    LEFT JOIN pending p ON p.user_id = u.user_id
    WHERE (
      v_search IS NULL
      OR u.full_name ILIKE '%' || v_search || '%'
      OR coalesce(u.phone, '') ILIKE '%' || v_search || '%'
    )
    AND (
      p_coach_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.user_attendance_history h
        WHERE h.user_id = u.user_id
          AND h.coach_id = p_coach_id
      )
    )
    AND (
      p_branch_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.user_attendance_history h
        WHERE h.user_id = u.user_id
          AND h.branch_id = p_branch_id
      )
    )
    AND (
      p_pending_only IS NULL
      OR p_pending_only = false
      OR p.user_id IS NOT NULL
    )
  )
  SELECT
    f.user_id,
    f.full_name::text,
    f.phone::text,
    f.qr_code::text,
    f.total_bookings::integer,
    f.active_bookings::integer,
    f.expired_bookings::integer,
    f.latest_subscription_end,
    f.has_pending_payment,
    COUNT(*) OVER()::bigint AS total_count
  FROM filtered f
  ORDER BY f.has_pending_payment DESC, f.full_name ASC
  LIMIT v_limit
  OFFSET v_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_active_users_page(
  integer, integer, text, uuid, uuid, boolean
) TO authenticated;
