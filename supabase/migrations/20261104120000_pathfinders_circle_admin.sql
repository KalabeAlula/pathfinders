-- Pathfinders: creator tools for a circle's identity.
--
-- Renaming fixes a typo or repurposes a circle without the destructive
-- delete-and-recreate path. Rotating the invite code revokes a code that was
-- screenshotted or shared too widely; everyone already inside stays a member,
-- and the old code stops matching immediately.
--
-- Both functions are creator-only and are the only write path: clients hold no
-- UPDATE privilege on public.circles.

-- ---------------------------------------------------------------------------
-- Rename (creator only)
-- ---------------------------------------------------------------------------

create or replace function public.rename_circle(p_circle_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  circle_creator uuid;
  clean_name text := btrim(coalesce(p_name, ''));
begin
  if caller is null then
    raise exception 'Sign in to rename a circle.' using errcode = '42501';
  end if;

  if char_length(clean_name) < 1 or char_length(clean_name) > 40 then
    raise exception 'Give your circle a name between 1 and 40 characters.'
      using errcode = '22023';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator is distinct from caller then
    raise exception 'Only the circle creator can rename it.'
      using errcode = '42501';
  end if;

  update public.circles set name = clean_name where id = p_circle_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Rotate invite code (creator only)
-- ---------------------------------------------------------------------------

create or replace function public.rotate_invite_code(p_circle_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  circle_creator uuid;
  candidate text;
  attempt integer := 0;
begin
  if caller is null then
    raise exception 'Sign in to rotate the invite code.' using errcode = '42501';
  end if;

  select created_by into circle_creator
  from public.circles
  where id = p_circle_id;

  if not found then
    raise exception 'That circle no longer exists.' using errcode = 'P0002';
  end if;

  if circle_creator is distinct from caller then
    raise exception 'Only the circle creator can rotate the invite code.'
      using errcode = '42501';
  end if;

  loop
    attempt := attempt + 1;
    candidate := public.generate_invite_code();
    begin
      update public.circles set invite_code = candidate where id = p_circle_id;
      return candidate;
    exception when unique_violation then
      if attempt >= 8 then
        raise exception 'Could not reserve a fresh invite code. Please try again.'
          using errcode = 'P0001';
      end if;
    end;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke all on function public.rename_circle(uuid, text) from public, anon, authenticated;
revoke all on function public.rotate_invite_code(uuid) from public, anon, authenticated;

grant execute on function public.rename_circle(uuid, text) to authenticated;
grant execute on function public.rotate_invite_code(uuid) to authenticated;
