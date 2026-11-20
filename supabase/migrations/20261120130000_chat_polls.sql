-- Pathfinders: "where are we going?" votes in the crew chat.
--
-- A poll is a chat message (kind 'poll', body = question) with 2-6 options.
-- An option may carry a place so the winner can become the group destination
-- through the existing setDestination flow. Polls and votes are written only
-- through the RPCs below: clients can read the tables but never write them,
-- so a poll message can never exist without its options.

alter table public.chat_messages
  drop constraint chat_messages_kind_check,
  add constraint chat_messages_kind_check
    check (kind in ('text', 'location_share', 'destination_update', 'gif', 'poll'));

alter table public.chat_messages
  drop constraint chat_messages_payload_check,
  add constraint chat_messages_payload_check check (
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
    or (
      kind = 'gif'
      and body ~ '^https://([A-Za-z0-9-]+\.)*giphy\.com/[^[:space:]]+$'
    )
    or (kind = 'poll' and body is not null and char_length(btrim(body)) > 0)
  );

create table public.chat_poll_options (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  id uuid not null default gen_random_uuid(),
  position smallint not null check (position between 0 and 5),
  label text not null check (char_length(btrim(label)) between 1 and 80),
  latitude double precision,
  longitude double precision,
  place_label text check (char_length(place_label) between 1 and 120),
  primary key (message_id, id),
  unique (message_id, position),
  constraint chat_poll_options_point_check
    check ((latitude is null) = (longitude is null)),
  constraint chat_poll_options_lat_check check (latitude between -90 and 90),
  constraint chat_poll_options_lon_check check (longitude between -180 and 180)
);

create table public.chat_poll_votes (
  message_id uuid not null,
  option_id uuid not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id),
  constraint chat_poll_votes_option_fkey
    foreign key (message_id, option_id)
    references public.chat_poll_options (message_id, id)
    on delete cascade
);

create index chat_poll_votes_option_idx on public.chat_poll_votes (option_id);

alter table public.chat_poll_options enable row level security;
alter table public.chat_poll_votes enable row level security;

revoke all on table public.chat_poll_options from anon, authenticated;
revoke all on table public.chat_poll_votes from anon, authenticated;
grant select on table public.chat_poll_options to authenticated;
grant select on table public.chat_poll_votes to authenticated;

create policy "Circle members read poll options"
  on public.chat_poll_options
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.chat_messages message
      where message.id = message_id
        and public.is_circle_member(message.circle_id)
    )
  );

create policy "Circle members read poll votes"
  on public.chat_poll_votes
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.chat_messages message
      where message.id = message_id
        and public.is_circle_member(message.circle_id)
    )
  );

