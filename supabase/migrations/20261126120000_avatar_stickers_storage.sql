-- Avatar Stickers Storage: Animated WebP avatars for profile/chat/groups
--
-- Updates profiles.avatar_id CHECK constraint to allow 23 new animated avatars
-- while keeping legacy Ethiopian animal IDs for backward compatibility.
--
-- Note: avatar-stickers storage bucket created manually via dashboard.

-- ============================================================================
-- Update profiles.avatar_id constraint to include new 23 avatars
-- ============================================================================

alter table public.profiles
  drop constraint if exists profiles_avatar_id_check;

alter table public.profiles
  add constraint profiles_avatar_id_check check (
    avatar_id in (
      -- Legacy Ethiopian animal avatars (keep for backward compatibility)
      'avatar_wolf',
      'avatar_lion',
      'avatar_lovebird',
      'avatar_ibex',
      'avatar_gelada',
      'avatar_monkey',
      'avatar_owl',
      'avatar_bear',
      'avatar_deer',
      'avatar_cat',
      -- New animated Fortnite-style avatars
      'cuddle_bear',
      'tech_bandit',
      'dark_knight',
      'robo_soldier',
      'party_king',
      'bush_ranger',
      'skull_trooper',
      'tomato_head',
      'tac_ops',
      'outlaw',
      'ice_monk',
      'love_ranger',
      'dab_champion',
      'astro_ace',
      'bunny_brawler',
      'blue_hoodie',
      'go_go',
      'grumpy_witch',
      'gingerbread',
      'llama_loot',
      'scout',
      'hype_dancer',
      'cash_grab'
    )
  );

comment on constraint profiles_avatar_id_check on public.profiles is
  'Catalog of 33 avatar IDs: 10 legacy Ethiopian animals + 23 animated Fortnite characters';
