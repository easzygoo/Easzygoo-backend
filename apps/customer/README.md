# EaszyGoo — Customer app

React Native (Expo SDK 52) customer app. Navigation skeleton + native Firebase
phone-auth configuration.

## Native Firebase config

Phone auth uses `@react-native-firebase/auth`, which needs **native modules**.
Expo Go cannot run it — you need a **dev build**:

```bash
npx expo run:android          # local build, or
eas build --profile development --platform android
```

`expo-dev-client` is installed so the resulting build can load JS from the dev
server.

### Android — wired up

- `android.package` is `com.easzygoo.user`, matching the entry in
  `google-services.json`.
- `android.googleServicesFile` points at `./google-services.json`.
- That file is the **project-level** download from the Firebase console and
  contains all three Android apps (`com.easzygoo.rider`, `com.easzygoo.user`,
  `com.easzygoo.vendor`). The Google Services Gradle plugin selects the entry
  matching the build's `applicationId`, so the same file is valid for all three
  apps — but each app must set its own `android.package`.

### iOS — structure ready, not wired

There is **no iOS app registered in the Firebase console yet**, so there is no
`GoogleService-Info.plist` to reference. `ios.bundleIdentifier` is set
(`com.easzygoo.user`) so prebuild can generate the iOS project, but Firebase is
Android-only right now.

To enable iOS later:

1. Firebase console → Project settings → Add app → iOS, bundle id
   `com.easzygoo.user`.
2. Download `GoogleService-Info.plist` into this folder.
3. Add to the `ios` block in `app.json`:

   ```json
   "ios": {
     "bundleIdentifier": "com.easzygoo.user",
     "googleServicesFile": "./GoogleService-Info.plist"
   }
   ```

4. Rebuild. The `@react-native-firebase/app` config plugin picks it up the same
   way it does the Android file.

## Notes

- `android/` and `ios/` are **not** committed. This is a managed (CNG) project —
  `expo prebuild` / EAS regenerate them from `app.json` on every build. Editing
  generated native files directly will be overwritten.
- Both `google-services.json` and `GoogleService-Info.plist` are gitignored at
  the repo root, so each developer/CI needs their own copy (or an EAS secret).
