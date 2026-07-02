-- 1. DROP the old functions first to prevent PostgreSQL "cannot change return type" conflicts
DROP FUNCTION IF EXISTS public.get_user_sessions_by_coach(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_user_sessions_by_coach(uuid);

-- 2. CREATE the new corrected function
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
  completed_sessions integer,
  remaining_sessions integer,
  session_date date,          -- Column 11: defined as date
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
    c.specialty::text AS coach_specialty,
    br.name::text AS branch_name,
    b.selected_time::text AS selected_time,
    COALESCE(bp.total_sessions, 0)::integer AS total_sessions,
    COALESCE(bp.attended_sessions, 0)::integer AS completed_sessions,
    (COALESCE(bp.total_sessions, 0) - COALESCE(bp.attended_sessions, 0))::integer AS remaining_sessions,
    bs.session_date::date AS session_date,     -- Cast explicitly to date to resolve the type mismatch
    bs.day_name::text AS day_name,
    true AS is_training_day,
    bs.status::text AS session_status,
    CASE 
      WHEN bs.is_attended THEN 'attended'::text
      ELSE NULL::text
    END AS attendance_status
  FROM bookings b
  JOIN coaches c ON b.coach_id = c.id
  LEFT JOIN profiles p ON c.id = p.id
  LEFT JOIN booking_progress bp ON b.id = bp.booking_id
  LEFT JOIN coach_sessions cs ON b.session_id = cs.id
  LEFT JOIN branches br ON cs.branch_id = br.id
  CROSS JOIN LATERAL get_booking_sessions(b.id) bs
  WHERE b.user_id = p_user_id
    AND (p_coach_id IS NULL OR b.coach_id = p_coach_id)
    AND b.status = 'active';
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_sessions_by_coach(uuid, uuid) TO authenticated;
