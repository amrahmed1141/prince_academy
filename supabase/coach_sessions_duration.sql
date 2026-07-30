-- Add session duration (minutes) to coach_sessions.
-- Used by admin Create Session / Edit Session forms.
-- Applied remotely via Supabase MCP migration: add_coach_sessions_duration_minutes

ALTER TABLE public.coach_sessions
  ADD COLUMN IF NOT EXISTS duration_minutes integer NOT NULL DEFAULT 60
    CHECK (duration_minutes > 0 AND duration_minutes <= 480);

COMMENT ON COLUMN public.coach_sessions.duration_minutes IS
  'Length of each scheduled session in minutes (e.g. 60, 90).';
