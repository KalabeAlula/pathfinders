-- Pathfinders: live telemetry for a circle.
--
-- The sharing promise is enforced by the database, not the client:
--   * exact       -> the fix is stored as reported.
--   * approximate -> coordinates are snapped to a ~330 m grid, arrival times
--                    are dropped, and accuracy is floored at 150 m.
--   * paused      -> no coordinates are stored at all. Battery and presence
--                    keep flowing so the circle still knows you are safe.
--
-- Because a stored row only ever holds what the chosen mode allows, members
-- can read it directly under RLS and realtime can stream it without a second
-- masking pass. Switching modes rewrites the stored row immediately, so the
-- old precision is gone before the next reading arrives.
--
-- Clients never insert or update rows: report_status / set_privacy_mode are
-- the only write paths, and both read the mode from the database rather than
-- trusting the payload.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.member_status (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  latitude double precision,
  longitude double precision,
  accuracy_meters double precision not null default 0,
  battery_percent smallint,
  is_charging boolean not null default false,
  speed_kph double precision not null default 0,
  privacy_mode text not null default 'exact',
  arrived_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint member_status_mode_check
    check (privacy_mode in ('exact', 'approximate', 'paused')),
  constraint member_status_pair_check
    check ((latitude is null) = (longitude is null)),
  constraint member_status_lat_check
    check (latitude is null or latitude between -90 and 90),
  constraint member_status_lon_check
    check (longitude is null or longitude between -180 and 180),
  constraint member_status_accuracy_check check (accuracy_meters >= 0),
  constraint member_status_battery_check
    check (battery_percent is null or battery_percent between 0 and 100),
  constraint member_status_speed_check check (speed_kph >= 0)
);

-- ---------------------------------------------------------------------------
-- Writes
-- ---------------------------------------------------------------------------

