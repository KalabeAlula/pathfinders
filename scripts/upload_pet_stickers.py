"""
Upload pet sticker WebP files to Supabase Storage.

Usage:
    python scripts/upload_pet_stickers.py <SUPABASE_URL> <SERVICE_ROLE_KEY>

Example:
    python scripts/upload_pet_stickers.py https://xxxxx.supabase.co eyJhbGc...
"""

import os
import sys
import requests
from pathlib import Path

def upload_stickers(supabase_url: str, service_role_key: str):
    """Upload all WebP stickers from assets/pets/ to Supabase Storage."""
    
    # Base directory
    base_dir = Path(__file__).parent.parent / "assets" / "pets"
    pets = ["fox", "seagull", "dog", "orangutan"]
    
    # Supabase Storage API endpoint
    storage_url = f"{supabase_url}/storage/v1/object/pet-stickers"
    
    headers = {
        "Authorization": f"Bearer {service_role_key}",
        "apikey": service_role_key,
    }
    
    uploaded = []
    failed = []
    
    print("Starting upload of pet stickers to Supabase Storage...")
    print(f"Target bucket: pet-stickers")
    print(f"Base URL: {storage_url}")
    print("-" * 60)
    
    for pet in pets:
        pet_dir = base_dir / pet
        if not pet_dir.exists():
            print(f"⚠️  Warning: Directory not found: {pet_dir}")
            continue
        
        # Find all .webp files in this pet's directory
        webp_files = list(pet_dir.glob("*.webp"))
        print(f"\n📁 Processing {pet} ({len(webp_files)} files)...")
        
        for webp_file in webp_files:
            # Storage path: <pet>/<filename>.webp
            storage_path = f"{pet}/{webp_file.name}"
            upload_url = f"{storage_url}/{storage_path}"
            
            try:
                with open(webp_file, "rb") as f:
                    file_data = f.read()
                
                # Upload with proper headers
                response = requests.post(
                    upload_url,
                    headers={
                        **headers,
                        "Content-Type": "image/webp",
                        "Cache-Control": "public, max-age=31536000",  # 1 year
                    },
                    data=file_data,
                )
                
                if response.status_code in (200, 201):
                    file_size_kb = len(file_data) / 1024
                    print(f"  ✅ {storage_path} ({file_size_kb:.1f} KB)")
                    uploaded.append(storage_path)
                else:
                    print(f"  ❌ {storage_path} - Status {response.status_code}: {response.text}")
                    failed.append(storage_path)
                    
            except Exception as e:
                print(f"  ❌ {storage_path} - Error: {e}")
                failed.append(storage_path)
    
    print("\n" + "=" * 60)
    print(f"✨ Upload complete!")
    print(f"   Successfully uploaded: {len(uploaded)} files")
    print(f"   Failed: {len(failed)} files")
    
    if failed:
        print("\n⚠️  Failed uploads:")
        for path in failed:
            print(f"   - {path}")
    
    # Test public URL for first sticker
    if uploaded:
        test_path = uploaded[0]
        public_url = f"{supabase_url}/storage/v1/object/public/pet-stickers/{test_path}"
        print(f"\n🔗 Test URL (open in browser to verify):")
        print(f"   {public_url}")
    
    return len(failed) == 0

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    
    supabase_url = sys.argv[1].rstrip("/")
    service_role_key = sys.argv[2]
    
    success = upload_stickers(supabase_url, service_role_key)
    sys.exit(0 if success else 1)
