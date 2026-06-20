-- Fix: "infinite recursion detected in policy for relation profiles" (42P17)
--
-- Cause: An RLS policy on `profiles` queries `profiles` again (e.g. to check
-- admin role), which re-triggers the same policy forever.
--
-- Run this entire script in Supabase → SQL Editor.
-- Safe to re-run (drops and recreates policies).

-- ---------------------------------------------------------------------------
-- 1. Helper: check admin role WITHOUT triggering RLS recursion
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Ensure profiles table exists (skip if you already have it)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'user' check (role in ('user', 'admin')),
  qr_code text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- ---------------------------------------------------------------------------
-- 3. Remove ALL existing profiles policies (names may vary in your project)
-- ---------------------------------------------------------------------------
do $$
declare
  pol record;
begin
  for pol in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
  loop
    execute format(
      'drop policy if exists %I on public.profiles',
      pol.policyname
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Correct policies (no self-referencing subqueries on profiles)
-- ---------------------------------------------------------------------------

-- Every signed-in user can read their own row (required after login)
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

-- Admins can read any profile (scanner, admin panel)
create policy "profiles_select_admin"
  on public.profiles
  for select
  to authenticated
  using (public.is_admin());

-- User creates their own profile on sign-up
create policy "profiles_insert_own"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

-- User updates their own profile (e.g. qr_code after first booking)
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Admins can update any profile
create policy "profiles_update_admin"
  on public.profiles
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- 5. Optional: auto-create profile row when a new auth user signs up
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'role', 'user')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 6. Fix coach_sessions admin policies to use is_admin() (avoids extra lookups)
-- ---------------------------------------------------------------------------
drop policy if exists "coach_sessions_insert_admin" on public.coach_sessions;
create policy "coach_sessions_insert_admin"
  on public.coach_sessions
  for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "coach_sessions_update_admin" on public.coach_sessions;
create policy "coach_sessions_update_admin"
  on public.coach_sessions
  for update
  to authenticated
  using (public.is_admin());
