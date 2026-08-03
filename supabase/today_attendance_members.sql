-- Admin "Today's attendance" detail: one row per booking expected today.
-- Companion to today_coach_sessions — identical booking eligibility filters so
-- COUNT(*) / COUNT(*) FILTER (is_attended) match Σ booked_count / Σ attended_count.
-- Apply via Supabase SQL editor / MCP migration. Source of truth for app select.
-- security_invoker keeps RLS on underlying tables in effect.

CREATE OR REPLACE VIEW public.today_attendance_members
WITH (security_invoker = true) AS
SELECT
  b.id AS booking_id,
  b.user_id,
  COALESCE(NULLIF(trim(pr.full_name), ''), 'Member') AS member_name,
  pr.photo_url AS member_photo,
  cs.id AS session_id,
  cs.coach_id,
  c.name AS coach_name,
  c.photo_url AS coach_photo,
  trim(
    COALESCE(
      NULLIF(trim(split_part(cs.session_type, ',', d.ord::int)), ''),
      NULLIF(trim(split_part(cs.session_type, ',', 1)), ''),
      cs.session_type
    )
  ) AS session_type,
  COALESCE(
    NULLIF(trim(cs.time_slots[1]), ''),
    'Time TBD'
  ) AS session_time,
  br.name AS branch_name,
  EXISTS (
    SELECT 1
    FROM public.attendance a
    WHERE a.booking_id = b.id
      AND a.attended_on = CURRENT_DATE
      AND lower(coalesce(a.status, '')) = 'attended'
  ) AS is_attended
FROM public.coach_sessions cs
JOIN public.coaches c ON c.id = cs.coach_id
LEFT JOIN public.branches br ON br.id = cs.branch_id
CROSS JOIN LATERAL (
  SELECT day_name, ordinality AS ord
  FROM unnest(COALESCE(cs.days, ARRAY[]::text[])) WITH ORDINALITY AS u(day_name, ordinality)
) d
JOIN public.bookings b
  ON b.session_id = cs.id
 AND lower(coalesce(b.status, '')) = 'active'
 AND lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
 AND CURRENT_DATE BETWEEN b.subscription_start AND b.subscription_end
 AND TRIM(BOTH FROM to_char(CURRENT_DATE::timestamp with time zone, 'Day'::text))
       = ANY (b.selected_days)
 AND (
   b.selected_time IS NULL
   OR trim(b.selected_time) = ''
   OR lower(trim(b.selected_time)) = lower(trim(COALESCE(NULLIF(trim(cs.time_slots[1]), ''), '')))
 )
LEFT JOIN public.profiles pr ON pr.id = b.user_id
WHERE cs.is_active = true
  AND COALESCE(c.is_active, true) = true
  AND trim(d.day_name) = trim(to_char((CURRENT_DATE)::timestamp with time zone, 'Day'::text));

COMMENT ON VIEW public.today_attendance_members IS
  'Members booked on today''s coach sessions with attendance status; counts match today_coach_sessions aggregates.';

GRANT SELECT ON public.today_attendance_members TO authenticated;
GRANT SELECT ON public.today_attendance_members TO anon;
