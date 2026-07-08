-- ═══════════════════════════════════════════════════════════════
-- Prince Academy — Monthly subscription pricing for bookings
--
-- Pricing tiers (based on selected_days count = sessions per week):
--   3 sessions/week → 12 sessions/month → full monthly price (e.g. 1000 EGP)
--   2 sessions/week →  8 sessions/month → 80% of full price  (e.g.  800 EGP)
--   1 session/week  →  4 sessions/month → 1/3 of full price
--
-- Run the ENTIRE script in Supabase → SQL Editor → Run.
-- Safe to re-run (idempotent).
-- ═══════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────
-- 1. Pricing helpers
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.monthly_session_count(p_sessions_per_week integer)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT GREATEST(COALESCE(p_sessions_per_week, 0), 0) * 4;
$$;

CREATE OR REPLACE FUNCTION public.monthly_subscription_price(
  p_full_monthly_price numeric,
  p_sessions_per_week integer
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN COALESCE(p_full_monthly_price, 0) <= 0
      OR COALESCE(p_sessions_per_week, 0) <= 0 THEN 0::numeric
    WHEN p_sessions_per_week >= 3 THEN p_full_monthly_price
    WHEN p_sessions_per_week = 2 THEN round(p_full_monthly_price * 0.8, 2)
    WHEN p_sessions_per_week = 1 THEN round(p_full_monthly_price / 3, 2)
    ELSE p_full_monthly_price
  END;
$$;

GRANT EXECUTE ON FUNCTION public.monthly_session_count(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.monthly_subscription_price(numeric, integer) TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 2. Enforce monthly price on booking insert/update
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_booking_pricing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_base_price numeric;
  v_sessions_per_week integer;
BEGIN
  v_sessions_per_week := COALESCE(
    NULLIF(array_length(NEW.selected_days, 1), 0),
    1
  );

  SELECT cs.price_per_session
  INTO v_base_price
  FROM public.coach_sessions cs
  WHERE cs.id = NEW.session_id
  LIMIT 1;

  IF v_base_price IS NULL OR v_base_price <= 0 THEN
    v_base_price := COALESCE(NEW.total_price, 0);
  END IF;

  NEW.total_price := public.monthly_subscription_price(
    v_base_price,
    v_sessions_per_week
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_booking_pricing ON public.bookings;
CREATE TRIGGER trg_set_booking_pricing
  BEFORE INSERT OR UPDATE OF selected_days, session_id, total_price
  ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_booking_pricing();

-- ───────────────────────────────────────────────────────────────
-- 3. booking_progress — use monthly session count (8 / 12 / …)
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.booking_progress AS
SELECT
  b.id AS booking_id,
  b.user_id,
  b.coach_id,
  public.monthly_session_count(
    COALESCE(array_length(b.selected_days, 1), 0)
  ) AS total_sessions,
  COUNT(a.id) FILTER (WHERE a.status = 'attended') AS attended_sessions,
  public.monthly_session_count(
    COALESCE(array_length(b.selected_days, 1), 0)
  ) - COUNT(a.id) FILTER (WHERE a.status = 'attended') AS remaining_sessions
FROM public.bookings b
LEFT JOIN public.attendance a
  ON a.booking_id = b.id
 AND a.status = 'attended'
GROUP BY b.id;

GRANT SELECT ON public.booking_progress TO authenticated;

-- ───────────────────────────────────────────────────────────────
-- 4. Subscription renewal — keep the same monthly tier price
-- ───────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.renew_booking_subscription(p_booking_id uuid)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings;
  v_base_price numeric;
  v_sessions_per_week integer;
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  v_sessions_per_week := COALESCE(
    NULLIF(array_length(v_booking.selected_days, 1), 0),
    1
  );

  SELECT cs.price_per_session
  INTO v_base_price
  FROM public.coach_sessions cs
  WHERE cs.id = v_booking.session_id
  LIMIT 1;

  UPDATE public.bookings
  SET
    subscription_start = CURRENT_DATE,
    subscription_end = (CURRENT_DATE + INTERVAL '1 month')::date,
    total_price = public.monthly_subscription_price(
      COALESCE(v_base_price, v_booking.total_price),
      v_sessions_per_week
    ),
    status = 'approved',
    updated_at = now()
  WHERE id = p_booking_id
  RETURNING * INTO v_booking;

  RETURN v_booking;
END;
$$;

GRANT EXECUTE ON FUNCTION public.renew_booking_subscription(uuid) TO authenticated;
