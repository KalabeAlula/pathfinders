-- Pathfinders: one reaction per member per memory.
--
-- Design notes:
--   * A member can leave at most one reaction on a memory. Changing the emoji
--     is an upsert on (memory_id, user_id); tapping the same emoji again
--     deletes the row.
--   * Reactions carry no circle_id. Membership is checked by joining up to the
--     memory, so a reaction can never point across circles.
--   * The emoji list is constrained here because the client offers a fixed
--     palette; arbitrary strings would be a needless surface.
--   * Realtime needs `replica identity full` to deliver enough columns for the
--     client to tell which memory a change belongs to.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.memory_reactions (
  memory_id uuid not null references public.memories (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  primary key (memory_id, user_id),
  constraint memory_reactions_emoji_check
    check (emoji in ('🧡', '✨', '😂', '🌱'))
);

create index memory_reactions_user_idx
  on public.memory_reactions (user_id);

alter table public.memory_reactions replica identity full;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.memory_reactions enable row level security;

create policy "Read reactions in your circles"
  on public.memory_reactions
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.memories m
      where m.id = memory_reactions.memory_id
        and public.is_circle_member(m.circle_id)
    )
  );

create policy "React to memories in your circles"
  on public.memory_reactions
  for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.memories m
      where m.id = memory_reactions.memory_id
        and public.is_circle_member(m.circle_id)
    )
  );

create policy "Change your own reaction"
  on public.memory_reactions
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.memories m
      where m.id = memory_reactions.memory_id
        and public.is_circle_member(m.circle_id)
    )
  );

create policy "Remove your own reaction"
  on public.memory_reactions
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.memory_reactions from anon, authenticated;
grant select, insert, update, delete on table public.memory_reactions
  to authenticated;

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
        and tablename = 'memory_reactions'
    ) then
      alter publication supabase_realtime add table public.memory_reactions;
    end if;
  end if;
end;
$$;
