-- Pathfinders: creator can remove a member and hand over ownership.
--
-- Removing frees a seat and revokes access; the removed member's client drops
-- the circle on the next realtime refresh and falls back to another group.
-- Transferring ownership is the only way for a creator to step down, because
-- leave_circle refuses the creator and delete_circle is final.
--
-- Both functions are creator-only and are the only write path: clients hold no
-- DELETE privilege on circle_members and no UPDATE privilege on circles.

-- ---------------------------------------------------------------------------
-- Remove a member (creator only)
-- ---------------------------------------------------------------------------

create or replace function public.remove_circle_member(
  p_circle_id uuid,
  p_user_id uuid
)
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
    raise exception 'Sign in to manage this circle.' using errcode = '42501';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator is distinct from caller then
    raise exception 'Only the circle creator can remove members.'
      using errcode = '42501';
  end if;

  if p_user_id is null then
    raise exception 'Choose a member to remove.' using errcode = '22023';
  end if;

  if p_user_id = circle_creator then
    raise exception 'The creator cannot be removed. Transfer ownership or delete the circle.'
      using errcode = 'P0001';
  end if;

  delete from public.circle_members
  where circle_id = p_circle_id
    and user_id = p_user_id;

  get diagnostics removed = row_count;
  if removed = 0 then
    raise exception 'That member is no longer in this circle.'
      using errcode = 'P0002';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Transfer ownership (creator only)
-- ---------------------------------------------------------------------------

create or replace function public.transfer_circle_ownership(
  p_circle_id uuid,
  p_new_owner uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  circle_creator uuid;
  updated integer;
begin
  if caller is null then
    raise exception 'Sign in to transfer this circle.' using errcode = '42501';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator is distinct from caller then
    raise exception 'Only the circle creator can transfer ownership.'
      using errcode = '42501';
  end if;

  if p_new_owner is null then
    raise exception 'Choose a member to take over.' using errcode = '22023';
  end if;

  if p_new_owner = caller then
    raise exception 'You already own this circle.' using errcode = '22023';
  end if;

  -- The membership check sits in the same statement as the update so a member
  -- leaving mid-transfer cannot leave the circle owned by a non-member.
  update public.circles c
  set created_by = p_new_owner
  where c.id = p_circle_id
    and exists (
      select 1
      from public.circle_members m
      where m.circle_id = c.id
        and m.user_id = p_new_owner
    );

  get diagnostics updated = row_count;
  if updated = 0 then
    raise exception 'That member is no longer in this circle.'
      using errcode = 'P0002';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on function public.remove_circle_member(uuid, uuid) from public, anon, authenticated;
revoke all on function public.transfer_circle_ownership(uuid, uuid) from public, anon, authenticated;

grant execute on function public.remove_circle_member(uuid, uuid) to authenticated;
grant execute on function public.transfer_circle_ownership(uuid, uuid) to authenticated;
