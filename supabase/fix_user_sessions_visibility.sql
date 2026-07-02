-- ═══════════════════════════════════════════════════════════════
-- Fix: My Sessions returns empty for users with pending bookings
-- that already have attendance (common for cash / admin-marked bookings).
--
-- Run in Supabase → SQL Editor. Safe to re-run.
-- ═══════════════════════════════════════════════════════════════

-- Bookings visible on "My Sessions" — aligned with booking history UX:
-- include active/approved bookings AND pending bookings that have
-- attendance or fall within the current subscription window.
CREATE OR REPLACE FUNCTION public.booking_visible_for_user_sessions(b public.bookings)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT
    lower(coalesce(b.status, '')) NOT IN ('cancelled', 'rejected')
    AND (
      lower(coalesce(b.status, '')) <> 'pending'
      OR EXISTS (
        SELECT 1
        FROM public.attendance a
        WHERE a.booking_id = b.id
      )
      OR (
        b.subscription_start IS NOT NULL
        AND b.subscription_end IS NOT NULL
        AND b.subscription_start::date <= CURRENT_DATE
        AND b.subscription_end::date >= CURRENT_DATE
      )
    );
$$;

DROP FUNCTION IF EXISTS public.get_user_sessions_by_coach(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_coaches(uuid) CASCADE;

CREATE OR REPLACE FUNCTION public.get_user_sessions_by_coach(
  p_user_id uuid,
  p_coach_id uuid DEFAULT NULL
)
RETURNS TABLE (
  booking_id uuid,
  coach_id uuid,
  coach_name text,
  coach_photo text,
  coach_specialty text,
  branch_name text,
  selected_time text,
  total_sessions integer,
  attended_sessions integer,
  remaining_sessions integer,
  session_date date,
  day_name text,
  is_training_day boolean,
  session_status text,
  attendance_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.id AS booking_id,
    c.id AS coach_id,
    COALESCE(p.full_name, c.name)::text AS coach_name,
    c.photo_url::text AS coach_photo,
    COALESCE(c.specialty, '')::text AS coach_specialty,
    br.name::text AS branch_name,
    b.selected_time::text AS selected_time,
    COALESCE(bp.total_sessions, 0)::integer AS total_sessions,
    COALESCE(bp.attended_sessions, 0)::integer AS attended_sessions,
    (COALESCE(bp.total_sessions, 0) - COALESCE(bp.attended_sessions, 0))::integer
      AS remaining_sessions,
    bs.session_date::date AS session_date,
    bs.day_name::text AS day_name,
    true AS is_training_day,
    bs.status::text AS session_status,
    CASE
      WHEN bs.is_attended THEN 'attended'::text
      ELSE NULL::text
    END AS attendance_status
  FROM public.bookings b
  JOIN public.coaches c ON c.id = b.coach_id
  LEFT JOIN public.profiles p ON p.id = c.id
  LEFT JOIN public.booking_progress bp ON bp.booking_id = b.id
  LEFT JOIN public.coach_sessions cs ON cs.id = b.session_id
  LEFT JOIN public.branches br ON br.id = COALESCE(b.branch_id, cs.branch_id)
  CROSS JOIN LATERAL public.get_booking_sessions(b.id) bs
  WHERE b.user_id = p_user_id
    AND (p_coach_id IS NULL OR b.coach_id = p_coach_id)
    AND public.booking_visible_for_user_sessions(b);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_coaches(
  p_user_id uuid
)
RETURNS TABLE (
  coach_id uuid,
  coach_name text,
  coach_photo text,
  coach_specialty text,
  total_sessions integer,
  attended_sessions integer,
  remaining_sessions integer,
  active_booking boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ON (c.id)
    c.id AS coach_id,
    COALESCE(p.full_name, c.name)::text AS coach_name,
    c.photo_url::text AS coach_photo,
    COALESCE(c.specialty, '')::text AS coach_specialty,
    COALESCE(bp.total_sessions, 0)::integer AS total_sessions,
    COALESCE(bp.attended_sessions, 0)::integer AS attended_sessions,
    COALESCE(bp.remaining_sessions, 0)::integer AS remaining_sessions,
    (b.subscription_end::date >= CURRENT_DATE) AS active_booking
  FROM public.bookings b
  JOIN public.coaches c ON c.id = b.coach_id
  LEFT JOIN public.profiles p ON p.id = c.id
  LEFT JOIN public.booking_progress bp ON bp.booking_id = b.id
  WHERE b.user_id = p_user_id
    AND public.booking_visible_for_user_sessions(b)
  ORDER BY c.id, b.subscription_end DESC NULLS LAST;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_sessions_by_coach(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_coaches(uuid) TO authenticated;
