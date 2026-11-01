-- Pathfinders: the memory feed and the shared countdown.
--
-- Design notes:
--   * Both tables belong to a circle, not a user. Every member of the circle
--     can read every row, and RLS is the only access check needed.
--   * Authors may add and remove their own entries. Nothing is editable in
--     place: a memory is a record of what was said, so "fixing" it would
--     quietly rewrite history.
--   * The author column is checked against auth.uid() at insert time, so a
--     client cannot post as somebody else.
--   * Realtime needs `replica identity full` to deliver enough columns for
--     the client to tell which circle a change belongs to.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null
    check (char_length(btrim(body)) between 1 and 600),
  mood text not null default 'cozy',
  place_label text,
  voice_note_seconds integer,
  created_at timestamptz not null default now(),
  constraint memories_mood_check
    check (mood in ('cozy', 'joyful', 'calm', 'silly', 'proud')),
  constraint memories_place_label_check
    check (
      place_label is null
      or char_length(btrim(place_label)) between 1 and 80
    ),
  constraint memories_voice_note_check
    check (voice_note_seconds is null or voice_note_seconds between 1 and 300)
);

create index memories_circle_created_idx
  on public.memories (circle_id, created_at desc);

create table public.milestones (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  subtitle text,
  due_on date not null,
  kind text not null default 'goal',
  created_at timestamptz not null default now(),
  constraint milestones_kind_check
    check (kind in ('birthday', 'anniversary', 'trip', 'goal')),
  constraint milestones_subtitle_check
    check (
      subtitle is null
      or char_length(btrim(subtitle)) between 1 and 120
    )
);

create index milestones_circle_due_idx
  on public.milestones (circle_id, due_on asc);

alter table public.memories replica identity full;
alter table public.milestones replica identity full;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.memories enable row level security;
alter table public.milestones enable row level security;

create policy "Read your circle's memories"
  on public.memories
  for select
  to authenticated
  using (public.is_circle_member(circle_id));

create policy "Write your own memories"
  on public.memories
  for insert
  to authenticated
  with check (
    author_id = (select auth.uid())
    and public.is_circle_member(circle_id)
  );

create policy "Remove your own memories"
  on public.memories
  for delete
  to authenticated
  using (author_id = (select auth.uid()));

create policy "Read your circle's milestones"
  on public.milestones
  for select
  to authenticated
  using (public.is_circle_member(circle_id));

create policy "Write milestones for your circle"
  on public.milestones
  for insert
  to authenticated
  with check (
    created_by = (select auth.uid())
    and public.is_circle_member(circle_id)
  );

create policy "Remove the milestones you added"
  on public.milestones
  for delete
  to authenticated
  using (created_by = (select auth.uid()));

-- No UPDATE policies: entries are removed and re-added instead of rewritten.

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on table public.memories from anon, authenticated;
revoke all on table public.milestones from anon, authenticated;

grant select, insert, delete on table public.memories to authenticated;
grant select, insert, delete on table public.milestones to authenticated;

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
        and tablename = 'memories'
    ) then
      alter publication supabase_realtime add table public.memories;
    end if;

    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'milestones'
    ) then
      alter publication supabase_realtime add table public.milestones;
    end if;
  end if;
end;
$$;
