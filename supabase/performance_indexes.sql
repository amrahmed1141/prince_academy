-- Prince Academy — Performance indexes (run in Supabase SQL Editor)
-- Safe to re-run. Add gym_id indexes when multi-tenant schema is introduced.

-- Bookings
CREATE INDEX IF NOT EXISTS idx_bookings_user_id
  ON public.bookings (user_id);

CREATE INDEX IF NOT EXISTS idx_bookings_coach_id
  ON public.bookings (coach_id);

CREATE INDEX IF NOT EXISTS idx_bookings_created_at
  ON public.bookings (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_subscription_end
  ON public.bookings (subscription_end);

-- Attendance
CREATE INDEX IF NOT EXISTS idx_attendance_booking_id
  ON public.attendance (booking_id);

CREATE INDEX IF NOT EXISTS idx_attendance_user_id
  ON public.attendance (user_id);

CREATE INDEX IF NOT EXISTS idx_attendance_attended_on
  ON public.attendance (attended_on DESC);

CREATE INDEX IF NOT EXISTS idx_attendance_booking_date
  ON public.attendance (booking_id, attended_on);

-- Coaches & sessions
CREATE INDEX IF NOT EXISTS idx_coaches_is_active
  ON public.coaches (is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_coach_sessions_coach_id
  ON public.coach_sessions (coach_id);

CREATE INDEX IF NOT EXISTS idx_coach_sessions_branch_id
  ON public.coach_sessions (branch_id);

CREATE INDEX IF NOT EXISTS idx_coach_sessions_active
  ON public.coach_sessions (is_active)
  WHERE is_active = true;

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role
  ON public.profiles (role);

CREATE INDEX IF NOT EXISTS idx_profiles_qr_code
  ON public.profiles (qr_code)
  WHERE qr_code IS NOT NULL;

-- Admin member search (see also get_active_users_page.sql)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_profiles_full_name_trgm
  ON public.profiles USING gin (full_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_profiles_phone_trgm
  ON public.profiles USING gin (phone gin_trgm_ops);

-- Future multi-gym (uncomment when gym_id column exists):
-- CREATE INDEX IF NOT EXISTS idx_bookings_gym_id ON public.bookings (gym_id);
-- CREATE INDEX IF NOT EXISTS idx_coaches_gym_id ON public.coaches (gym_id);
-- CREATE INDEX IF NOT EXISTS idx_attendance_gym_id ON public.attendance (gym_id);
