-- Per-circle companion care. Stats live on the circle row so every member
-- reads the same pet through the existing circle realtime channel; care is a
-- single locked RPC that applies offline decay and the action atomically.

alter table public.circles
  add column if not exists pet_experience integer not null default 0
    check (pet_experience >= 0),
  add column if not exists pet_hunger numeric not null default 70
    check (pet_hunger between 0 and 100),
  add column if not exists pet_energy numeric not null default 70
    check (pet_energy between 0 and 100),
  add column if not exists pet_hygiene numeric not null default 70
    check (pet_hygiene between 0 and 100),
  add column if not exists pet_happiness numeric not null default 70
    check (pet_happiness between 0 and 100),
  add column if not exists pet_last_action text
    check (pet_last_action is null or pet_last_action in ('feed', 'clean', 'play')),
  add column if not exists pet_last_action_at timestamptz,
  add column if not exists pet_updated_at timestamptz not null default now();

create or replace function public.care_for_pet(
  p_circle_id uuid,
  p_action text
)
returns public.circles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_circle public.circles;
  v_hours numeric;
  v_hunger numeric;
  v_energy numeric;
  v_hygiene numeric;
  v_happiness numeric;
  v_experience integer;
  v_level integer;
  v_mood text;
begin
  if not public.is_circle_member(p_circle_id) then
    raise exception 'You are not in this circle.' using errcode = '42501';
  end if;

  if p_action is null or p_action not in ('feed', 'clean', 'play') then
    raise exception 'Unknown care action.' using errcode = '22023';
  end if;

  select *
    into v_circle
    from public.circles
   where id = p_circle_id
     for update;

  if not found then
    raise exception 'Circle not found.' using errcode = 'P0002';
  end if;

  -- Same drift rates as the client so a pet left alone does not jump when a
  -- member finally opens the app.
  v_hours := greatest(
    extract(epoch from (now() - v_circle.pet_updated_at)) / 3600,
    0
  );

  v_hunger := v_circle.pet_hunger - v_hours * 6;
  v_energy := v_circle.pet_energy - v_hours * 4;
  v_hygiene := v_circle.pet_hygiene - v_hours * 3;
  v_happiness := v_circle.pet_happiness - v_hours * 2.5;

  if p_action = 'feed' then
    v_hunger := v_hunger + 34;
    v_energy := v_energy + 2;
    v_hygiene := v_hygiene - 5;
    v_happiness := v_happiness + 5;
  elsif p_action = 'clean' then
    v_energy := v_energy - 2;
    v_hygiene := v_hygiene + 38;
    v_happiness := v_happiness + 7;
  else
    v_hunger := v_hunger - 8;
    v_energy := v_energy - 10;
    v_hygiene := v_hygiene - 4;
    v_happiness := v_happiness + 20;
  end if;

  v_hunger := least(100, greatest(0, v_hunger));
  v_energy := least(100, greatest(0, v_energy));
  v_hygiene := least(100, greatest(0, v_hygiene));
  v_happiness := least(100, greatest(0, v_happiness));

  v_experience := v_circle.pet_experience + case p_action
    when 'feed' then 8
    when 'clean' then 6
    else 10
  end;
  v_level := least(99, 1 + v_experience / 100);

  v_mood := case
    when v_energy < 25 then 'sleepy'
    when v_hunger < 30 then 'hungry'
    when v_hygiene < 30 then 'dirty'
    when v_happiness >= 70 then 'happy'
    else 'content'
  end;

  update public.circles
     set pet_experience = v_experience,
         pet_level = v_level,
         pet_hunger = v_hunger,
         pet_energy = v_energy,
         pet_hygiene = v_hygiene,
         pet_happiness = v_happiness,
         pet_mood = v_mood,
         pet_last_action = p_action,
         pet_last_action_at = now(),
         pet_updated_at = now()
   where id = p_circle_id
  returning * into v_circle;

  return v_circle;
end;
$$;

revoke all on function public.care_for_pet(uuid, text) from public, anon;
grant execute on function public.care_for_pet(uuid, text) to authenticated;
