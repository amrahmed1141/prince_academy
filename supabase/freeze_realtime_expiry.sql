-- Live freeze approval → member UI (expiry + freeze list) without pull-to-refresh.
-- Safe to re-run.
--
-- Why:
--   Supabase Realtime filters on non-PK columns (user_id) require
--   REPLICA IDENTITY FULL for UPDATE/DELETE events.
--   booking_freezes must be in supabase_realtime for member freeze list sync.

ALTER TABLE public.bookings REPLICA IDENTITY FULL;
ALTER TABLE public.booking_freezes REPLICA IDENTITY FULL;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_freezes;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
END $$;
