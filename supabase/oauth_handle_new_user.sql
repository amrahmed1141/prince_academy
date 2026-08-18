-- ═══════════════════════════════════════════════════════════════
-- OAuth profile name: Google / Facebook send `name`, email signup
-- sends `full_name`. handle_new_user must accept both so social
-- users are not stored as "Member".
--
-- Run in Supabase → SQL Editor (safe to re-run).
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_name text;
  v_phone text;
BEGIN
  v_role := lower(trim(coalesce(NEW.raw_user_meta_data ->> 'role', 'user')));
  IF v_role NOT IN ('user', 'admin') THEN
    v_role := 'user';
  END IF;

  v_name := nullif(trim(coalesce(
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'name',
    ''
  )), '');
  v_phone := nullif(trim(coalesce(NEW.raw_user_meta_data ->> 'phone', '')), '');

  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    coalesce(v_name, 'Member'),
    v_phone,
    v_role
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = coalesce(EXCLUDED.full_name, public.profiles.full_name),
    phone = coalesce(EXCLUDED.phone, public.profiles.phone),
    updated_at = now();

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'handle_new_user skipped for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;
