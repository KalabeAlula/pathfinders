-- Pathfinders: 1-on-1 direct messaging and 5-day expiring chat attachments
-- (shared across group chat and direct messages).

-- ---------------------------------------------------------------------------
-- Part 1: Direct 1-on-1 Threads & Messages
-- ---------------------------------------------------------------------------

create table public.direct_threads (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  user_a_last_read_at timestamptz not null default now(),
  user_b_last_read_at timestamptz not null default now(),
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  constraint direct_threads_distinct_users check (user_a <> user_b)
);

-- One canonical thread per pair regardless of who starts it.
create unique index direct_threads_pair_uidx
  on public.direct_threads (least(user_a, user_b), greatest(user_a, user_b));

create index direct_threads_user_a_idx
  on public.direct_threads (user_a, last_message_at desc);

create index direct_threads_user_b_idx
  on public.direct_threads (user_b, last_message_at desc);

create table public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.direct_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null default 'text'
    check (kind in ('text', 'location_share', 'gif', 'file')),
  body text,
  latitude double precision,
  longitude double precision,
  place_label text,
  reply_to_id uuid references public.direct_messages (id) on delete set null,
  edited_at timestamptz,
  attachment_path text,
  attachment_name text,
  attachment_size bigint,
  attachment_mime text,
  attachment_expires_at timestamptz,
  attachment_expired boolean not null default false,
  created_at timestamptz not null default now(),
  constraint direct_messages_body_check
    check (body is null or char_length(body) <= 2000),
  constraint direct_messages_lat_check
    check (latitude is null or latitude between -90 and 90),
  constraint direct_messages_lon_check
    check (longitude is null or longitude between -180 and 180),
  constraint direct_messages_attachment_size_check
    check (
      attachment_size is null
      or (attachment_size > 0 and attachment_size <= 15728640)
    ),
  constraint direct_messages_attachment_name_check
    check (
      attachment_name is null
      or char_length(btrim(attachment_name)) between 1 and 255
    ),
  constraint direct_messages_attachment_path_check
    check (
      attachment_path is null
      or (
        attachment_path like 'dm/' || thread_id::text || '/' || sender_id::text || '/%'
        and char_length(attachment_path) <= 300
      )
    ),
  constraint direct_messages_payload_check check (
    (kind = 'text' and body is not null and char_length(btrim(body)) > 0)
    or (
      kind = 'location_share'
      and latitude is not null
      and longitude is not null
    )
    or (
      kind = 'gif'
      and body ~ '^https://([A-Za-z0-9-]+\.)*giphy\.com/[^[:space:]]+$'
    )
    or (
      kind = 'file'
      and attachment_name is not null
      and attachment_size is not null
      and attachment_expires_at is not null
      and (attachment_expired = true or attachment_path is not null)
    )
  )
);

create index direct_messages_thread_created_idx
  on public.direct_messages (thread_id, created_at desc);

create index direct_messages_expiring_attachments_idx
  on public.direct_messages (attachment_expires_at)
  where attachment_expired = false and attachment_path is not null;

alter table public.direct_threads replica identity full;
alter table public.direct_messages replica identity full;

-- Helper used by both table RLS and Storage RLS to verify the caller
-- participates in a DM thread with someone who still shares a circle.
create or replace function public.is_direct_thread_participant(target_thread uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.direct_threads t
    where t.id = target_thread
      and (select auth.uid()) in (t.user_a, t.user_b)
      and public.shares_circle_with(
        case
          when t.user_a = (select auth.uid()) then t.user_b
          else t.user_a
        end
      )
  );
$$;

