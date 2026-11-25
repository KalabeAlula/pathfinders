-- Fix pet energy recovery system
-- 
-- Problem: Energy only drains, never recovers. Pets get stuck at 0 energy in "sleepy" mood.
-- 
-- Changes:
-- 1. Energy regenerates passively at +20/hour (instead of draining at -4/hour)
-- 2. Feed now restores +15 energy (instead of +2)
-- 3. Play drains less energy (-5 instead of -10)
-- 4. Clean no longer drains energy (0 instead of -2)
-- 5. Reset stuck pets to 80 energy

-- First, reset all pets stuck at low energy
update public.circles
   set pet_energy = 80,
       pet_mood = case
         when pet_happiness >= 70 then 'happy'
         when pet_hygiene < 30 then 'dirty'
         when pet_hunger < 30 then 'hungry'
         else 'content'
       end,
       pet_updated_at = now()
 where pet_energy < 20;

-- Recreate care_for_pet with energy recovery
create or replace function public.care_for_pet(
  p_circle_id uuid,
  p_action text
)
returns public.circles
language plpgsql
security definer
set search_path = public
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

  -- Calculate elapsed hours since last update
  v_hours := greatest(
    extract(epoch from (now() - v_circle.pet_updated_at)) / 3600,
    0
  );

  -- Apply passive changes (hunger/hygiene still decay, but energy RECOVERS)
  v_hunger := v_circle.pet_hunger - v_hours * 6;
  v_energy := v_circle.pet_energy + v_hours * 20; -- CHANGED: +20/hour (was -4/hour)
  v_hygiene := v_circle.pet_hygiene - v_hours * 3;
  v_happiness := v_circle.pet_happiness - v_hours * 2.5;

  -- Apply care action bonuses
  if p_action = 'feed' then
    v_hunger := v_hunger + 34;
    v_energy := v_energy + 15;  -- CHANGED: +15 (was +2)
    v_hygiene := v_hygiene - 5;
    v_happiness := v_happiness + 5;
  elsif p_action = 'clean' then
    v_energy := v_energy + 0;   -- CHANGED: 0 (was -2)
    v_hygiene := v_hygiene + 38;
    v_happiness := v_happiness + 7;
  else -- play
    v_hunger := v_hunger - 8;
    v_energy := v_energy - 5;   -- CHANGED: -5 (was -10)
    v_hygiene := v_hygiene - 4;
    v_happiness := v_happiness + 20;
  end if;

  -- Clamp all stats to [0, 100]
  v_hunger := least(100, greatest(0, v_hunger));
  v_energy := least(100, greatest(0, v_energy));
  v_hygiene := least(100, greatest(0, v_hygiene));
  v_happiness := least(100, greatest(0, v_happiness));

  -- Calculate XP and level
  v_experience := v_circle.pet_experience + case p_action
    when 'feed' then 8
    when 'clean' then 6
    else 10
  end;
  v_level := least(99, 1 + v_experience / 100);

  -- Derive mood (priority: sleepy > hungry > dirty > happy > content)
  v_mood := case
    when v_energy < 25 then 'sleepy'
    when v_hunger < 30 then 'hungry'
    when v_hygiene < 30 then 'dirty'
    when v_happiness >= 70 then 'happy'
    else 'content'
  end;

  -- Update circle with new pet state
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

comment on function public.care_for_pet is 
  'Feed, clean, or play with the circle companion. Energy now regenerates passively at +20/hour.';
