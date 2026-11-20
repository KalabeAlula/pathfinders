-- Pathfinders: crew chat changes fan out over Realtime Broadcast.
--
-- postgres_changes re-evaluates every subscriber's RLS policies for each
-- changed row before delivery, which is the slow part of receiving on mobile.
-- A private broadcast channel is authorized once at join against
-- realtime.messages, then changes are pushed to the room directly.
--
-- The broadcast carries the row, but clients use it only as a wake-up signal:
-- messages are still fetched from the RLS-protected table, so a member removed
-- mid-session stops seeing new messages even while their channel is joined.

create or replace function private.broadcast_chat_changes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.broadcast_changes(
    'chat:' || coalesce(new.circle_id, old.circle_id)::text,
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

revoke all on function private.broadcast_chat_changes() from public;

drop trigger if exists chat_messages_broadcast on public.chat_messages;
create trigger chat_messages_broadcast
  after insert or update or delete on public.chat_messages
  for each row execute function private.broadcast_chat_changes();

-- Joining a private channel is allowed only for topics that name a circle the
-- caller still belongs to. RLS on realtime.messages is already enabled and the
-- table belongs to supabase_realtime_admin, so it cannot be toggled here.
drop policy if exists "Crew chat broadcasts reach their circle"
  on realtime.messages;
create policy "Crew chat broadcasts reach their circle"
  on realtime.messages
  for select
  to authenticated
  using (
    extension = 'broadcast'
    and exists (
      select 1
      from public.circle_members member
      where member.user_id = (select auth.uid())
        and (select realtime.topic()) = 'chat:' || member.circle_id::text
    )
  );
