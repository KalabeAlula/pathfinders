# Pet Sticker Migration to Supabase Storage

This guide walks through migrating the 96 animated WebP pet stickers from bundled Flutter assets to Supabase Storage, reducing APK size by ~70 MB.

## Overview

- **Before**: 96 WebP files (4 pets × 8 moods × 3 expressions) bundled in APK
- **After**: Only 4 static PNG avatars bundled; WebPs served from Supabase Storage with client-side caching
- **APK Size Reduction**: ~70 MB

## Step 1: Apply the Storage Bucket Migration

```powershell
cd D:\Project\Flutter\pathfinders

# If using local Supabase CLI (recommended for testing):
supabase db reset  # Apply all migrations including the new one

# Or apply directly to your remote project:
supabase db push
```

The migration (`20261126104337_pet_stickers_storage.sql`) creates:
- A public storage bucket named `pet-stickers`
- Public read policy (all users can download)
- Authenticated upload policy (for initial upload)

## Step 2: Upload WebP Files to Supabase Storage

You'll need:
- Your Supabase project URL (e.g., `https://xxxxx.supabase.co`)
- Your service role key (found in Supabase Dashboard → Project Settings → API → service_role key)

### Option A: Using the Python Script (Recommended)

```powershell
# Install requests if needed
pip install requests

# Run the upload script
python scripts/upload_pet_stickers.py "https://YOUR-PROJECT.supabase.co" "YOUR_SERVICE_ROLE_KEY"
```

The script will:
- Upload all 96 WebP files from `assets/pets/{pet}/*.webp`
- Set proper `Content-Type: image/webp` and cache headers
- Display progress and report any failures
- Provide a test URL to verify the first upload

### Option B: Using Supabase CLI

```powershell
# Upload each pet's directory
supabase storage cp assets/pets/fox/ pet-stickers/fox/ --recursive
supabase storage cp assets/pets/seagull/ pet-stickers/seagull/ --recursive
supabase storage cp assets/pets/dog/ pet-stickers/dog/ --recursive
supabase storage cp assets/pets/orangutan/ pet-stickers/orangutan/ --recursive
```

## Step 3: Verify Upload

Open one of these test URLs in your browser (replace YOUR-PROJECT):

```
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/fox/idle_1.webp
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/dog/celebrating_2.webp
```

You should see the animated WebP playing smoothly. If you see a 404 or access denied error, check:
1. The bucket policy is set to public read
2. The files were uploaded to the correct paths: `<pet>/<mood>_<index>.webp`

## Step 4: Update Supabase Client Configuration

Ensure your Flutter app has the correct Supabase URL configured. Check:

```dart
// lib/main.dart or wherever Supabase is initialized
await Supabase.initialize(
  url: 'https://YOUR-PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

## Step 5: Test the App

```powershell
# Run the app on a device/emulator
flutter run

# Check the debug console for any Supabase storage errors
# Navigate to screens showing pet stickers and verify they load smoothly
```

Expected behavior:
- Static PNG avatar shows immediately
- Animated WebP loads from cache (after first download)
- Smooth gapless playback with no flicker
- Fallback to static avatar if offline or on error

## Step 6: Backup and Remove Local WebP Files

**IMPORTANT**: Only do this AFTER verifying uploads work in the app!

```powershell
# Backup to safe location first
mkdir D:\pet_webp_backup
xcopy assets\pets\fox\*.webp D:\pet_webp_backup\fox\ /I /Y
xcopy assets\pets\seagull\*.webp D:\pet_webp_backup\seagull\ /I /Y
xcopy assets\pets\dog\*.webp D:\pet_webp_backup\dog\ /I /Y
xcopy assets\pets\orangutan\*.webp D:\pet_webp_backup\orangutan\ /I /Y

# Delete from assets (keeping PNG avatars)
Remove-Item assets\pets\fox\*.webp
Remove-Item assets\pets\seagull\*.webp
Remove-Item assets\pets\dog\*.webp
Remove-Item assets\pets\orangutan\*.webp
```

## Step 7: Update pubspec.yaml

Remove the 4 pet subfolder entries from `pubspec.yaml` (the WebP files are now gone):

```yaml
flutter:
  assets:
    - assets/branding/
    - assets/pets/  # Keep this - still has the 4 PNG files
    # REMOVE these 4 lines:
    # - assets/pets/fox/
    # - assets/pets/seagull/
    # - assets/pets/dog/
    # - assets/pets/orangutan/
    - assets/avatars/
