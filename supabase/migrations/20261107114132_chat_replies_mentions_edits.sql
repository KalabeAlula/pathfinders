-- Pathfinders: quoted replies, member mentions, and sender edits/deletes.
--
-- A reply points at another message in the same circle; losing the parent only
-- clears the quote, never the reply itself. Mentions are stored as ids so push
-- targeting never has to parse the body. Editing stays sender-only, text-only
-- and column-scoped, so a member can change the words but not the row's
-- identity, placement or circle.

alter table public.chat_messages
  add column reply_to_id uuid
    references public.chat_messages (id) on delete set null,
  add column mentioned_user_ids uuid[] not null default '{}',
  add column edited_at timestamptz,
  add constraint chat_messages_mentions_check
    check (coalesce(array_length(mentioned_user_ids, 1), 0) <= 50);

create index chat_messages_reply_to_idx
  on public.chat_messages (reply_to_id);

-- ---------------------------------------------------------------------------
-- Replies must stay inside their thread
-- ---------------------------------------------------------------------------

create or replace function private.prepare_chat_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- The edit stamp is server-only; nobody posts a message pre-edited.
  new.edited_at := null;

  if new.reply_to_id is not null and not exists (
    select 1
    from public.chat_messages
    where id = new.reply_to_id
      and circle_id = new.circle_id
  ) then
    raise exception 'That message is not in this circle.'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

revoke all on function private.prepare_chat_message() from public;

drop trigger if exists chat_messages_prepare on public.chat_messages;
create trigger chat_messages_prepare
  before insert on public.chat_messages
  for each row execute function private.prepare_chat_message();

-- ---------------------------------------------------------------------------
-- Edits are stamped by the database, not the client
-- ---------------------------------------------------------------------------

create or replace function private.stamp_chat_edit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- The reply parent being deleted also updates this row; that is not an edit.
  if new.body is distinct from old.body
     or new.mentioned_user_ids is distinct from old.mentioned_user_ids
  then
    new.edited_at := now();
  end if;

  return new;
end;
$$;

revoke all on function private.stamp_chat_edit() from public;

drop trigger if exists chat_messages_edit_stamp on public.chat_messages;
create trigger chat_messages_edit_stamp
  before update on public.chat_messages
  for each row execute function private.stamp_chat_edit();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

create policy "Edit your own text messages"
  on public.chat_messages
  for update
  to authenticated
  using (sender_id = (select auth.uid()) and kind = 'text')
  with check (
    sender_id = (select auth.uid())
    and kind = 'text'
    and public.is_circle_member(circle_id)
  );

create policy "Delete your own text messages"
  on public.chat_messages
  for delete
  to authenticated
  using (sender_id = (select auth.uid()) and kind = 'text');

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

grant update (body, mentioned_user_ids)
  on table public.chat_messages to authenticated;
grant delete on table public.chat_messages to authenticated;