create or replace function public.create_chat_poll(
  p_circle_id uuid,
  p_question text,
  p_options jsonb,
  p_message_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  question text := btrim(coalesce(p_question, ''));
  option_count int;
  option jsonb;
  option_label text;
  option_lat double precision;
  option_lon double precision;
  option_place text;
  option_id uuid;
  message_id uuid;
  i smallint := 0;
begin
  if caller is null then
    raise exception 'Sign in to start a vote.' using errcode = '42501';
  end if;
  if not public.is_circle_member(p_circle_id) then
    raise exception 'Join this circle to start a vote.'
      using errcode = '42501';
  end if;
  if char_length(question) = 0 or char_length(question) > 160 then
    raise exception 'Write a question between 1 and 160 characters.'
      using errcode = '22023';
  end if;

  option_count := jsonb_array_length(coalesce(p_options, '[]'::jsonb));
  if option_count < 2 or option_count > 6 then
    raise exception 'Give the vote between 2 and 6 options.'
      using errcode = '22023';
  end if;

  message_id := coalesce(p_message_id, gen_random_uuid());

  insert into public.chat_messages (id, circle_id, sender_id, kind, body)
  values (message_id, p_circle_id, caller, 'poll', question);

  for option in select * from jsonb_array_elements(p_options) loop
    option_label := btrim(coalesce(option ->> 'label', ''));
    if char_length(option_label) = 0 or char_length(option_label) > 80 then
      raise exception 'Each option needs a label of at most 80 characters.'
        using errcode = '22023';
    end if;
    option_lat := (option ->> 'latitude')::double precision;
    option_lon := (option ->> 'longitude')::double precision;
    option_place := nullif(btrim(coalesce(option ->> 'place_label', '')), '');
    option_id := coalesce((option ->> 'id')::uuid, gen_random_uuid());

    insert into public.chat_poll_options
      (message_id, id, position, label, latitude, longitude, place_label)
    values
      (message_id, option_id, i, option_label, option_lat, option_lon,
       option_place);
    i := i + 1;
  end loop;

  return message_id;
end;
$$;

-- Tapping the option you already chose clears the vote; any other option moves
-- it. The database is the single source of that toggle rule.
create or replace function public.cast_chat_vote(
  p_message_id uuid,
  p_option_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  message_circle uuid;
  message_kind text;
  current_option uuid;
begin
  if caller is null then
    raise exception 'Sign in to vote.' using errcode = '42501';
  end if;

  select message.circle_id, message.kind
    into message_circle, message_kind
    from public.chat_messages message
   where message.id = p_message_id;

  if message_circle is null or message_kind <> 'poll' then
    raise exception 'That vote is no longer in this thread.'
      using errcode = 'P0001';
  end if;
  if not public.is_circle_member(message_circle) then
    raise exception 'Join this circle to vote.' using errcode = '42501';
  end if;
  if not exists (
    select 1
    from public.chat_poll_options option
    where option.message_id = p_message_id
      and option.id = p_option_id
  ) then
    raise exception 'That option is no longer on this vote.'
      using errcode = 'P0001';
  end if;

  select vote.option_id
    into current_option
    from public.chat_poll_votes vote
   where vote.message_id = p_message_id
     and vote.user_id = caller;

  if current_option = p_option_id then
    delete from public.chat_poll_votes
     where message_id = p_message_id
       and user_id = caller;
    return;
  end if;

  insert into public.chat_poll_votes (message_id, option_id, user_id)
  values (p_message_id, p_option_id, caller)
  on conflict (message_id, user_id)
  do update set option_id = excluded.option_id, created_at = now();
end;
$$;

revoke all on function public.create_chat_poll(uuid, text, jsonb, uuid)
  from public, anon;
revoke all on function public.cast_chat_vote(uuid, uuid) from public, anon;
grant execute on function public.create_chat_poll(uuid, text, jsonb, uuid)
  to authenticated;
grant execute on function public.cast_chat_vote(uuid, uuid) to authenticated;

-- Votes and options ride the same private topic as the thread so counts move
-- without touching postgres_changes.
create or replace function private.broadcast_chat_poll_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_circle uuid;
begin
  select message.circle_id
    into target_circle
    from public.chat_messages message
   where message.id = coalesce(new.message_id, old.message_id);

  if target_circle is null then
    return null;
  end if;

  perform realtime.broadcast_changes(
    'chat:' || target_circle::text,
    tg_op,
    tg_op,
    tg_table_name,
    tg_table_schema,
    new,
    old
  );
  return null;
end;
$$;

revoke all on function private.broadcast_chat_poll_changes() from public;

drop trigger if exists chat_poll_options_broadcast
  on public.chat_poll_options;
create trigger chat_poll_options_broadcast
  after insert or update or delete on public.chat_poll_options
  for each row execute function private.broadcast_chat_poll_changes();

drop trigger if exists chat_poll_votes_broadcast on public.chat_poll_votes;
create trigger chat_poll_votes_broadcast
  after insert or update or delete on public.chat_poll_votes
  for each row execute function private.broadcast_chat_poll_changes();