revoke all on function public.is_direct_thread_participant(uuid) from public, anon;
grant execute on function public.is_direct_thread_participant(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Direct Threads & Messages RLS
-- ---------------------------------------------------------------------------

alter table public.direct_threads enable row level security;
alter table public.direct_messages enable row level security;

create policy "Read your direct threads"
  on public.direct_threads
  for select
  to authenticated
  using (
    (select auth.uid()) in (user_a, user_b)
    and public.shares_circle_with(
      case
        when user_a = (select auth.uid()) then user_b
        else user_a
      end
    )
  );

create policy "Start a direct thread with a circle peer"
  on public.direct_threads
  for insert
  to authenticated
  with check (
    (select auth.uid()) in (user_a, user_b)
    and user_a <> user_b
    and public.shares_circle_with(
      case
        when user_a = (select auth.uid()) then user_b
        else user_a
      end
    )
  );

create policy "Update read state on your direct threads"
  on public.direct_threads
  for update
  to authenticated
  using (
    (select auth.uid()) in (user_a, user_b)
    and public.shares_circle_with(
      case
        when user_a = (select auth.uid()) then user_b
        else user_a
      end
    )
  )
  with check (
    (select auth.uid()) in (user_a, user_b)
    and public.shares_circle_with(
      case
        when user_a = (select auth.uid()) then user_b
        else user_a
      end
    )
  );

create policy "Read your direct messages"
  on public.direct_messages
  for select
  to authenticated
  using (public.is_direct_thread_participant(thread_id));

create policy "Send direct messages in your threads"
  on public.direct_messages
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_direct_thread_participant(thread_id)
  );

create policy "Edit your own direct messages"
  on public.direct_messages
  for update
  to authenticated
  using (
    sender_id = (select auth.uid())
    and public.is_direct_thread_participant(thread_id)
  )
  with check (
    sender_id = (select auth.uid())
    and public.is_direct_thread_participant(thread_id)
  );

create policy "Delete your own direct messages"
  on public.direct_messages
  for delete
  to authenticated
  using (
    sender_id = (select auth.uid())
    and public.is_direct_thread_participant(thread_id)
  );

revoke all on table public.direct_threads from anon, authenticated;
grant select, insert, update on table public.direct_threads to authenticated;

revoke all on table public.direct_messages from anon, authenticated;
grant select, insert, update, delete on table public.direct_messages to authenticated;

-- Keep direct_threads.last_message_at updated on every new DM.
create or replace function private.touch_direct_thread()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.direct_threads
  set last_message_at = new.created_at
  where id = new.thread_id;
  return new;
end;
$$;

revoke all on function private.touch_direct_thread() from public;

drop trigger if exists direct_messages_touch_thread on public.direct_messages;
create trigger direct_messages_touch_thread
  after insert on public.direct_messages
  for each row execute function private.touch_direct_thread();

-- Mark only the caller's read cursor on a DM thread.
create or replace function public.mark_direct_thread_read(p_thread_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null or not public.is_direct_thread_participant(p_thread_id) then
    raise exception 'Not authorized';
  end if;

  update public.direct_threads
  set
    user_a_last_read_at = case when user_a = uid then now() else user_a_last_read_at end,
    user_b_last_read_at = case when user_b = uid then now() else user_b_last_read_at end
  where id = p_thread_id;
end;
$$;

revoke all on function public.mark_direct_thread_read(uuid) from public, anon;
grant execute on function public.mark_direct_thread_read(uuid) to authenticated;

-- Realtime for direct_threads and direct_messages
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'direct_threads'
    ) then
      alter publication supabase_realtime add table public.direct_threads;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'direct_messages'
    ) then
      alter publication supabase_realtime add table public.direct_messages;
    end if;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Part 2: Group Chat Attachment Columns + Private Storage Bucket & RLS
-- ---------------------------------------------------------------------------

alter table public.chat_messages
  add column if not exists attachment_path text,
  add column if not exists attachment_name text,
  add column if not exists attachment_size bigint,
  add column if not exists attachment_mime text,
  add column if not exists attachment_expires_at timestamptz,
  add column if not exists attachment_expired boolean not null default false;

