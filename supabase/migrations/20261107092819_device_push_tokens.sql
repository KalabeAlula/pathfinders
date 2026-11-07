-- Cloud push targets, one row per device and account. FlutterFire 17 stores a
-- Firebase Installation ID, which is the direct-send target. The push function
-- reads these with the service role to reach members who are not running the
-- app; clients only ever touch their own rows.
create table public.device_push_tokens (
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

alter table public.device_push_tokens enable row level security;

create policy "Members read their own push tokens"
  on public.device_push_tokens for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Members register their own push tokens"
  on public.device_push_tokens for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Members refresh their own push tokens"
  on public.device_push_tokens for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Members remove their own push tokens"
  on public.device_push_tokens for delete
  to authenticated
  using ((select auth.uid()) = user_id);
