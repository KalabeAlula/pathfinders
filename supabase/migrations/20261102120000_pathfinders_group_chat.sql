-- Pathfinders: in-group chat with text, shared locations and destination
-- updates.
--
-- Text and shared locations are written by members. Destination updates are
-- system messages written by a trigger when circle_destinations changes, so
-- every member sees the same banner no matter which device moved the pin.
-- Messages are immutable: members can read and append, not edit or delete.

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null default 'text'
    check (kind in ('text', 'location_share', 'destination_update')),
  body text,
  latitude double precision,
  longitude double precision,
  place_label text,
  created_at timestamptz not null default now(),
  constraint chat_messages_body_check
    check (body is null or char_length(body) <= 2000),
  constraint chat_messages_lat_check
    check (latitude is null or latitude between -90 and 90),
  constraint chat_messages_lon_check
    check (longitude is null or longitude between -180 and 180),
  constraint chat_messages_payload_check check (
    (kind = 'text' and body is not null and char_length(btrim(body)) > 0)
    or (
      kind = 'location_share'
      and latitude is not null
      and longitude is not null
    )
    or (
      kind = 'destination_update'
      and place_label is not null
      and latitude is not null
      and longitude is not null
    )
  )
);

create index chat_messages_circle_created_idx
  on public.chat_messages (circle_id, created_at desc);

alter table public.chat_messages replica identity full;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.chat_messages enable row level security;

create policy "Read your circle's chat"
  on public.chat_messages
  for select
  to authenticated
  using (public.is_circle_member(circle_id));

-- Clients may only append member messages. System destination updates come
-- from the trigger below, which bypasses this policy as a definer function.
create policy "Send to your circle's chat"
  on public.chat_messages
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_circle_member(circle_id)
    and kind in ('text', 'location_share')
  );

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.chat_messages from anon, authenticated;

grant select, insert on table public.chat_messages to authenticated;

-- ---------------------------------------------------------------------------
-- Destination updates become chat messages
-- ---------------------------------------------------------------------------

create schema if not exists private;

create or replace function private.post_destination_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- A re-upsert of the same pin should not spam the thread.
  if tg_op = 'UPDATE'
     and new.label is not distinct from old.label
     and new.latitude is not distinct from old.latitude
     and new.longitude is not distinct from old.longitude
  then
    return new;
  end if;

  insert into public.chat_messages
    (circle_id, sender_id, kind, latitude, longitude, place_label)
  values
    (new.circle_id, new.set_by, 'destination_update',
     new.latitude, new.longitude, new.label);

  return new;
end;
$$;

revoke all on function private.post_destination_update() from public;

drop trigger if exists circle_destinations_chat on public.circle_destinations;

create trigger circle_destinations_chat
  after insert or update on public.circle_destinations
  for each row execute function private.post_destination_update();

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
        and tablename = 'chat_messages'
    ) then
      alter publication supabase_realtime add table public.chat_messages;
    end if;
  end if;
end;
$$;
