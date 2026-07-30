-- Admin "Today's Sessions" list: scheduled coach sessions for the current weekday.
-- Apply via Supabase SQL editor / MCP migration. Source of truth for app select.
-- security_invoker keeps RLS on coach_sessions / coaches / branches / bookings in effect.
--
-- Attendance progress (no new table):
--   booked_count   = active verified bookings for this session scheduled today
--   attended_count = of those, rows in public.attendance with status=attended today
-- Same attendance source of truth as QR scan / re_attend / unmark.

CREATE OR REPLACE VIEW public.today_coach_sessions
WITH (security_invoker = true) AS
SELECT
  cs.id AS session_id,
  cs.coach_id,
  c.name AS coach_name,
  c.photo_url AS coach_photo,
  cs.branch_id,
  br.name AS branch_name,
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
  COALESCE(cs.duration_minutes, 60) AS duration_minutes,
  COALESCE(counts.booked_count, 0) AS booked_count,
  COALESCE(counts.attended_count, 0) AS attended_count
FROM public.coach_sessions cs
JOIN public.coaches c ON c.id = cs.coach_id
LEFT JOIN public.branches br ON br.id = cs.branch_id
CROSS JOIN LATERAL (
  SELECT day_name, ordinality AS ord
  FROM unnest(COALESCE(cs.days, ARRAY[]::text[])) WITH ORDINALITY AS u(day_name, ordinality)
) d
LEFT JOIN LATERAL (
  SELECT
    COUNT(*)::integer AS booked_count,
    COUNT(*) FILTER (
      WHERE EXISTS (
        SELECT 1
        FROM public.attendance a
        WHERE a.booking_id = b.id
          AND a.attended_on = CURRENT_DATE
          AND lower(coalesce(a.status, '')) = 'attended'
      )
    )::integer AS attended_count
  FROM public.bookings b
  WHERE b.session_id = cs.id
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
) counts ON true
WHERE cs.is_active = true
  AND COALESCE(c.is_active, true) = true
  AND trim(d.day_name) = trim(to_char((CURRENT_DATE)::timestamp with time zone, 'Day'::text));

COMMENT ON VIEW public.today_coach_sessions IS
  'Active coach_sessions for the current weekday, with coach/branch/duration and today attendance progress (attended/booked).';

GRANT SELECT ON public.today_coach_sessions TO authenticated;
GRANT SELECT ON public.today_coach_sessions TO anon;
