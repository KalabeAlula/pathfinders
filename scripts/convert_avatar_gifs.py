#!/usr/bin/env python3
"""
Convert Fortnite animated GIFs to:
1. Animated WebP (180x180) for Supabase Storage upload
2. Static PNG (180x180, frame 0) for bundled assets/avatars/

Usage: python scripts/convert_avatar_gifs.py
"""

import os
from pathlib import Path
from PIL import Image

# Source and output directories
SOURCE_DIR = Path(r"D:\pofile_pics")
WEBP_OUTPUT = Path(r"D:\avatar_webp_converted")
PNG_OUTPUT = Path("assets/avatars/converted")

def convert_gif_to_avatar(gif_path: Path, output_name: str):
    """Convert a single GIF to animated WebP and static PNG"""
    print(f"\n📦 Processing: {gif_path.name}")
    
    try:
        # Open the animated GIF
        with Image.open(gif_path) as img:
            # Get total frames
            frame_count = getattr(img, 'n_frames', 1)
            print(f"   Frames: {frame_count}")
            
            # === ANIMATED WEBP (all frames, 180x180) ===
            webp_path = WEBP_OUTPUT / f"{output_name}.webp"
            frames = []
            durations = []
            
            # Limit to max 60 frames for reasonable file size
            max_frames = min(frame_count, 60)
            frame_step = max(1, frame_count // max_frames)
            
            for frame_idx in range(0, frame_count, frame_step):
                if len(frames) >= max_frames:
                    break
                img.seek(frame_idx)
                frame = img.convert("RGBA")
                
                # Resize to 180x180 (faster BICUBIC for speed)
                frame_resized = frame.resize((180, 180), Image.Resampling.BICUBIC)
                frames.append(frame_resized)
                
                # Get frame duration (default 100ms if not specified)
                duration = img.info.get('duration', 100)
                durations.append(duration)
            
            print(f"   Using {len(frames)}/{frame_count} frames...", end='', flush=True)
            
            # Save animated WebP (faster settings)
            frames[0].save(
                webp_path,
                format='WEBP',
                save_all=True,
                append_images=frames[1:],
                duration=durations,
                loop=0,  # infinite loop
                quality=80,  # Slightly lower for speed
                method=4  # Faster compression (was 6)
            )
            webp_size_kb = webp_path.stat().st_size / 1024
            print(f" ✅ WebP: {webp_size_kb:.1f} KB")
            
            # === STATIC PNG (frame 0 only, 180x180) ===
            png_path = PNG_OUTPUT / f"{output_name}.png"
            img.seek(0)  # First frame
            static_frame = img.convert("RGBA")
            static_resized = static_frame.resize((180, 180), Image.Resampling.BICUBIC)
            static_resized.save(png_path, format='PNG', optimize=True)
            png_size_kb = png_path.stat().st_size / 1024
            print(f"   ✅ PNG:  {png_size_kb:.1f} KB")
            
    except Exception as e:
        print(f"   ❌ Error: {e}")

def main():
    # Create output directories
    WEBP_OUTPUT.mkdir(parents=True, exist_ok=True)
    PNG_OUTPUT.mkdir(parents=True, exist_ok=True)
    
    print("🎨 Fortnite Avatar Converter")
    print("=" * 60)
    print(f"Source: {SOURCE_DIR}")
    print(f"WebP Output: {WEBP_OUTPUT}")
    print(f"PNG Output: {PNG_OUTPUT}")
    print("=" * 60)
    
    # Find all Fortnite_animated-XX.gif files (01-23)
    gif_files = []
    for i in range(1, 24):
        gif_name = f"Fortnite_animated-{i:02d}.gif"
        gif_path = SOURCE_DIR / gif_name
        if gif_path.exists():
            gif_files.append((i, gif_path))
        else:
            print(f"⚠️  Missing: {gif_name}")
    
    print(f"\n📂 Found {len(gif_files)} GIF files")
    
    # Convert each GIF
    for idx, gif_path in gif_files:
        # Output naming: fortnite_01, fortnite_02, etc.
        output_name = f"fortnite_{idx:02d}"
        convert_gif_to_avatar(gif_path, output_name)
    
    print("\n" + "=" * 60)
    print("✨ Conversion complete!")
    print(f"\n📊 Summary:")
    print(f"   WebP files: {len(list(WEBP_OUTPUT.glob('*.webp')))} in {WEBP_OUTPUT}")
    print(f"   PNG files:  {len(list(PNG_OUTPUT.glob('*.png')))} in {PNG_OUTPUT}")
    
    # Calculate total sizes
    webp_total = sum(f.stat().st_size for f in WEBP_OUTPUT.glob('*.webp')) / 1024
    png_total = sum(f.stat().st_size for f in PNG_OUTPUT.glob('*.png')) / 1024
    print(f"\n💾 Total sizes:")
    print(f"   WebP (Supabase): {webp_total:.1f} KB")
    print(f"   PNG (bundled):   {png_total:.1f} KB (~{png_total:.0f} KB APK impact)")
    
    print("\n🔍 Next steps:")
    print("   1. Review converted files visually")
    print("   2. Pick descriptive names (or keep all 23)")
    print("   3. Run upload_avatar_stickers.py to push WebPs to Supabase")

if __name__ == "__main__":
    main()
