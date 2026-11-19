-- Pathfinders: Giphy GIFs in the crew chat.
--
-- The message body carries the media URL. Both the payload check and the
-- insert policy pin it to https Giphy hosts, so no member can point a bubble —
-- or another member's phone — at an arbitrary link.

alter table public.chat_messages
  drop constraint chat_messages_kind_check,
  add constraint chat_messages_kind_check
    check (kind in ('text', 'location_share', 'destination_update', 'gif'));

alter table public.chat_messages
  drop constraint chat_messages_payload_check,
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
  );

drop policy "Send to your circle's chat" on public.chat_messages;

create policy "Send to your circle's chat"
  on public.chat_messages
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_circle_member(circle_id)
    and kind in ('text', 'location_share', 'gif')
  );
