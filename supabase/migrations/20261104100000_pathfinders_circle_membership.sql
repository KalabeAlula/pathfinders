-- Pathfinders: members can leave a circle; only the creator can delete one.
--
-- Direct writes stay impossible for clients: circles and circle_members have
-- no INSERT/UPDATE/DELETE policies and authenticated has no table privileges.
-- These SECURITY DEFINER functions are the only path, so the creator guard is
-- enforced in the database, not just the UI.
--
-- Deleting a circle cascades through circle_members, chat_messages,
-- circle_destinations, memories, milestones, and memory_reactions because every
-- child table declares `on delete cascade` on circle_id. Storage objects for
-- memory photos are the one exception; those are cleaned up by the app.

-- ---------------------------------------------------------------------------
-- Leave
-- ---------------------------------------------------------------------------

create or replace function public.leave_circle(p_circle_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  circle_creator uuid;
  removed integer;
begin
  if caller is null then
    raise exception 'Sign in to leave a circle.' using errcode = '42501';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator = caller then
    raise exception 'You created this circle. Delete it instead of leaving.'
      using errcode = 'P0001';
  end if;

  delete from public.circle_members
  where circle_id = p_circle_id
    and user_id = caller;

  get diagnostics removed = row_count;
  if removed = 0 then
    raise exception 'You are not in this circle.' using errcode = 'P0002';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Delete (creator only)
-- ---------------------------------------------------------------------------

create or replace function public.delete_circle(p_circle_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  circle_creator uuid;
begin
  if caller is null then
    raise exception 'Sign in to delete a circle.' using errcode = '42501';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator is distinct from caller then
    raise exception 'Only the circle creator can delete it.'
      using errcode = '42501';
  end if;

  delete from public.circles where id = p_circle_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on function public.leave_circle(uuid) from public, anon, authenticated;
revoke all on function public.delete_circle(uuid) from public, anon, authenticated;

grant execute on function public.leave_circle(uuid) to authenticated;
grant execute on function public.delete_circle(uuid) to authenticated;
