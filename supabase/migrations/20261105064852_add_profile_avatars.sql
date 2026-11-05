-- Profile identity: the animal avatar a member wears on the map.
--
-- avatar_id is a catalog id from the app (lib/features/profile/domain/
-- animal_avatar.dart). The check keeps unknown ids out of the database so a
-- map pin never has to guess. display_name already lives on this table; the
-- existing "Edit your own profile" policy (id = auth.uid()) already covers
-- both columns.

alter table public.profiles
  add column if not exists avatar_id text not null default 'avatar_wolf';

alter table public.profiles
  drop constraint if exists profiles_avatar_id_check;

alter table public.profiles
  add constraint profiles_avatar_id_check check (
    avatar_id in (
      'avatar_wolf',
      'avatar_lion',
      'avatar_lovebird',
      'avatar_ibex',
      'avatar_gelada',
      'avatar_monkey',
      'avatar_owl',
      'avatar_bear',
      'avatar_deer',
      'avatar_cat'
    )
  );

-- Column privileges are granted per column; avatar_color stays as it was.
grant update (avatar_id) on table public.profiles to authenticated;

-- Realtime so circle members pick up a rename or a new avatar immediately.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1
       from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'profiles'
     ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;
