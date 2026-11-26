# Pet Sticker Migration to Supabase Storage - Summary

## ✅ What's Been Done

All code changes are complete and tested. The app is ready to load animated pet stickers from Supabase Storage instead of bundled assets.

### 1. Database Migration Created
- **File**: `supabase/migrations/20261126104337_pet_stickers_storage.sql`
- Creates public `pet-stickers` storage bucket
- Sets up public read policy for anonymous & authenticated users
- Allows authenticated users to upload (for migration)

### 2. Code Changes

#### sticker_assets.dart
- **Before**: Returned local asset paths like `assets/pets/fox/idle_1.webp`
- **After**: Returns Supabase Storage public URLs
- Graceful fallback for unit tests where Supabase isn't initialized
- Removed AssetManifest loading logic (no longer needed)

#### animated_pet_sticker.dart
- Added support for both local assets (PNG avatars) and remote URLs (WebP stickers)
- Automatically detects URLs vs asset paths
- Uses platform-specific cached network loading

#### New Platform-Specific Files
- `cached_sticker.dart`: Platform-agnostic typedef
- `cached_sticker_io.dart`: Mobile/desktop implementation with flutter_cache_manager
- `cached_sticker_web.dart`: Web implementation with Image.network

**Mobile/Desktop Behavior**:
- Downloads WebP from Supabase Storage on first load
- Caches to device storage using `flutter_cache_manager`
- Instant load from cache on subsequent views
- Uses `Image.file()` with `gaplessPlayback: true` for smooth animation
- Shows static PNG avatar while loading or on error

**Web Behavior**:
- Uses `Image.network()` for simpler implementation
- Browser handles caching automatically
- Shows static PNG avatar while loading or on error

#### Tests Updated
- `pet_sticker_assets_test.dart`: Now only tests 4 static PNG avatars
- `pet_sticker_test.dart`: Tests remote URL loading with mock Supabase URLs
- All 14 tests passing ✅

#### Dependencies
- Added `flutter_cache_manager: ^3.4.1` to pubspec.yaml

### 3. Upload Script Created
- **File**: `scripts/upload_pet_stickers.py`
- Uploads all 96 WebP files to Supabase Storage
- Sets proper headers: `Content-Type: image/webp`, `Cache-Control: public, max-age=31536000`
- Progress reporting and error handling
- Provides test URL for verification

### 4. Documentation
- **File**: `scripts/README_STICKER_MIGRATION.md`
- Complete step-by-step migration guide
- Verification steps
- Rollback instructions
- Troubleshooting section

## 🔄 What You Need to Do Next

### Step 1: Apply the Migration
```powershell
cd D:\Project\Flutter\pathfinders

# For local testing:
supabase db reset

# For remote project:
supabase db push
```

### Step 2: Get Your Supabase Credentials
1. Go to your Supabase Dashboard
2. Navigate to Project Settings → API
3. Copy:
   - Project URL (e.g., `https://xxxxx.supabase.co`)
   - Service role key (not the anon key!)

### Step 3: Upload WebP Files
```powershell
# Install requests library if needed
pip install requests

# Run the upload script
python scripts/upload_pet_stickers.py "https://YOUR-PROJECT.supabase.co" "YOUR_SERVICE_ROLE_KEY"
```

Expected output:
```
Starting upload of pet stickers to Supabase Storage...
Target bucket: pet-stickers
...
📁 Processing fox (24 files)...
  ✅ fox/idle_1.webp (445.7 KB)
  ✅ fox/idle_2.webp (392.4 KB)
  ...
✨ Upload complete!
   Successfully uploaded: 96 files
   Failed: 0 files

🔗 Test URL (open in browser to verify):
   https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/fox/idle_1.webp
```

### Step 4: Verify Upload in Browser
Open the test URL provided by the script. You should see the animated WebP playing smoothly.

### Step 5: Test in the App
```powershell
# Run the app
flutter run

# Navigate to screens showing pet stickers
# Check debug console for any errors
# Verify stickers load and animate smoothly
```

**Expected behavior**:
- Static PNG avatar appears instantly
- Animated WebP loads shortly after (first time)
- Subsequent loads are instant (from cache)
- Smooth animation with no flicker
- Fallback to static avatar if offline

### Step 6: Backup & Remove Local WebPs

**⚠️ ONLY do this AFTER verifying Step 5 works!**

```powershell
# Create backup first
mkdir D:\pet_webp_backup
xcopy assets\pets\fox\*.webp D:\pet_webp_backup\fox\ /I /Y
xcopy assets\pets\seagull\*.webp D:\pet_webp_backup\seagull\ /I /Y
xcopy assets\pets\dog\*.webp D:\pet_webp_backup\dog\ /I /Y
xcopy assets\pets\orangutan\*.webp D:\pet_webp_backup\orangutan\ /I /Y

# Delete from assets (keeps PNG avatars)
Remove-Item assets\pets\fox\*.webp
Remove-Item assets\pets\seagull\*.webp
Remove-Item assets\pets\dog\*.webp
Remove-Item assets\pets\orangutan\*.webp
```

### Step 7: Update pubspec.yaml

Remove these 4 lines from the `flutter:` → `assets:` section:
```yaml
# REMOVE THESE:
- assets/pets/fox/
- assets/pets/seagull/
- assets/pets/dog/
- assets/pets/orangutan/
```

