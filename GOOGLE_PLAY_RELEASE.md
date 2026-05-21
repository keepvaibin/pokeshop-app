# Google Play Release Notes

Use these values for the Google Play Console listing and Android release workflow.

## App Setup

- App name: SCTCG
- Package name: com.santacruztcg.pokeshop_app
- Default language: English (United States) - en-US
- Type: App
- Pricing: Free unless the business intentionally wants a paid app
- Current Flutter versionName/versionCode: 0.1.5 / 6

## Build

From this directory:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.santacruztcg.com/api
```

The Play upload artifact is generated at:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Release Signing

Do not upload a production App Bundle until `android/key.properties` exists locally and points at the release/upload keystore. The file is intentionally ignored by Git because it contains secrets.

Expected local shape:

```properties
storeFile=../keys/pokeshop-release.jks
storePassword=<keystore password>
keyAlias=<upload key alias>
keyPassword=<upload key password>
```

Keep Play App Signing enabled in the Play Console. The first uploaded package name, version code, and signing lineage become important long-term app identity decisions.

## Console Declarations

Review these before submitting:

- Developer Program Policies declaration
- Play App Signing terms
- US export laws declaration
- Data safety form for account data, contact details, order/purchase information, push notifications, and any uploaded images
- Privacy policy URL

## Integration Checks

- `android/app/google-services.json` is present and matches package `com.santacruztcg.pokeshop_app`.
- If Google Sign-In is enabled for Android release builds, make sure Firebase/Google Cloud has the release SHA certificate registered for this package.
- The Android notification permission is declared; Play data safety should mention push notifications if used.
