-- ═══════════════════════════════════════════════════════════════
-- Member freeze request list RPC
-- Safe to re-run.
--
-- Callers:
--   BookingFreezeRepository.getMyFreezeRequests
--   MyFreezeRequestsPage (Profile → Freeze Requests)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_my_freeze_requests()
RETURNS TABLE (
  freeze_id uuid,
  booking_id uuid,
  status text,
  coach_name text,
  session_dates date[],
  created_at timestamptz,
  reviewed_at timestamptz,
  original_subscription_end date,
  new_subscription_end date,
  current_subscription_end date
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    bf.id AS freeze_id,
    bf.booking_id,
    bf.status,
    COALESCE(c.name, 'Coach')::text AS coach_name,
    (
      SELECT array_agg(fd.session_date ORDER BY fd.session_date)
      FROM public.booking_freeze_dates fd
      WHERE fd.freeze_id = bf.id
    ) AS session_dates,
    bf.created_at,
    bf.reviewed_at,
    bf.original_subscription_end,
    bf.new_subscription_end,
    b.subscription_end::date AS current_subscription_end
  FROM public.booking_freezes bf
  JOIN public.bookings b ON b.id = bf.booking_id
  LEFT JOIN public.coaches c ON c.id = b.coach_id
  WHERE bf.user_id = auth.uid()
  ORDER BY
    CASE bf.status
      WHEN 'pending' THEN 0
      WHEN 'approved' THEN 1
      WHEN 'rejected' THEN 2
      ELSE 3
    END,
    bf.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_freeze_requests() TO authenticated;
