-- Pathfinders: profiles, closed circles, and membership.
--
-- Design notes:
--   * One circle per user (enforced by the unique constraint on circle_members.user_id).
--   * The 2..4 seat rule is a product invariant, so the cap lives in the database
--     (advisory-lock + trigger + RPC checks) instead of trusting the client.
--   * Clients never write rows directly. Membership changes go through the
--     SECURITY DEFINER RPCs create_circle / join_circle, which also keep invite
--     codes unique and the seat count honest.
--   * RLS only allows members to read their own circle and each other's profiles.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  avatar_color bigint not null default 4290276175,
  created_at timestamptz not null default now()
);

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 40),
  invite_code text not null unique check (invite_code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Six characters from an unambiguous alphabet (no I, O, 0, 1).
-- Each output character consumes a full byte of UUID randomness modulo 32,
-- which divides evenly, so the distribution stays uniform.
create or replace function public.generate_invite_code()
returns text
language sql
volatile
set search_path = ''
as $$
  with raw as (
    select replace(gen_random_uuid()::text, '-', '') as hex
  )
  select string_agg(
    substr(
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
      (('x' || substr(raw.hex, pos, 2))::bit(8)::int % 32) + 1,
      1
    ),
    '' order by pos
  )
  from raw, generate_series(1, 11, 2) as pos;
$$;

-- SECURITY DEFINER so RLS on circle_members cannot recurse while policies use it.
create or replace function public.is_circle_member(target_circle uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.circle_members
    where circle_id = target_circle
      and user_id = (select auth.uid())
  );
$$;

create or replace function public.shares_circle_with(target_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.circle_members mine
    join public.circle_members theirs on theirs.circle_id = mine.circle_id
    where mine.user_id = (select auth.uid())
      and theirs.user_id = target_user
  );
$$;

-- ---------------------------------------------------------------------------
-- Profile bootstrap
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  fallback_name text;
  final_name text;
begin
  fallback_name := split_part(coalesce(new.email, 'Pathfinder'), '@', 1);
  final_name := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
  if char_length(final_name) = 0 then
    final_name := fallback_name;
  end if;
  final_name := left(final_name, 40);
  if char_length(final_name) = 0 then
    final_name := 'Pathfinder';
  end if;

  insert into public.profiles (id, display_name, avatar_color)
  values (
    new.id,
    final_name,
    (array[4290276175, 4286352491, 4291270476, 4287459208])[
      (mod(abs(hashtext(new.id::text)::bigint), 4)) + 1
    ]
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Seat cap
-- ---------------------------------------------------------------------------

create or replace function public.enforce_circle_capacity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seated integer;
begin
  -- Serialises concurrent joins to the same circle so the count cannot race.
  perform pg_advisory_xact_lock(hashtextextended(new.circle_id::text, 0));

  select count(*) into seated
  from public.circle_members
  where circle_id = new.circle_id;

  if seated >= 4 then
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

create or replace function public.create_circle(p_name text)
returns public.circles
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  clean_name text := btrim(coalesce(p_name, ''));
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

  if exists (select 1 from public.circle_members where user_id = caller) then
    raise exception 'You are already in a circle.' using errcode = '23505';
  end if;

  if not exists (select 1 from public.profiles where id = caller) then
    raise exception 'Your profile is still being set up. Try again in a moment.'
      using errcode = '42501';
  end if;

  loop
    attempt := attempt + 1;
    candidate := public.generate_invite_code();
    begin
      insert into public.circles (name, invite_code, created_by)
      values (clean_name, candidate, caller)
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
begin
  if caller is null then
    raise exception 'Sign in to join a circle.' using errcode = '42501';
  end if;

  if clean_code !~ '^[A-HJ-NP-Z2-9]{6}$' then
    raise exception 'Invite codes are six letters and numbers.' using errcode = '22023';
  end if;

  if exists (select 1 from public.circle_members where user_id = caller) then
    raise exception 'You are already in a circle.' using errcode = '23505';
  end if;

  select * into target from public.circles where invite_code = clean_code;
  if not found then
    raise exception 'No circle matches that invite code.' using errcode = 'P0002';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(target.id::text, 0));

  select count(*) into seated
  from public.circle_members
  where circle_id = target.id;

  if seated >= 4 then
    raise exception 'This circle is full.' using errcode = '23514';
  end if;

  insert into public.circle_members (circle_id, user_id)
  values (target.id, caller);

  return target;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;

create policy "Read yourself and your circle"
  on public.profiles
  for select
  to authenticated
  using (id = (select auth.uid()) or public.shares_circle_with(id));

create policy "Edit your own profile"
  on public.profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Read your circle"
  on public.circles
  for select
  to authenticated
  using (public.is_circle_member(id));

create policy "Read your circle membership"
  on public.circle_members
  for select
  to authenticated
  using (public.is_circle_member(circle_id));

-- No INSERT/UPDATE/DELETE policies: membership only changes through the RPCs.

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.circles from anon, authenticated;
revoke all on table public.circle_members from anon, authenticated;

grant select on table public.profiles to authenticated;
grant select on table public.circles to authenticated;
grant select on table public.circle_members to authenticated;
grant update (display_name, avatar_color) on table public.profiles to authenticated;

revoke all on function public.generate_invite_code() from public, anon, authenticated;
revoke all on function public.enforce_circle_capacity() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;

revoke all on function public.is_circle_member(uuid) from public, anon;
revoke all on function public.shares_circle_with(uuid) from public, anon;
revoke all on function public.create_circle(text) from public, anon;
revoke all on function public.join_circle(text) from public, anon;

grant execute on function public.is_circle_member(uuid) to authenticated;
grant execute on function public.shares_circle_with(uuid) to authenticated;
grant execute on function public.create_circle(text) to authenticated;
grant execute on function public.join_circle(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'circles'
    ) then
      alter publication supabase_realtime add table public.circles;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'circle_members'
    ) then
      alter publication supabase_realtime add table public.circle_members;
    end if;
  end if;
end;
$$;
