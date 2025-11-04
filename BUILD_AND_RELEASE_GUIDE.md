# Pranthora App - Build & Release Guide

Complete step-by-step guide for building and releasing Android (APK/AAB) and iOS apps to Google Play Store and Apple App Store.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Bundle ID Configuration](#bundle-id-configuration)
3. [Android Build & Release](#android-build--release)
4. [iOS Build & Release](#ios-build--release)
5. [Version Management](#version-management)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts
- ✅ **Google Play Console Account** (Developer account: $25 one-time fee)
- ✅ **Apple Developer Account** ($99/year)
- ✅ **Flutter SDK** (3.9.2 or higher)
- ✅ **Android Studio** (latest version)
- ✅ **Xcode** (latest version for macOS)

### Required Tools
```bash
# Check Flutter installation
flutter doctor -v

# Verify required tools
- Android SDK (via Android Studio)
- Xcode Command Line Tools (for iOS)
- CocoaPods (for iOS dependencies)
```

### Install CocoaPods (if not already installed)
```bash
sudo gem install cocoapods
```

---

## Bundle ID Configuration

### Current Configuration
- **Android Package Name**: `com.example.pranthora_app` ⚠️ **MUST CHANGE**
- **iOS Bundle ID**: `com.example.pranthoraApp` ⚠️ **MUST CHANGE**

### Recommended Production Bundle IDs
- **Android**: `com.firstpeak.pranthora` or `com.yourcompany.pranthora`
- **iOS**: `com.firstpeak.pranthora` or `com.yourcompany.pranthora`

> ⚠️ **Important**: Bundle IDs must be unique and cannot be changed after app publication. Choose carefully!

---

## Android Build & Release

### Step 1: Configure Application ID

#### 1.1 Update `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.firstpeak.pranthora"  // Change this
    // ... other config ...

    defaultConfig {
        applicationId = "com.firstpeak.pranthora"  // Change this
        // ... rest of config ...
    }
}
```

#### 1.2 Update Package Structure (Optional but Recommended)

If you change the package name, update the directory structure:

```bash
# Create new package structure
mkdir -p android/app/src/main/kotlin/com/firstpeak/pranthora

# Move MainActivity.kt
mv android/app/src/main/kotlin/com/example/pranthora_app/MainActivity.kt \
   android/app/src/main/kotlin/com/firstpeak/pranthora/

# Update package name in MainActivity.kt
sed -i '' 's/package com.example.pranthora_app/package com.firstpeak.pranthora/g' \
   android/app/src/main/kotlin/com/firstpeak/pranthora/MainActivity.kt

# Remove old directory
rm -rf android/app/src/main/kotlin/com/example
```

#### 1.3 Update AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.firstpeak.pranthora">
    <!-- rest of manifest -->
</manifest>
```

### Step 2: Generate Signing Key

#### 2.1 Create Keystore

```bash
cd android/app

keytool -genkey -v -keystore pranthora-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pranthora-key \
  -storepass YOUR_KEYSTORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

> 📝 **Important**: 
> - Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with strong passwords
> - Save these passwords securely (use a password manager)
> - The `pranthora-release-key.jks` file is critical - **back it up securely!**
> - Never commit this file to version control

#### 2.2 Create `key.properties` File

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pranthora-key
storeFile=../app/pranthora-release-key.jks
```

> ⚠️ **Security**: Add `key.properties` and `*.jks` to `.gitignore`:
> ```bash
> echo "key.properties" >> .gitignore
> echo "*.jks" >> .gitignore
> ```

#### 2.3 Update `build.gradle.kts` for Signing

```kotlin
// android/app/build.gradle.kts

// Add at the top of the file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 3: Update Version Number

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

- **Version Name** (1.0.0): User-facing version
- **Version Code** (+1): Internal build number (must increment for each release)

### Step 4: Build App Bundle (AAB) for Play Store

#### 4.1 Build Release AAB

```bash
cd pranthora_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle (Recommended for Play Store)
flutter build appbundle --release
```

Output location: `build/app/outputs/bundle/release/app-release.aab`

#### 4.2 Build APK (For Testing or Direct Distribution)

```bash
# Build release APK
flutter build apk --release

# For split APKs (smaller size per architecture)
flutter build apk --split-per-abi --release
```

Output locations:
- Single APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: 
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Step 5: Test the Release Build

#### 5.1 Install on Device

```bash
# Install release APK on connected device
flutter install --release

# Or manually install APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 5.2 Verify Signing

```bash
# Check if APK is signed
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# For AAB, use bundletool
bundletool verify --bundle=build/app/outputs/bundle/release/app-release.aab
```

### Step 6: Upload to Google Play Store

#### 6.1 Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - **App name**: Pranthora
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free (or Paid)
   - **Declarations**: Complete all required sections

#### 6.2 Complete Store Listing

Required information:
- **App icon**: 512x512px PNG (no transparency)
- **Feature graphic**: 1024x500px
- **Screenshots**: 
  - Phone: At least 2 (up to 8)
  - Tablet: Optional but recommended
- **Short description**: 80 characters max
- **Full description**: 4000 characters max
- **Privacy Policy URL**: Required

#### 6.3 Set Up App Content

1. **Content rating**: Complete questionnaire
2. **Target audience**: Select appropriate age groups
3. **Data safety**: Declare data collection practices
4. **Ads**: Declare if app contains ads

#### 6.4 Upload AAB

1. Go to **Production** → **Create new release**
2. Upload `app-release.aab`
3. Add **Release notes** (what's new in this version)
4. Click **Review release**

#### 6.5 Submit for Review

1. Complete all required sections (marked with ⚠️)
2. Click **Send for review**
3. Review typically takes 1-3 days

---

## iOS Build & Release

### Step 1: Configure Bundle Identifier

#### 1.1 Update Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode:
```bash
open ios/Runner.xcworkspace
```

2. In Xcode:
   - Select **Runner** project in left sidebar
   - Select **Runner** target
   - Go to **Signing & Capabilities** tab
   - Change **Bundle Identifier** to: `com.firstpeak.pranthora`
   - Ensure **Automatically manage signing** is checked

#### 1.2 Update Info.plist (Optional)

The bundle ID in Info.plist uses `$(PRODUCT_BUNDLE_IDENTIFIER)`, so it will automatically use the Xcode setting.

### Step 2: Set Up Apple Developer Account

#### 2.1 Register App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (Add)
4. Select **App IDs** → **Continue**
5. Select **App** → **Continue**
6. Enter:
   - **Description**: Pranthora App
   - **Bundle ID**: `com.firstpeak.pranthora` (must match Xcode)
   - **Capabilities**: Enable required ones (Push Notifications, etc.)
7. Click **Continue** → **Register**

#### 2.2 Create Distribution Certificate

1. In **Certificates** → **+** (Add)
2. Select **Apple Distribution** → **Continue**
3. Upload Certificate Signing Request (CSR):
   ```bash
   # On macOS, open Keychain Access
   # Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   # Enter email and name, save to disk
   ```
4. Upload the CSR file
5. Download the certificate and double-click to install

#### 2.3 Create Provisioning Profile

1. In **Profiles** → **+** (Add)
2. Select **App Store** → **Continue**
3. Select **App ID**: `com.firstpeak.pranthora`
4. Select **Certificate**: Your distribution certificate
5. Enter **Profile Name**: Pranthora App Store
6. Download and double-click to install

### Step 3: Configure Xcode Signing

1. In Xcode, select **Runner** target
2. Go to **Signing & Capabilities**
3. Select your **Team** (Apple Developer account)
4. Ensure **Bundle Identifier** matches: `com.firstpeak.pranthora`
5. Xcode will automatically select the provisioning profile

### Step 4: Update Version & Build Number

#### 4.1 Update pubspec.yaml

```yaml
version: 1.0.0+1  # Same format as Android
```

#### 4.2 Update in Xcode (Alternative)

1. In Xcode, select **Runner** target
2. Go to **General** tab
3. Update:
   - **Version**: 1.0.0 (CFBundleShortVersionString)
   - **Build**: 1 (CFBundleVersion)

### Step 5: Prepare App Icons

Ensure app icons are set up:

```bash
# Generate icons if needed
flutter pub run flutter_launcher_icons:main
```

Icons should be in:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Step 6: Build for App Store

#### 6.1 Archive Build

**Option A: Using Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Any iOS Device** or **Generic iOS Device** as target
3. Menu: **Product** → **Archive**
4. Wait for archive to complete
5. **Organizer** window will open automatically

**Option B: Using Command Line**

```bash
cd ios

# Clean build
flutter clean
flutter pub get

# Build iOS
flutter build ios --release

# Archive (requires Xcode)
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
```

#### 6.2 Validate Archive

1. In Xcode Organizer, select your archive
2. Click **Validate App**
3. Fix any issues if prompted
4. Wait for validation to complete

#### 6.3 Distribute to App Store

1. In Xcode Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Select distribution options:
   - **Upload**: Upload directly to App Store Connect
   - **Export**: Save for manual upload (optional)
5. Follow the wizard to complete upload

### Step 7: Configure App Store Connect

#### 7.1 Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** (Create App)
3. Fill in:
   - **Platform**: iOS
   - **Name**: Pranthora
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.firstpeak.pranthora`
   - **SKU**: pranthora-ios-001 (unique identifier)
   - **User Access**: Full Access (or limited)

#### 7.2 Complete App Information

**App Information Tab:**
- **Category**: Select appropriate categories
- **Privacy Policy URL**: Required
- **Subtitle**: Optional short description

**Pricing and Availability:**
- **Price**: Free or set price
- **Availability**: Select countries/regions

**App Privacy:**
- Complete privacy questionnaire
- Declare data collection practices

#### 7.3 Prepare Store Listing

**1. App Store Screenshots:**
- iPhone 6.7" (iPhone 14 Pro Max): 1290x2796px
- iPhone 6.5" (iPhone 11 Pro Max): 1242x2688px
- iPhone 5.5" (iPhone 8 Plus): 1242x2208px
- iPad Pro 12.9": 2048x2732px
- iPad Pro 11": 1668x2388px

**2. App Preview Videos** (Optional):
- 30-second videos showing app features

**3. Description:**
- **Name**: Pranthora (30 characters max)
- **Subtitle**: Short tagline (30 characters max)
- **Description**: Full description (4000 characters max)
- **Keywords**: Comma-separated keywords (100 characters max)
- **Promotional Text**: Optional (170 characters max)
- **Support URL**: Required
- **Marketing URL**: Optional

**4. App Icon:**
- 1024x1024px PNG (no transparency, no rounded corners)

**5. Version Information:**
- **Copyright**: © 2025 Your Company Name
- **Version**: What's New in This Version

#### 7.4 Submit for Review

1. Go to **App Store** tab
2. Select **+ Version or Platform**
3. Select the build you uploaded
4. Complete all required sections
5. Answer **Export Compliance** questions
6. Click **Submit for Review**

Review typically takes 24-48 hours, but can take up to a week.

---

## Version Management

### Version Number Format

**Format**: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

Example: `1.0.0+1`
- **1.0.0**: Version name (user-facing)
- **+1**: Build number (increment for each release)

### Updating Versions

#### For Android & iOS (Both)

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment both version and build number
```

#### Increment Rules

- **PATCH** (1.0.0 → 1.0.1): Bug fixes
- **MINOR** (1.0.0 → 1.1.0): New features (backward compatible)
- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
- **BUILD NUMBER**: Always increment for each release (even for same version)

### Version History Example

```
1.0.0+1  - Initial release
1.0.1+2  - Bug fixes
1.1.0+3  - New features
1.1.1+4  - Minor fixes
2.0.0+5  - Major update
```

---

## Build Commands Reference

### Android Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK (single)
flutter build apk --release

# Build APK (split by architecture)
flutter build apk --split-per-abi --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build with specific build number
flutter build appbundle --release --build-number=2

# Build with specific version
flutter build appbundle --release --build-name=1.0.1 --build-number=2

# Install on connected device
flutter install --release
```

### iOS Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build iOS (release)
flutter build ios --release

# Build iOS (with specific version)
flutter build ios --release --build-name=1.0.1 --build-number=2

# Open in Xcode
open ios/Runner.xcworkspace

# Archive via command line (after opening in Xcode)
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ios/build/Runner.xcarchive \
  archive
```

### Generate App Icons

```bash
# Generate icons from config in pubspec.yaml
flutter pub run flutter_launcher_icons:main
```

---

## Troubleshooting

### Android Issues

#### Issue: "Execution failed for task ':app:signReleaseBundle'"
**Solution**: Ensure `key.properties` exists and contains correct passwords.

#### Issue: "Keystore file not found"
**Solution**: Verify path in `key.properties` is correct (relative to `android/` directory).

#### Issue: Build fails with "minifyEnabled"
**Solution**: Add ProGuard rules or disable minification temporarily:
```kotlin
minifyEnabled = false
shrinkResources = false
```

#### Issue: "App not installed" on device
**Solution**: Uninstall previous version first, or increment version code.

### iOS Issues

#### Issue: "No signing certificate found"
**Solution**: 
1. Ensure you're logged into Xcode with your Apple ID
2. Select your team in Signing & Capabilities
3. Let Xcode automatically manage signing

#### Issue: "Provisioning profile doesn't match"
**Solution**: 
1. Delete existing provisioning profiles in Xcode
2. Let Xcode regenerate them automatically
3. Or manually download from Apple Developer Portal

#### Issue: "Archive failed: Code signing error"
**Solution**:
1. Clean build folder: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Re-archive

#### Issue: "Pod install fails"
**Solution**:
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
cd ..
```

#### Issue: "Flutter build ios fails"
**Solution**:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

### General Issues

#### Issue: "Build number already used"
**Solution**: Increment build number in `pubspec.yaml`.

#### Issue: "Version code must be incremented"
**Solution**: Android requires version code to always increase. Update build number.

#### Issue: "Bundle ID already exists"
**Solution**: 
- For Android: Change package name in `build.gradle.kts`
- For iOS: Change bundle identifier in Xcode or use a different bundle ID

---

## Pre-Release Checklist

### Android Checklist

- [ ] Updated `applicationId` in `build.gradle.kts`
- [ ] Created and secured keystore file
- [ ] Configured `key.properties` (not in git)
- [ ] Updated version in `pubspec.yaml`
- [ ] Tested release APK on device
- [ ] Verified app signing
- [ ] Prepared Play Store assets (screenshots, icons, descriptions)
- [ ] Completed Play Console setup
- [ ] Built and uploaded AAB
- [ ] Filled all required store listing information
- [ ] Submitted for review

### iOS Checklist

- [ ] Updated bundle identifier in Xcode
- [ ] Registered App ID in Apple Developer Portal
- [ ] Created distribution certificate
- [ ] Created provisioning profile
- [ ] Configured signing in Xcode
- [ ] Updated version in `pubspec.yaml` and Xcode
- [ ] Generated app icons
- [ ] Tested on physical iOS device
- [ ] Created app record in App Store Connect
- [ ] Prepared App Store assets (screenshots, descriptions)
- [ ] Archived and uploaded build
- [ ] Completed all App Store Connect sections
- [ ] Submitted for review

---

## Security Best Practices

### Keystore Security

1. **Never commit** keystore files or `key.properties` to version control
2. **Backup keystore** to secure location (encrypted cloud storage)
3. **Use strong passwords** for keystore and key
4. **Store passwords** in secure password manager
5. **Limit access** to keystore files

### Code Signing Security

1. **Keep certificates secure** - don't share private keys
2. **Use separate certificates** for development and production
3. **Revoke compromised certificates** immediately
4. **Enable two-factor authentication** on developer accounts

---

## Additional Resources

### Official Documentation

- [Flutter Build & Release](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

### Useful Tools

- **Bundletool**: For testing Android App Bundles
- **TestFlight**: For beta testing iOS apps
- **Google Play Internal Testing**: For beta testing Android apps
- **Firebase App Distribution**: For distributing test builds

---

## Support

For issues or questions:
1. Check [Flutter Documentation](https://docs.flutter.dev/)
2. Review [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
3. Check platform-specific documentation (Android/iOS)

---

**Last Updated**: 2025-01-03  
**App Version**: 1.0.0+1  
**Maintained by**: FirstPeak Development Team