Keep:
```yaml
flutter:
  assets:
    - assets/branding/
    - assets/pets/  # Still has the 4 PNG files
    - assets/avatars/
```

### Step 8: Build & Measure APK Size
```powershell
flutter clean
flutter pub get
flutter build apk --split-per-abi

# Check sizes
Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}}
```

**Expected result**: APK size drops from ~114 MB to ~44 MB per ABI (~70 MB savings).

## 📊 Technical Details

### File Structure Before
```
assets/pets/
├── fox.png (43 KB) ✅ Kept
├── fox/
│   ├── idle_1.webp (445 KB) ❌ Moving to Supabase
│   ├── idle_2.webp (392 KB) ❌ Moving to Supabase
│   └── ... (21 more)
├── seagull.png (48 KB) ✅ Kept
├── seagull/ (24 WebP files) ❌ Moving to Supabase
├── dog.png (31 KB) ✅ Kept
├── dog/ (24 WebP files) ❌ Moving to Supabase
├── orangutan.png (29 KB) ✅ Kept
└── orangutan/ (24 WebP files) ❌ Moving to Supabase

Total: ~70 MB WebP + 152 KB PNG
```

### File Structure After
```
Local (bundled in APK):
assets/pets/
├── fox.png (43 KB)
├── seagull.png (48 KB)
├── dog.png (31 KB)
└── orangutan.png (29 KB)
Total: 152 KB

Remote (Supabase Storage, pet-stickers bucket):
├── fox/ (24 WebP files)
├── seagull/ (24 WebP files)
├── dog/ (24 WebP files)
└── orangutan/ (24 WebP files)
Total: ~70 MB (not in APK!)
```

### URL Examples

The app now generates URLs like:
```
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/fox/idle_1.webp
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/dog/celebrating_2.webp
https://YOUR-PROJECT.supabase.co/storage/v1/object/public/pet-stickers/seagull/hungry_3.webp
```

### Caching Strategy

**First Load** (per user, per device):
1. Static PNG avatar shows instantly (from bundled assets)
2. App requests WebP from Supabase Storage
3. `flutter_cache_manager` downloads and caches to device storage
4. WebP replaces PNG smoothly (gaplessPlayback)

**Subsequent Loads**:
1. Static PNG shows instantly
2. Cached WebP loads from local storage (instant)
3. No network request needed

**Cache Duration**:
- Files cached with `Cache-Control: public, max-age=31536000` (1 year)
- `flutter_cache_manager` default: 7 days (configurable)
- Perfect for static assets that never change

## 🔧 Verification Checklist

Before removing local WebPs:
- [ ] Migration applied successfully to Supabase
- [ ] All 96 WebP files uploaded (check upload script output)
- [ ] Test URL loads in browser and animates
- [ ] App runs without errors
- [ ] Pet stickers load and animate in app
- [ ] Static avatars show immediately
- [ ] No console errors related to Supabase Storage
- [ ] Offline mode shows static avatars (graceful degradation)

After removing local WebPs:
- [ ] `flutter analyze` passes (pre-existing warnings are fine)
- [ ] `flutter test` passes (all tests green)
- [ ] WebP files deleted from assets/pets/
- [ ] WebP files backed up to D:\pet_webp_backup\
- [ ] pubspec.yaml updated (4 subfolder entries removed)
- [ ] APK size reduced to ~44 MB per ABI
- [ ] App still runs and stickers still work

## 🚨 Troubleshooting

### "Failed to upload" errors
- Verify service role key is correct (not anon key)
- Check bucket was created (Supabase Dashboard → Storage)
- Ensure authenticated upload policy exists

### Stickers not loading in app
- Check Supabase.initialize() in main.dart has correct URL
- Verify public read policy on bucket
- Test public URL directly in browser
- Check Flutter debug console for specific errors

### App still large after removing WebPs
- Run `flutter clean`
- Verify WebPs actually deleted from assets/pets/
- Confirm subfolder entries removed from pubspec.yaml
- Rebuild APK

### Stickers flicker or don't animate
- Ensure `gaplessPlayback: true` is set
- Verify not using `cacheWidth` or `cacheHeight` (breaks animation)
- Check downloaded file is valid multi-frame WebP

## 🔄 Rollback Plan

If anything goes wrong, follow the rollback instructions in `scripts/README_STICKER_MIGRATION.md`.

Quick rollback:
```powershell
# Restore WebP files from backup
xcopy D:\pet_webp_backup\*.webp assets\pets\ /S /I /Y

# Restore pubspec.yaml and code
git checkout HEAD -- pubspec.yaml lib/features/pet/presentation/

# Remove flutter_cache_manager dependency
# (edit pubspec.yaml, remove the line)

flutter pub get
```

## 📝 Notes

- The 4 static PNG avatars remain bundled (152 KB total) for instant display
- Supabase Storage serves files via CDN with global edge caching
- Users only download WebPs they actually see (lazy loading)
- Storage cost: ~70 MB × $0.021/GB/month = ~$0.0015/month
- Bandwidth: Likely free tier (Supabase provides 2 GB egress/month free, then $0.09/GB)

## ✨ Benefits

- **APK Size**: 114 MB → 44 MB per ABI (61% reduction)
- **User Experience**: Faster app installs, same smooth sticker animations
- **Maintainability**: Update stickers without app release (just upload new files)
- **Scalability**: Add more stickers/pets without bloating APK
- **Offline Support**: Static PNG avatars always work, cached WebPs work offline after first load
