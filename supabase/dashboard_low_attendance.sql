-- Prince Academy — Dashboard low-attendance members preview
-- Run in Supabase → SQL Editor. Safe to re-run.
--
-- Returns active members with zero attendance or a rate well below the
-- cohort average over the last N days (default 14).
-- Caller: AdminDashboardRepository._fetchLowAttendanceMembers()

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
      COALESCE(p.avatar_url, p.photo_url)::text AS member_avatar_url,
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
    ms.member_avatar_url,
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
