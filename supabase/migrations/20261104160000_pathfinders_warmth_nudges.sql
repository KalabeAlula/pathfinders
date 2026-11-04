-- Pathfinders: personalized "warmth" nudges between members of a circle.
--
-- One row is one delivered warmth action from a sender to a single peer. The
-- message is rendered on the sender's device from the group's warmth
-- catalogue, so the recipient can show it verbatim even though realtime rows
-- do not carry joined profile data.
--
-- Rows are append-only. Only the recipient can read a row; only a member of
-- the circle can send to another member of the same circle.

create table public.nudges (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  warmth_type text not null check (
    warmth_type in (
      'kiss',
      'hug',
      'thinking_of_you',
      'love_you',
      'high_five',
      'fist_bump',
      'wave',
      'where_you_at',
      'warm_hug',
      'check_in',
      'family_love'
    )
  ),
  emoji text not null check (char_length(emoji) between 1 and 8),
  message text not null check (
    char_length(btrim(message)) between 1 and 140
  ),
  created_at timestamptz not null default now(),
  constraint nudges_distinct_members check (sender_id <> target_id)
);

create index nudges_inbox_idx
  on public.nudges (target_id, created_at desc);

create index nudges_circle_created_idx
  on public.nudges (circle_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.nudges enable row level security;

create policy "Read warmth sent to you"
  on public.nudges
  for select
  to authenticated
  using (target_id = (select auth.uid()));

create policy "Send warmth to a circle peer"
  on public.nudges
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_circle_member(circle_id)
    and exists (
      select 1
      from public.circle_members peer
      where peer.circle_id = nudges.circle_id
        and peer.user_id = nudges.target_id
    )
  );

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.nudges from anon, authenticated;

grant select, insert on table public.nudges to authenticated;

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
        and tablename = 'nudges'
    ) then
      alter publication supabase_realtime add table public.nudges;
    end if;
  end if;
end;
$$;
