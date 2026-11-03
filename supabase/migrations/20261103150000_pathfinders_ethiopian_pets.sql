-- Ethiopian companion catalog. `pet_id` becomes the source of truth; legacy
-- rows are mapped to a fitting animal and `pet_species` is kept in sync for
-- older reads. A trigger keeps every future row inside the group-type list.

alter table public.circles
  add column if not exists pet_id text;

update public.circles
   set pet_id = case group_type
     when 'couple' then 'lovebird'
     when 'family' then 'walia_ibex'
     else 'gelada'
   end
 where pet_id is null
    or pet_id not in (
      'lovebird', 'ethiopian_wolf', 'gelada', 'bale_monkey', 'walia_ibex', 'lion'
    );

alter table public.circles
  alter column pet_id set not null;

update public.circles
   set pet_species = pet_id
 where pet_species <> pet_id;

alter table public.circles
  drop constraint if exists circles_pet_id_allowed;
alter table public.circles
  add constraint circles_pet_id_allowed
  check (pet_id in (
    'lovebird', 'ethiopian_wolf', 'gelada', 'bale_monkey', 'walia_ibex', 'lion'
  ));

create or replace function public.pet_allowed_for_group(
  p_group_type text,
  p_pet_id text
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case p_group_type
    when 'couple' then p_pet_id in ('lovebird', 'ethiopian_wolf')
    when 'friends' then p_pet_id in ('gelada', 'bale_monkey')
    when 'family' then p_pet_id in ('walia_ibex', 'lion')
    else false
  end;
$$;

create or replace function public.enforce_group_pet()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not public.pet_allowed_for_group(new.group_type, new.pet_id) then
    raise exception 'That companion does not fit this group type.'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists circles_group_pet on public.circles;
create trigger circles_group_pet
  before insert or update of pet_id, group_type on public.circles
  for each row execute function public.enforce_group_pet();

drop function if exists public.create_circle(text, text, text, text);

create or replace function public.create_circle(
  p_name text,
  p_group_type text default 'friends',
  p_pet_id text default 'gelada',
  p_pet_name text default 'Chele'
)
returns public.circles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  clean_name text := btrim(coalesce(p_name, ''));
  clean_type text := lower(btrim(coalesce(p_group_type, 'friends')));
  clean_pet_id text := lower(btrim(coalesce(p_pet_id, 'gelada')));
  clean_pet text := btrim(coalesce(p_pet_name, 'Chele'));
  created public.circles;
  candidate text;
  attempt integer := 0;
begin
  if caller is null then
    raise exception 'Sign in to create a circle.' using errcode = '42501';
  end if;

  if char_length(clean_name) < 1 or char_length(clean_name) > 40 then
    raise exception 'Give your circle a name between 1 and 40 characters.'
      using errcode = '22023';
  end if;

  if clean_type not in ('couple', 'friends', 'family') then
    raise exception 'Pick a group type: couple, friends, or family.'
      using errcode = '22023';
  end if;

  if not public.pet_allowed_for_group(clean_type, clean_pet_id) then
    raise exception 'That companion does not fit this group type.'
      using errcode = '23514';
  end if;

  if char_length(clean_pet) < 1 or char_length(clean_pet) > 24 then
    raise exception 'Give your pet a name between 1 and 24 characters.'
      using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles where id = caller) then
    raise exception 'Your profile is still being set up. Try again in a moment.'
      using errcode = '42501';
  end if;

  loop
    attempt := attempt + 1;
    candidate := public.generate_invite_code();
    begin
      insert into public.circles (
        name,
        invite_code,
        created_by,
        group_type,
        pet_id,
        pet_species,
        pet_name
      )
      values (
        clean_name,
        candidate,
        caller,
        clean_type,
        clean_pet_id,
        clean_pet_id,
        clean_pet
      )
      returning * into created;
      exit;
    exception when unique_violation then
      if attempt >= 8 then
        raise exception 'Could not reserve an invite code. Please try again.'
          using errcode = 'P0001';
      end if;
    end;
  end loop;

  insert into public.circle_members (circle_id, user_id)
  values (created.id, caller);

  return created;
end;
$$;

revoke all on function public.pet_allowed_for_group(text, text)
  from public, anon, authenticated;
revoke all on function public.create_circle(text, text, text, text)
  from public, anon;
grant execute on function public.create_circle(text, text, text, text)
  to authenticated;
