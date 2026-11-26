# Next Steps - Pet Sticker Migration

## Quick Action Checklist

### ✅ Completed (by AI)
- [x] Created Supabase Storage migration
- [x] Added flutter_cache_manager dependency
- [x] Updated sticker_assets.dart to generate Supabase URLs
- [x] Updated animated_pet_sticker.dart with caching support
- [x] Created platform-specific implementations (mobile/web)
- [x] Updated tests
- [x] Created upload script
- [x] Created documentation
- [x] All tests passing
- [x] Flutter analyze clean (only pre-existing warnings)

### 🔄 Your Tasks (in order)

#### 1. Apply Migration & Upload Files (10 minutes)
```powershell
# 1a. Apply the database migration
cd D:\Project\Flutter\pathfinders
supabase db push
# or for local: supabase db reset

# 1b. Get your Supabase credentials
# - Project URL: https://[YOUR-PROJECT].supabase.co
# - Service role key: (from Dashboard → Project Settings → API)

# 1c. Upload WebP files
pip install requests  # if needed
python scripts/upload_pet_stickers.py "YOUR_URL" "YOUR_SERVICE_ROLE_KEY"

# Expected: "✨ Upload complete! Successfully uploaded: 96 files"
```

#### 2. Verify Upload (2 minutes)
```powershell
# Open the test URL provided by the upload script in your browser
# Example: https://[YOUR-PROJECT].supabase.co/storage/v1/object/public/pet-stickers/fox/idle_1.webp
# Should see: Animated WebP playing smoothly
```

#### 3. Test in App (5 minutes)
```powershell
# Run the app on a device/emulator
flutter run

# Check:
# - Navigate to screens with pet stickers
# - Verify stickers load and animate
# - Check debug console for errors
# - Try offline mode (should show static avatars)
```

#### 4. Backup & Remove WebPs (5 minutes)
**⚠️ Only after Step 3 succeeds!**

```powershell
# Create backup
mkdir D:\pet_webp_backup
xcopy assets\pets\fox\*.webp D:\pet_webp_backup\fox\ /I /Y
xcopy assets\pets\seagull\*.webp D:\pet_webp_backup\seagull\ /I /Y
xcopy assets\pets\dog\*.webp D:\pet_webp_backup\dog\ /I /Y
xcopy assets\pets\orangutan\*.webp D:\pet_webp_backup\orangutan\ /I /Y

# Verify backup
Get-ChildItem D:\pet_webp_backup -Recurse -Filter *.webp | Measure-Object
# Should show: Count = 96

# Delete from assets
Remove-Item assets\pets\fox\*.webp
Remove-Item assets\pets\seagull\*.webp
Remove-Item assets\pets\dog\*.webp
Remove-Item assets\pets\orangutan\*.webp

# Verify only PNGs remain
Get-ChildItem assets\pets -Recurse
# Should show: Only 4 PNG files + 4 empty directories
```

#### 5. Update pubspec.yaml (1 minute)
Edit `pubspec.yaml` and remove these 4 lines:

```yaml
# REMOVE:
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

#### 6. Build & Measure (5 minutes)
```powershell
flutter clean
flutter pub get
flutter build apk --split-per-abi

# Check APK sizes
Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}}

# Expected: ~44 MB per ABI (down from ~114 MB)
```

#### 7. Final Verification (2 minutes)
```powershell
# Run tests
flutter test test/widgets/pet_sticker_test.dart test/widgets/pet_sticker_assets_test.dart
# Expected: All tests passed!

# Run analyzer
flutter analyze
# Expected: Same warnings as before (5 pre-existing warnings, none from our changes)

# Install and test on device
flutter install
# Navigate to pet stickers, verify they still work
```

## 📋 Total Time: ~30 minutes

## 🚨 If Something Goes Wrong

See `scripts/README_STICKER_MIGRATION.md` for detailed troubleshooting.

Quick rollback:
```powershell
# Restore WebPs from backup
xcopy D:\pet_webp_backup\*.webp assets\pets\ /S /I /Y

# Restore pubspec.yaml
git checkout HEAD -- pubspec.yaml

# Restore code
git checkout HEAD -- lib/features/pet/presentation/sticker_assets.dart
git checkout HEAD -- lib/features/pet/presentation/widgets/animated_pet_sticker.dart
git checkout HEAD -- lib/features/pet/presentation/widgets/cached_sticker*.dart

# Remove dependency
# (manually edit pubspec.yaml to remove flutter_cache_manager)

flutter pub get
```

## 📚 Documentation

- **Full guide**: `scripts/README_STICKER_MIGRATION.md`
- **Summary**: `STICKER_MIGRATION_SUMMARY.md`
- **This checklist**: `NEXT_STEPS.md`

## 💡 Key Points

1. **WebPs are now remote**: Loaded from Supabase Storage, cached locally
2. **PNGs stay bundled**: 4 static avatars for instant display
3. **Offline works**: Shows static PNGs + cached WebPs
4. **APK shrinks**: ~70 MB smaller
5. **UX unchanged**: Users see the same smooth animations
6. **Web supported**: Uses Image.network, browser handles caching

## ✅ Success Criteria

- [ ] Upload script reports 96 files uploaded
- [ ] Test URL loads in browser
- [ ] App runs without errors
- [ ] Pet stickers animate in app
- [ ] APK size ~44 MB per ABI
- [ ] Tests pass
- [ ] Analyzer clean (same warnings as before)

When all checked, you're done! 🎉
