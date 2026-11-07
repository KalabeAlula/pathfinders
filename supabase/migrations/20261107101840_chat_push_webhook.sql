-- Cloud push plumbing: every chat message fires a webhook into the notify-chat
-- Edge Function, and the function reads its secrets from Vault with the
-- service role (clients never see them).
create extension if not exists pg_net;

create or replace function public.read_push_secret(p_name text)
returns text
language sql
security definer
set search_path = ''
as $$
  select decrypted_secret from vault.decrypted_secrets where name = p_name;
$$;

revoke all on function public.read_push_secret(text) from public, anon, authenticated;
grant execute on function public.read_push_secret(text) to service_role;

create or replace function private.notify_chat_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  secret text;
begin
  select decrypted_secret into secret
  from vault.decrypted_secrets
  where name = 'push_webhook_secret';

  -- No secret yet means push is not configured; drop the event quietly.
  if secret is null then
    return new;
  end if;

  perform net.http_post(
    url := 'https://ijqweyrwyfmtkfsscarg.supabase.co/functions/v1/notify-chat',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || secret
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'chat_messages',
      'schema', 'public',
      'record', to_jsonb(new)
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

drop trigger if exists chat_messages_push on public.chat_messages;
create trigger chat_messages_push
  after insert on public.chat_messages
  for each row execute function private.notify_chat_push();
