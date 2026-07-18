-- Conflict = another coach at same branch + day + time (class type ignored).
-- Returns coach name, conflicting class type, and time for the dialog message.
drop function if exists public.find_coach_session_conflict(uuid, uuid, text, text[], text[]);

create function public.find_coach_session_conflict(
  p_branch_id uuid,
  p_coach_id uuid,
  p_time_slot text,
  p_days text[],
  p_class_types text[]
)
returns table (coach_name text, class_type text, time_slot text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  i int;
  draft_day text;
  draft_time text;
begin
  if p_branch_id is null
     or p_coach_id is null
     or p_time_slot is null
     or p_days is null
     or array_length(p_days, 1) is null then
    return;
  end if;

  draft_time := lower(trim(regexp_replace(p_time_slot, '\s+', ' ', 'g')));

  for i in 1 .. array_length(p_days, 1) loop
    draft_day := lower(left(trim(p_days[i]), 3));

    if draft_day = '' then
      continue;
    end if;

    return query
    select
      coalesce(nullif(trim(c.name), ''), 'Another coach')::text,
      coalesce(
        nullif(
          trim(
            (
              select trim(types.val)
              from unnest(string_to_array(cs.session_type, ',')) with ordinality as types(val, ord)
              join unnest(cs.days) with ordinality as days(val, ord)
                on days.ord = types.ord
              where lower(left(trim(days.val), 3)) = draft_day
              limit 1
            )
          ),
          ''
        ),
        coalesce(nullif(trim(split_part(cs.session_type, ',', 1)), ''), 'session')
      )::text,
      coalesce(nullif(trim(cs.time_slots[1]), ''), p_time_slot)::text
    from public.coach_sessions cs
    join public.coaches c on c.id = cs.coach_id
    where cs.is_active = true
      and cs.branch_id = p_branch_id
      and cs.coach_id <> p_coach_id
      and lower(trim(regexp_replace(coalesce(cs.time_slots[1], ''), '\s+', ' ', 'g'))) = draft_time
      and exists (
        select 1
        from unnest(cs.days) as d(day)
        where lower(left(trim(d.day), 3)) = draft_day
      )
    limit 1;

    if found then
      return;
    end if;
  end loop;

  return;
end;
$$;

grant execute on function public.find_coach_session_conflict(uuid, uuid, text, text[], text[])
  to authenticated;