```

## Step 8: Build and Measure APK Size

```powershell
# Clean build
flutter clean
flutter pub get

# Build split APKs
flutter build apk --split-per-abi

# Check sizes
Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}}
```

Expected APK size reduction: ~70 MB (from ~114 MB → ~44 MB per ABI).

## Rollback Instructions

If something goes wrong:

1. **Restore WebP files from backup**:
   ```powershell
   xcopy D:\pet_webp_backup\fox\*.webp assets\pets\fox\ /I /Y
   xcopy D:\pet_webp_backup\seagull\*.webp assets\pets\seagull\ /I /Y
   xcopy D:\pet_webp_backup\dog\*.webp assets\pets\dog\ /I /Y
   xcopy D:\pet_webp_backup\orangutan\*.webp assets\pets\orangutan\ /I /Y
   ```

2. **Restore pubspec.yaml** (add back the 4 folder entries)

3. **Revert code changes**:
   ```powershell
   git checkout HEAD -- lib/features/pet/presentation/sticker_assets.dart
   git checkout HEAD -- lib/features/pet/presentation/widgets/animated_pet_sticker.dart
   git checkout HEAD -- test/widgets/
   git checkout HEAD -- pubspec.yaml
   ```

4. **Remove the dependency**:
   ```powershell
   # Remove flutter_cache_manager from pubspec.yaml dependencies
   flutter pub get
   ```

## Technical Details

### Code Changes Summary

1. **sticker_assets.dart**: 
   - Now builds Supabase Storage URLs instead of asset paths
   - Falls back to placeholder URLs in tests where Supabase isn't initialized
   - Removed AssetManifest loading logic (no longer needed)

2. **animated_pet_sticker.dart**:
   - Added `flutter_cache_manager` for efficient network caching
   - New `_CachedNetworkSticker` widget uses `DefaultCacheManager().getSingleFile(url)`
   - `Image.file()` with `gaplessPlayback: true` (no cacheWidth/cacheHeight to preserve animation frames)
   - Automatic fallback to static PNG avatar while loading or on error

3. **Tests**:
   - `pet_sticker_assets_test.dart`: Now only tests the 4 bundled PNG avatars
   - `pet_sticker_test.dart`: Updated to test URL-based loading with mock Supabase URLs

### Caching Strategy

- **First load**: Downloads WebP from Supabase Storage, caches to device storage
- **Subsequent loads**: Instant load from cache
- **Cache headers**: `public, max-age=31536000` (1 year) set on upload
- **Fallback**: Static PNG avatar shown during load, error, or offline

### File Structure

Before:
```
assets/pets/
├── fox.png (43 KB)
├── fox/
│   ├── idle_1.webp (445 KB)
│   ├── idle_2.webp (392 KB)
│   └── ... (21 more)
├── seagull.png (48 KB)
├── seagull/ (24 WebP files)
├── dog.png (31 KB)
├── dog/ (24 WebP files)
├── orangutan.png (29 KB)
└── orangutan/ (24 WebP files)
Total: ~70 MB WebP + 152 KB PNG
```

After:
```
assets/pets/
├── fox.png (43 KB)
├── seagull.png (48 KB)
├── dog.png (31 KB)
└── orangutan.png (29 KB)
Total: 152 KB

Supabase Storage (pet-stickers bucket):
├── fox/ (24 WebP files)
├── seagull/ (24 WebP files)
├── dog/ (24 WebP files)
└── orangutan/ (24 WebP files)
```

## Troubleshooting

### "Failed to upload" errors
- Check your service role key is correct
- Verify the bucket was created (check Supabase Dashboard → Storage)
- Ensure the authenticated upload policy exists

### Stickers not loading in app
- Verify Supabase.initialize() was called in main.dart
- Check the public read policy exists on the bucket
- Test a public URL directly in a browser
- Check Flutter debug console for specific error messages

### App still large after removing WebPs
- Run `flutter clean` and rebuild
- Verify the WebP files are actually deleted from assets/pets/
- Confirm the 4 subfolder entries are removed from pubspec.yaml

### Stickers flicker or don't animate
- Ensure you're NOT using `cacheWidth` or `cacheHeight` on Image.file()
- Confirm `gaplessPlayback: true` is set
- Check that the downloaded file is a valid multi-frame WebP

## Support

If you encounter issues:
1. Check the Flutter debug console for error messages
2. Verify network requests in the app (use a network inspector)
3. Test the public URLs directly in a browser
4. Check Supabase Dashboard → Storage → pet-stickers for uploaded files
