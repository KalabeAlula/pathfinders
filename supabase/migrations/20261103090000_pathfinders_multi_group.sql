-- Pathfinders: multiple groups per member, group types with hard caps, and a
-- per-group pet companion.
--
-- Existing circles become 'friends' (the historical four-seat ceiling), so
-- current memberships, chats, memories, milestones, and status rows keep
-- working with no backfill and no downtime.
--
-- Seat caps still live in the database: the advisory lock plus trigger plus
-- RPC checks are the only trusted authority, the client merely renders them.

-- ---------------------------------------------------------------------------
-- Group type and pet metadata
-- ---------------------------------------------------------------------------

alter table public.circles
  add column if not exists group_type text not null default 'friends'
    check (group_type in ('couple', 'friends', 'family')),
  add column if not exists pet_species text not null default 'capybara'
    check (char_length(pet_species) between 1 and 32),
  add column if not exists pet_name text not null default 'Momo'
    check (char_length(pet_name) between 1 and 24),
  add column if not exists pet_level integer not null default 1
    check (pet_level between 1 and 99),
  add column if not exists pet_mood text not null default 'content'
    check (pet_mood in ('happy', 'content', 'hungry', 'sleepy', 'dirty', 'playing'));

-- ---------------------------------------------------------------------------
-- Multiple memberships
-- ---------------------------------------------------------------------------

-- A member can now belong to several groups. Lookups by user stay indexed.
alter table public.circle_members
  drop constraint if exists circle_members_user_id_key;

create index if not exists circle_members_user_id_idx
  on public.circle_members (user_id);

-- ---------------------------------------------------------------------------
-- Capacity
-- ---------------------------------------------------------------------------

create or replace function public.circle_capacity(p_type text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_type
    when 'couple' then 2
    when 'family' then 6
    else 4
  end;
$$;

create or replace function public.enforce_circle_capacity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seated integer;
  seat_cap integer;
begin
  -- Serialises concurrent joins to the same circle so the count cannot race.
  perform pg_advisory_xact_lock(hashtextextended(new.circle_id::text, 0));

  select public.circle_capacity(c.group_type) into seat_cap
  from public.circles c
  where c.id = new.circle_id;

  if seat_cap is null then
    raise exception 'No circle matches that invite code.' using errcode = 'P0002';
  end if;

  select count(*) into seated
  from public.circle_members
  where circle_id = new.circle_id;

  if seated >= seat_cap then
    raise exception 'This circle is full.' using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists circle_members_capacity on public.circle_members;
create trigger circle_members_capacity
  before insert on public.circle_members
  for each row execute function public.enforce_circle_capacity();

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

-- The one-argument version enforced a single membership, so it must go.
drop function if exists public.create_circle(text);

create or replace function public.create_circle(
  p_name text,
  p_group_type text default 'friends',
  p_pet_species text default 'capybara',
  p_pet_name text default 'Momo'
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
  clean_species text := lower(btrim(coalesce(p_pet_species, 'capybara')));
  clean_pet text := btrim(coalesce(p_pet_name, 'Momo'));
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

  if char_length(clean_species) < 1 or char_length(clean_species) > 32 then
    raise exception 'Pick a pet companion.' using errcode = '22023';
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
        pet_species,
        pet_name
      )
      values (
        clean_name,
        candidate,
        caller,
        clean_type,
        clean_species,
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

create or replace function public.join_circle(p_code text)
returns public.circles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  clean_code text := upper(btrim(coalesce(p_code, '')));
  target public.circles;
  seated integer;
  seat_cap integer;
begin
  if caller is null then
    raise exception 'Sign in to join a circle.' using errcode = '42501';
  end if;

  if clean_code !~ '^[A-HJ-NP-Z2-9]{6}$' then
    raise exception 'Invite codes are six letters and numbers.' using errcode = '22023';
  end if;

  select * into target from public.circles where invite_code = clean_code;
  if not found then
    raise exception 'No circle matches that invite code.' using errcode = 'P0002';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(target.id::text, 0));

  if exists (
    select 1
    from public.circle_members
    where circle_id = target.id
      and user_id = caller
  ) then
    raise exception 'You are already in this circle.' using errcode = '23505';
  end if;

  seat_cap := public.circle_capacity(target.group_type);

  select count(*) into seated
  from public.circle_members
  where circle_id = target.id;

  if seated >= seat_cap then
    raise exception 'This circle is full.' using errcode = '23514';
  end if;

  insert into public.circle_members (circle_id, user_id)
  values (target.id, caller);

  return target;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on function public.circle_capacity(text) from public, anon, authenticated;
revoke all on function public.create_circle(text, text, text, text) from public, anon;
revoke all on function public.join_circle(text) from public, anon;

grant execute on function public.create_circle(text, text, text, text) to authenticated;
grant execute on function public.join_circle(text) to authenticated;
