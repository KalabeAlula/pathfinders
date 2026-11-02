-- Pathfinders: photos attached to memories.
--
-- Design notes:
--   * The bucket is private. Nothing is readable without a short-lived signed
--     URL, and those are only minted for members of the photo's circle.
--   * Objects live at `{circle_id}/{author_id}/{uuid}.{ext}`. RLS reads the
--     circle from the first folder and the author from the second, so a client
--     can never upload into somebody else's folder or another circle.
--   * The memories.photo_path check repeats that layout so a row cannot point
--     at an object outside its own circle.
--   * A memory may be a photo with no caption, hence the relaxed body checks.
--   * Text comparisons against the folder names avoid casting arbitrary object
--     names to uuid, which would raise instead of simply denying access.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

alter table public.memories
  add column photo_path text;

alter table public.memories
  alter column body drop not null;

alter table public.memories
  drop constraint memories_body_check;

alter table public.memories
  add constraint memories_body_check
    check (
      body is null
      or char_length(btrim(body)) between 1 and 600
    );

alter table public.memories
  add constraint memories_photo_path_check
    check (
      photo_path is null
      or (
        photo_path like circle_id::text || '/' || author_id::text || '/%'
        and char_length(photo_path) <= 200
      )
    );

alter table public.memories
  add constraint memories_content_check
    check (
      photo_path is not null
      or (body is not null and btrim(body) <> '')
    );

-- ---------------------------------------------------------------------------
-- Private bucket
-- ---------------------------------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'memories',
  'memories',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- Storage RLS
-- ---------------------------------------------------------------------------

-- Members can read photos anywhere inside a circle they belong to.
create policy "Read photos from your circles"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'memories'
    and exists (
      select 1
      from public.circle_members membership
      where membership.user_id = (select auth.uid())
        and membership.circle_id::text = (storage.foldername(name))[1]
    )
  );

-- Uploads must sit in `{their circle}/{them}/{file}`.
create policy "Upload photos to your circles"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'memories'
    and array_length(storage.foldername(name), 1) = 2
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1
      from public.circle_members membership
      where membership.user_id = (select auth.uid())
        and membership.circle_id::text = (storage.foldername(name))[1]
    )
  );

-- Only the uploader can remove a photo. The app uses this to clean up an
-- object when the memory row itself fails to insert.
create policy "Remove your own photos"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'memories'
    and owner_id = (select auth.uid())::text
  );
