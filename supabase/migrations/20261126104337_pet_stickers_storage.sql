-- Create pet-stickers storage bucket for animated WebP stickers
-- Public read access, optimized for long-term caching

-- Create the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pet-stickers',
  'pet-stickers',
  true,
  2097152, -- 2MB limit per file
  ARRAY['image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Allow public SELECT (read) for all users (anon & authenticated)
CREATE POLICY "Public read access to pet stickers"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pet-stickers');

-- Allow authenticated users to upload (for admin/migration purposes)
CREATE POLICY "Authenticated users can upload pet stickers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pet-stickers');
