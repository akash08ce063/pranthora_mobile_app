# Quick Build Reference - Pranthora App

Quick reference for common build commands. See `BUILD_AND_RELEASE_GUIDE.md` for detailed instructions.

## 📱 Android Quick Commands

```bash
# Clean and build App Bundle (for Play Store)
flutter clean && flutter pub get && flutter build appbundle --release

# Build APK (for testing)
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi --release

# Install on connected device
flutter install --release
```

**Output Locations:**
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## 🍎 iOS Quick Commands

```bash
# Clean and build iOS
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ios --release

# Open in Xcode (for archiving)
open ios/Runner.xcworkspace

# In Xcode: Product → Archive → Distribute App
```

## 🔄 Version Update

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Format: VERSION+BUILD_NUMBER
```

## 📦 Bundle IDs

**Current (Development):**
- Android: `com.example.pranthora_app`
- iOS: `com.example.pranthoraApp`

**Recommended (Production):**
- Android: `com.firstpeak.pranthora`
- iOS: `com.firstpeak.pranthora`

## 🔐 Android Signing

**Key Location:** `android/key.properties` (create if missing)

**Keystore Location:** `android/app/pranthora-release-key.jks`

**Generate Keystore:**
```bash
cd android/app
keytool -genkey -v -keystore pranthora-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pranthora-key
```

## ✅ Pre-Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update bundle IDs (Android & iOS)
- [ ] Configure signing (Android keystore)
- [ ] Test on physical devices
- [ ] Prepare store assets (screenshots, descriptions)
- [ ] Build release artifacts
- [ ] Upload to stores
- [ ] Submit for review

## 🚨 Common Issues

**Android: "Keystore not found"**
- Ensure `android/key.properties` exists with correct paths

**iOS: "Signing error"**
- Clean build folder: `Product → Clean Build Folder` (Shift+Cmd+K)
- Verify team is selected in Xcode Signing & Capabilities

**"Pod install fails"**
```bash
cd ios && pod deintegrate && pod install && cd ..
```

---

For detailed instructions, see `BUILD_AND_RELEASE_GUIDE.md`