create or replace function public.report_status(
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_meters double precision,
  p_battery_percent integer,
  p_is_charging boolean,
  p_speed_kph double precision
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  mode text;
  has_fix boolean := p_latitude is not null and p_longitude is not null;
  prev_lat double precision;
  prev_lon double precision;
  prev_arrived timestamptz;
  next_lat double precision;
  next_lon double precision;
  next_accuracy double precision := 0;
  next_speed double precision := 0;
  next_arrived timestamptz;
  shifted_meters double precision;
begin
  if caller is null then
    raise exception 'Sign in to share your status.' using errcode = '42501';
  end if;

  if not exists (select 1 from public.circle_members where user_id = caller) then
    raise exception 'Join a circle before sharing your status.'
      using errcode = '42501';
  end if;

  if has_fix and (
    p_latitude not between -90 and 90
    or p_longitude not between -180 and 180
  ) then
    raise exception 'That location is out of range.' using errcode = '22023';
  end if;

  select s.privacy_mode, s.latitude, s.longitude, s.arrived_at
    into mode, prev_lat, prev_lon, prev_arrived
    from public.member_status s
   where s.user_id = caller;

  mode := coalesce(mode, 'exact');

  -- A paused member transmits no coordinates, even if the client sent some.
  if mode = 'paused' then
    has_fix := false;
  end if;

  if has_fix then
    if mode = 'approximate' then
      next_lat := round((p_latitude / 0.003)::numeric) * 0.003::double precision;
      next_lon := round((p_longitude / 0.003)::numeric) * 0.003::double precision;
      next_accuracy := greatest(coalesce(p_accuracy_meters, 0), 150);
      next_arrived := null;
    else
      next_lat := p_latitude;
      next_lon := p_longitude;
      next_accuracy := greatest(coalesce(p_accuracy_meters, 0), 0);
      next_arrived := prev_arrived;

      if prev_lat is null or prev_lon is null then
        next_arrived := now();
      else
        -- Flat-earth approximation; only needs to resolve a ~120 m radius.
        shifted_meters := sqrt(
          power(next_lat - prev_lat, 2) +
          power((next_lon - prev_lon) * cos(radians(prev_lat)), 2)
        ) * 111320;

        if shifted_meters > 120 then
          next_arrived := now();
        end if;
      end if;
    end if;

    next_speed := greatest(coalesce(p_speed_kph, 0), 0);
  end if;

  insert into public.member_status as s (
    user_id,
    latitude,
    longitude,
    accuracy_meters,
    battery_percent,
    is_charging,
    speed_kph,
    privacy_mode,
    arrived_at,
    updated_at
  )
  values (
    caller,
    next_lat,
    next_lon,
    next_accuracy,
    case
      when p_battery_percent is null then null
      else least(greatest(p_battery_percent, 0), 100)::smallint
    end,
    coalesce(p_is_charging, false),
    next_speed,
    mode,
    next_arrived,
    now()
  )
  on conflict (user_id) do update set
    latitude = case
      when excluded.privacy_mode = 'paused' then null
      when excluded.latitude is not null then excluded.latitude
      else s.latitude
    end,
    longitude = case
      when excluded.privacy_mode = 'paused' then null
      when excluded.longitude is not null then excluded.longitude
      else s.longitude
    end,
    accuracy_meters = case
      when excluded.privacy_mode = 'paused' then 0
      when excluded.latitude is not null then excluded.accuracy_meters
      else s.accuracy_meters
    end,
    battery_percent = coalesce(excluded.battery_percent, s.battery_percent),
    is_charging = excluded.is_charging,
    speed_kph = case
      when excluded.privacy_mode = 'paused' then 0
      when excluded.latitude is not null then excluded.speed_kph
      else s.speed_kph
    end,
    privacy_mode = excluded.privacy_mode,
    arrived_at = case
      when excluded.privacy_mode = 'paused' then null
      when excluded.latitude is not null then excluded.arrived_at
      else s.arrived_at
    end,
    updated_at = now();
end;
$$;

create or replace function public.set_privacy_mode(p_mode text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  clean_mode text := lower(btrim(coalesce(p_mode, '')));
begin
  if caller is null then
    raise exception 'Sign in to change your sharing.' using errcode = '42501';
  end if;

  if clean_mode not in ('exact', 'approximate', 'paused') then
    raise exception 'Unknown sharing mode.' using errcode = '22023';
  end if;

  if not exists (select 1 from public.circle_members where user_id = caller) then
    raise exception 'Join a circle before sharing your status.'
      using errcode = '42501';
  end if;

  -- updated_at is deliberately untouched: changing a preference does not mean
  -- the member was just seen.
  insert into public.member_status as s (user_id, privacy_mode, updated_at)
  values (caller, clean_mode, now())
  on conflict (user_id) do update set
    privacy_mode = excluded.privacy_mode,
    latitude = case
      when excluded.privacy_mode = 'paused' then null
      when excluded.privacy_mode = 'approximate' and s.latitude is not null
        then round((s.latitude / 0.003)::numeric) * 0.003::double precision
      else s.latitude
    end,
    longitude = case
      when excluded.privacy_mode = 'paused' then null
      when excluded.privacy_mode = 'approximate' and s.longitude is not null
        then round((s.longitude / 0.003)::numeric) * 0.003::double precision
      else s.longitude
    end,
    accuracy_meters = case
      when excluded.privacy_mode = 'paused' then 0
      when excluded.privacy_mode = 'approximate'
        then greatest(s.accuracy_meters, 150)
      else s.accuracy_meters
    end,
    speed_kph = case
      when excluded.privacy_mode = 'paused' then 0
      else s.speed_kph
    end,
    arrived_at = case
      when excluded.privacy_mode = 'exact' then s.arrived_at
      else null
    end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.member_status enable row level security;

drop policy if exists "Read your circle's status" on public.member_status;
create policy "Read your circle's status"
  on public.member_status
  for select
  to authenticated
  using (user_id = (select auth.uid()) or public.shares_circle_with(user_id));

-- No INSERT/UPDATE/DELETE policies: status only changes through the RPCs.

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.member_status from anon, authenticated;
grant select on table public.member_status to authenticated;

revoke all on function public.report_status(
  double precision,
  double precision,
  double precision,
  integer,
  boolean,
  double precision
) from public, anon;

revoke all on function public.set_privacy_mode(text) from public, anon;

grant execute on function public.report_status(
  double precision,
  double precision,
  double precision,
  integer,
  boolean,
  double precision
) to authenticated;

grant execute on function public.set_privacy_mode(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
  then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'member_status'
    ) then
      alter publication supabase_realtime add table public.member_status;
    end if;
  end if;
end;
$$;