alter table public.chat_messages
  drop constraint if exists chat_messages_kind_check,
  add constraint chat_messages_kind_check
    check (kind in ('text', 'location_share', 'destination_update', 'gif', 'poll', 'file'));

alter table public.chat_messages
  drop constraint if exists chat_messages_attachment_size_check,
  add constraint chat_messages_attachment_size_check
    check (
      attachment_size is null
      or (attachment_size > 0 and attachment_size <= 15728640)
    );

alter table public.chat_messages
  drop constraint if exists chat_messages_attachment_name_check,
  add constraint chat_messages_attachment_name_check
    check (
      attachment_name is null
      or char_length(btrim(attachment_name)) between 1 and 255
    );

alter table public.chat_messages
  drop constraint if exists chat_messages_attachment_path_check,
  add constraint chat_messages_attachment_path_check
    check (
      attachment_path is null
      or (
        attachment_path like 'group/' || circle_id::text || '/' || sender_id::text || '/%'
        and char_length(attachment_path) <= 300
      )
    );

alter table public.chat_messages
  drop constraint if exists chat_messages_payload_check,
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
    or (
      kind = 'file'
      and attachment_name is not null
      and attachment_size is not null
      and attachment_expires_at is not null
      and (attachment_expired = true or attachment_path is not null)
    )
  );

create index if not exists chat_messages_expiring_attachments_idx
  on public.chat_messages (attachment_expires_at)
  where attachment_expired = false and attachment_path is not null;

drop policy if exists "Send to your circle's chat" on public.chat_messages;
create policy "Send to your circle's chat"
  on public.chat_messages
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_circle_member(circle_id)
    and kind in ('text', 'location_share', 'gif', 'file')
  );

-- Private bucket for chat attachments (15 MB max per file)
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'chat-attachments',
  'chat-attachments',
  false,
  15728640,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/pdf',
    'text/plain',
    'text/csv',
    'application/zip',
    'application/x-zip-compressed',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'video/mp4',
    'video/quicktime'
  ]
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Storage RLS for `chat-attachments`:
--   group/{circle_id}/{sender_id}/{file}
--   dm/{thread_id}/{sender_id}/{file}
create policy "Read chat attachments in your circles or DMs"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'chat-attachments'
    and array_length(storage.foldername(name), 1) = 3
    and (
      (
        (storage.foldername(name))[1] = 'group'
        and exists (
          select 1
          from public.circle_members membership
          where membership.user_id = (select auth.uid())
            and membership.circle_id::text = (storage.foldername(name))[2]
        )
      )
      or (
        (storage.foldername(name))[1] = 'dm'
        and exists (
          select 1
          from public.direct_threads t
          where t.id::text = (storage.foldername(name))[2]
            and (select auth.uid()) in (t.user_a, t.user_b)
            and public.shares_circle_with(
              case
                when t.user_a = (select auth.uid()) then t.user_b
                else t.user_a
              end
            )
        )
      )
    )
  );

create policy "Upload chat attachments to your circles or DMs"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and array_length(storage.foldername(name), 1) = 3
    and (storage.foldername(name))[3] = (select auth.uid())::text
    and (
      (
        (storage.foldername(name))[1] = 'group'
        and exists (
          select 1
          from public.circle_members membership
          where membership.user_id = (select auth.uid())
            and membership.circle_id::text = (storage.foldername(name))[2]
        )
      )
      or (
        (storage.foldername(name))[1] = 'dm'
        and exists (
          select 1
          from public.direct_threads t
          where t.id::text = (storage.foldername(name))[2]
            and (select auth.uid()) in (t.user_a, t.user_b)
            and public.shares_circle_with(
              case
                when t.user_a = (select auth.uid()) then t.user_b
                else t.user_a
              end
            )
        )
      )
    )
  );

create policy "Delete your own chat attachments"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'chat-attachments'
    and owner_id = (select auth.uid())::text
  );
