#!/usr/bin/env python3
"""
Upload 23 animated avatar WebPs to Supabase Storage (avatar-stickers bucket).

Renames files from fortnite_01.webp -> cuddle_bear.webp using the official mapping.

Usage: python scripts/upload_avatar_stickers.py
"""

import os
from pathlib import Path
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://ijqweyrwyfmtkfsscarg.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqcXdleXJ3eWZtdGtmc3NjYXJnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzUxODA0NCwiZXhwIjoyMTA5MDk0MDQ0fQ.kGFQgfkDzNOtLzyPLhk9qzO0vIT6IOz0fww2zaNgiW8"

BUCKET_NAME = "avatar-stickers"
SOURCE_DIR = Path(r"D:\avatar_webp_converted")

# Official avatar ID mapping (fortnite_XX -> avatar_id)
AVATAR_MAPPING = {
    "fortnite_01": "cuddle_bear",
    "fortnite_02": "tech_bandit",
    "fortnite_03": "dark_knight",
    "fortnite_04": "robo_soldier",
    "fortnite_05": "party_king",
    "fortnite_06": "bush_ranger",
    "fortnite_07": "skull_trooper",
    "fortnite_08": "tomato_head",
    "fortnite_09": "tac_ops",
    "fortnite_10": "outlaw",
    "fortnite_11": "ice_monk",
    "fortnite_12": "love_ranger",
    "fortnite_13": "dab_champion",
    "fortnite_14": "astro_ace",
    "fortnite_15": "bunny_brawler",
    "fortnite_16": "blue_hoodie",
    "fortnite_17": "go_go",
    "fortnite_18": "grumpy_witch",
    "fortnite_19": "gingerbread",
    "fortnite_20": "llama_loot",
    "fortnite_21": "scout",
    "fortnite_22": "hype_dancer",
    "fortnite_23": "cash_grab",
}

def upload_avatar(supabase: Client, local_path: Path, storage_name: str):
    """Upload a single avatar WebP to Supabase Storage"""
    try:
        with open(local_path, "rb") as f:
            file_data = f.read()
        
        # Upload with cache-control for 1 year (immutable content)
        response = supabase.storage.from_(BUCKET_NAME).upload(
            path=storage_name,
            file=file_data,
            file_options={
                "content-type": "image/webp",
                "cache-control": "public, max-age=31536000",  # 1 year
                "upsert": "true"  # Overwrite if exists
            }
        )
        
        size_kb = len(file_data) / 1024
        print(f"  ✅ {storage_name:20s} ({size_kb:6.1f} KB)")
        return True
        
    except Exception as e:
        print(f"  ❌ {storage_name:20s} - Error: {e}")
        return False

def ensure_bucket_exists(supabase: Client):
    """Create avatar-stickers bucket if it doesn't exist"""
    try:
        # Try to list files (will fail if bucket doesn't exist)
        supabase.storage.from_(BUCKET_NAME).list()
        print("  ✓ Bucket already exists")
    except Exception:
        print("  ⚙️  Creating bucket...")
        try:
            supabase.storage.create_bucket(
                BUCKET_NAME,
                options={
                    "public": True,
                    "fileSizeLimit": 2097152,  # 2 MB
                    "allowedMimeTypes": ["image/webp"]
                }
            )
            print("  ✅ Bucket created successfully")
        except Exception as e:
            print(f"  ⚠️  Bucket creation error (may already exist): {e}")

def main():
    print("🎮 Avatar Stickers Upload")
    print("=" * 70)
    print(f"Supabase URL: {SUPABASE_URL}")
    print(f"Bucket:       {BUCKET_NAME}")
    print(f"Source:       {SOURCE_DIR}")
    print("=" * 70)
    
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    # Ensure bucket exists
    ensure_bucket_exists(supabase)
    
    # Upload all 23 avatars
    success_count = 0
    fail_count = 0
    
    for old_name, new_id in AVATAR_MAPPING.items():
        source_file = SOURCE_DIR / f"{old_name}.webp"
        storage_name = f"{new_id}.webp"
        
        if not source_file.exists():
            print(f"  ⚠️  {storage_name:20s} - Source file missing: {source_file}")
            fail_count += 1
            continue
        
        if upload_avatar(supabase, source_file, storage_name):
            success_count += 1
        else:
            fail_count += 1
    
    print("=" * 70)
    print(f"✨ Upload complete!")
    print(f"   ✅ Success: {success_count}/23")
    if fail_count > 0:
        print(f"   ❌ Failed:  {fail_count}/23")
    
    print(f"\n🔗 Public URL format:")
    print(f"   {SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/{{avatar_id}}.webp")
    print(f"\n📝 Example:")
    print(f"   {SUPABASE_URL}/storage/v1/object/public/{BUCKET_NAME}/cuddle_bear.webp")

if __name__ == "__main__":
    main()
