-- Run this in the Supabase SQL Editor if coach_sessions does not persist after login.
-- Creates the table (if missing) and RLS policies matching the coaches table pattern.

create table if not exists public.coach_sessions (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coaches(id) on delete cascade,
  sessions_per_week int not null check (sessions_per_week between 1 and 7),
  session_type text not null,
  session_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists coach_sessions_coach_id_idx
  on public.coach_sessions (coach_id);

create index if not exists coach_sessions_is_active_idx
  on public.coach_sessions (is_active);

alter table public.coach_sessions enable row level security;

-- Authenticated users can read active sessions (admin panel + user coach profile)
drop policy if exists "coach_sessions_select_active" on public.coach_sessions;
create policy "coach_sessions_select_active"
  on public.coach_sessions
  for select
  to authenticated
  using (is_active = true);

-- Admins can insert sessions
drop policy if exists "coach_sessions_insert_admin" on public.coach_sessions;
create policy "coach_sessions_insert_admin"
  on public.coach_sessions
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

-- Admins can update sessions
drop policy if exists "coach_sessions_update_admin" on public.coach_sessions;
create policy "coach_sessions_update_admin"
  on public.coach_sessions
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );
