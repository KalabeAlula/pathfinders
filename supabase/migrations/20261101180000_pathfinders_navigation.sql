-- Pathfinders: one shared navigation destination per circle.
--
-- Every member reads the active destination and can move or clear it. Routes
-- are not stored: each device computes them from the live coordinates that
-- already flow through member_status, so an ETA always matches the position
-- the map is showing.
--
-- Realtime needs replica identity full so a moved or cleared destination
-- carries the circle id in the change payload.

create table public.circle_destinations (
  circle_id uuid primary key references public.circles (id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  label text not null check (char_length(btrim(label)) between 1 and 120),
  set_by uuid not null references public.profiles (id) on delete cascade,
  updated_at timestamptz not null default now(),
  constraint circle_destinations_lat_check check (latitude between -90 and 90),
  constraint circle_destinations_lon_check
    check (longitude between -180 and 180)
);

alter table public.circle_destinations replica identity full;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.circle_destinations enable row level security;

create policy "Read your circle's destination"
  on public.circle_destinations
  for select
  to authenticated
  using (public.is_circle_member(circle_id));

create policy "Set your circle's destination"
  on public.circle_destinations
  for insert
  to authenticated
  with check (
    set_by = (select auth.uid())
    and public.is_circle_member(circle_id)
  );

-- Any member may move the shared pin, but the row must record who moved it.
create policy "Move your circle's destination"
  on public.circle_destinations
  for update
  to authenticated
  using (public.is_circle_member(circle_id))
  with check (
    set_by = (select auth.uid())
    and public.is_circle_member(circle_id)
  );

create policy "Clear your circle's destination"
  on public.circle_destinations
  for delete
  to authenticated
  using (public.is_circle_member(circle_id));

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.circle_destinations from anon, authenticated;

grant select, insert, update, delete
  on table public.circle_destinations to authenticated;

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
        and tablename = 'circle_destinations'
    ) then
      alter publication supabase_realtime add table public.circle_destinations;
    end if;
  end if;
end;
$$;
