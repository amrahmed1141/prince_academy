-- ═══════════════════════════════════════════════════════════════
-- Coach member counts (public aggregate for member app)
--
-- Members cannot count other users' bookings directly because of
-- bookings RLS. This view + RPC exposes only per-coach totals.
--
-- Run in Supabase → SQL Editor (safe to re-run).
-- ═══════════════════════════════════════════════════════════════

DROP VIEW IF EXISTS public.coach_member_count CASCADE;

CREATE VIEW public.coach_member_count AS
SELECT
  b.coach_id,
  COUNT(DISTINCT b.user_id)::int AS member_count
FROM public.bookings b
WHERE lower(coalesce(b.status, '')) IN ('active', 'pending_payment')
   OR b.payment_status IN (
        'pending_payment',
        'awaiting_verification',
        'verified',
        'active'
      )
GROUP BY b.coach_id;

GRANT SELECT ON public.coach_member_count TO authenticated;

CREATE OR REPLACE FUNCTION public.get_coach_member_counts(p_coach_ids uuid[])
RETURNS TABLE(coach_id uuid, member_count int)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.coach_id,
    c.member_count
  FROM public.coach_member_count c
  WHERE c.coach_id = ANY(p_coach_ids);
$$;

GRANT EXECUTE ON FUNCTION public.get_coach_member_counts(uuid[]) TO authenticated;
