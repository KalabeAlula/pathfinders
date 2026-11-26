-- Run this SQL in Supabase Dashboard SQL Editor to create avatar-stickers bucket

-- Create bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatar-stickers',
  'avatar-stickers',
  true,
  2097152,  -- 2 MB
  ARRAY['image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Public read policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Avatar stickers are publicly readable'
  ) THEN
    CREATE POLICY "Avatar stickers are publicly readable"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'avatar-stickers');
  END IF;
END $$;

-- Service role upload policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Service role can upload avatar stickers'
  ) THEN
    CREATE POLICY "Service role can upload avatar stickers"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'avatar-stickers'
        AND auth.role() = 'service_role'
      );
  END IF;
END $$;

-- Allow authenticated users to also upload (for future profile updates)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Authenticated users can upload avatar stickers'
  ) THEN
    CREATE POLICY "Authenticated users can upload avatar stickers"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'avatar-stickers'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- Update profiles.avatar_id constraint
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_avatar_id_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_avatar_id_check CHECK (
    avatar_id IN (
      -- Legacy
      'avatar_wolf', 'avatar_lion', 'avatar_lovebird', 'avatar_ibex', 'avatar_gelada',
      'avatar_monkey', 'avatar_owl', 'avatar_bear', 'avatar_deer', 'avatar_cat',
      -- New animated
      'cuddle_bear', 'tech_bandit', 'dark_knight', 'robo_soldier', 'party_king',
      'bush_ranger', 'skull_trooper', 'tomato_head', 'tac_ops', 'outlaw',
      'ice_monk', 'love_ranger', 'dab_champion', 'astro_ace', 'bunny_brawler',
      'blue_hoodie', 'go_go', 'grumpy_witch', 'gingerbread', 'llama_loot',
      'scout', 'hype_dancer', 'cash_grab'
    )
  );

SELECT 'Avatar bucket and constraints created successfully!' AS result;
